import AuthenticationServices
import Foundation
import UIKit

struct StravaConfig: Decodable {
    let configured: Bool
    let clientId: String?
    let redirectUri: String
    let scope: String
    let authorizeUrl: String
}

struct StravaExchangeResponse: Decodable {
    struct Athlete: Decodable {
        let id: Int?
        let name: String?
        let city: String?
    }

    let sessionToken: String
    let userId: String
    let athlete: Athlete?
    let profileCreated: Bool?
}

@MainActor
final class StravaAuthManager: NSObject, ObservableObject {
    private let baseURL: URL
    private let callbackScheme = "runnershello"
    private let store: KeychainSessionStore
    private var webSession: ASWebAuthenticationSession?

    @Published var isAuthenticating = false
    @Published var errorMessage: String?

    init(baseURL: URL, store: KeychainSessionStore = .shared) {
        self.baseURL = baseURL
        self.store = store
    }

    func login() async {
        isAuthenticating = true
        errorMessage = nil
        defer { isAuthenticating = false }

        do {
            let cfg = try await fetchConfig()
            guard cfg.configured, let clientId = cfg.clientId else {
                errorMessage = "서버에 Strava 설정이 없습니다."
                return
            }

            let authURL = buildAuthorizeURL(clientId: clientId, redirectUri: cfg.redirectUri, scope: cfg.scope)
            let code = try await runWebAuth(authURL)
            let token = try await exchange(code: code)
            store.save(token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        store.clear()
    }

    private func fetchConfig() async throws -> StravaConfig {
        let url = baseURL.appendingPathComponent("api/auth/strava/config")
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(StravaConfig.self, from: data)
    }

    private func buildAuthorizeURL(clientId: String, redirectUri: String, scope: String) -> URL {
        var comps = URLComponents(string: "https://www.strava.com/oauth/authorize")!
        comps.queryItems = [
            .init(name: "client_id", value: clientId),
            .init(name: "response_type", value: "code"),
            .init(name: "redirect_uri", value: redirectUri),
            .init(name: "approval_prompt", value: "auto"),
            .init(name: "scope", value: scope),
        ]
        return comps.url!
    }

    private func runWebAuth(_ url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL,
                      let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                if let err = items.first(where: { $0.name == "error" })?.value {
                    continuation.resume(
                        throwing: NSError(
                            domain: "strava",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Strava 인증 거부: \(err)"]
                        )
                    )
                    return
                }

                guard let code = items.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.webSession = session
            session.start()
        }
    }

    private func exchange(code: String) async throws -> String {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/auth/strava/exchange"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["code": code])

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["detail"] as? String
            throw NSError(
                domain: "exchange",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: detail ?? "세션 발급 실패"]
            )
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(StravaExchangeResponse.self, from: data).sessionToken
    }
}

extension StravaAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
