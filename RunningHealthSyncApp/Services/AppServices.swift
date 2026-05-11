import Foundation

struct AppConfiguration {
    let baseURL: URL

    init(baseURL: URL = URL(string: "http://127.0.0.1:8080")!) {
        self.baseURL = baseURL
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let body: Encodable?

    init(path: String, method: HTTPMethod = .get, body: Encodable? = nil) {
        self.path = path
        self.method = method
        self.body = body
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "서버 응답을 해석하지 못했습니다."
        case let .server(message):
            return message
        }
    }
}

final class AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ value: Encodable) {
        self.encodeClosure = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

final class HTTPClient {
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    func send<Response: Decodable>(_ endpoint: Endpoint, baseURL: URL) async throws -> Response {
        let normalizedPath = endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var request = URLRequest(url: baseURL.appendingPathComponent(normalizedPath))
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            if let errorPayload = try? decoder.decode([String: String].self, from: data),
               let message = errorPayload["error"] {
                throw APIError.server(message)
            }
            throw APIError.server("서버 호출에 실패했습니다. status=\(http.statusCode)")
        }

        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }
        return try decoder.decode(Response.self, from: data)
    }
}

struct EmptyResponse: Decodable {}

protocol RunningHealthServiceProviding {
    var baseURLDisplayString: String { get }
    func fetchToolCatalog() async throws -> [ToolDefinition]
    func fetchDashboard(location: String?, lat: Double?, lon: Double?) async throws -> DashboardResponse
    func fetchNaturalLanguageResponse(query: String) async throws -> NaturalLanguageResponse
    func fetchReport(period: String, n: Int) async throws -> HealthReportResponse
    func fetchInsight(metric: String, weeks: Int) async throws -> HealthInsightResponse
    func fetchRecommendation(location: String?, lat: Double?, lon: Double?) async throws -> RunningRecommendResponse
    func fetchStructuredQuery(metric: String, period: String, limit: Int) async throws -> HealthQueryResponse
}

final class RunningHealthAPIService: RunningHealthServiceProviding {
    private let configuration: AppConfiguration
    private let client: HTTPClient

    init(configuration: AppConfiguration, client: HTTPClient = HTTPClient()) {
        self.configuration = configuration
        self.client = client
    }

    var baseURLDisplayString: String {
        configuration.baseURL.absoluteString
    }

    func fetchToolCatalog() async throws -> [ToolDefinition] {
        let response: ToolCatalogResponse = try await client.send(Endpoint(path: "/api/tools"), baseURL: configuration.baseURL)
        return response.tools
    }

    func fetchDashboard(location: String?, lat: Double?, lon: Double?) async throws -> DashboardResponse {
        let body = DashboardRequest(location: location, lat: lat, lon: lon)
        return try await client.send(Endpoint(path: "/api/dashboard", method: .post, body: body), baseURL: configuration.baseURL)
    }

    func fetchNaturalLanguageResponse(query: String) async throws -> NaturalLanguageResponse {
        try await client.send(
            Endpoint(path: "/api/natural-query", method: .post, body: NaturalQueryRequest(query: query)),
            baseURL: configuration.baseURL
        )
    }

    func fetchReport(period: String, n: Int) async throws -> HealthReportResponse {
        try await callTool(name: "health_report", arguments: [
            "period": .string(period),
            "n": .integer(n),
        ])
    }

    func fetchInsight(metric: String, weeks: Int) async throws -> HealthInsightResponse {
        try await callTool(name: "health_insight", arguments: [
            "metric": .string(metric),
            "weeks": .integer(weeks),
        ])
    }

    func fetchRecommendation(location: String?, lat: Double?, lon: Double?) async throws -> RunningRecommendResponse {
        var args: [String: JSONValue] = [:]
        if let location, !location.isEmpty {
            args["location"] = .string(location)
        }
        if let lat {
            args["lat"] = .number(lat)
        }
        if let lon {
            args["lon"] = .number(lon)
        }
        return try await callTool(name: "running_recommend", arguments: args)
    }

    func fetchStructuredQuery(metric: String, period: String, limit: Int) async throws -> HealthQueryResponse {
        try await callTool(name: "health_query", arguments: [
            "metric": .string(metric),
            "period": .string(period),
            "limit": .integer(limit),
        ])
    }

    private func callTool<Response: Decodable>(name: String, arguments: [String: JSONValue]) async throws -> Response {
        let envelope: ToolCallEnvelope<Response> = try await client.send(
            Endpoint(path: "/api/call-tool", method: .post, body: ToolCallRequest(name: name, arguments: arguments)),
            baseURL: configuration.baseURL
        )
        return envelope.result
    }
}

struct DashboardRequest: Encodable {
    let location: String?
    let lat: Double?
    let lon: Double?
}

struct NaturalQueryRequest: Encodable {
    let query: String
}

final class PreviewRunningHealthService: RunningHealthServiceProviding {
    static let shared = PreviewRunningHealthService()

    var baseURLDisplayString: String {
        "preview://running-health"
    }

    func fetchToolCatalog() async throws -> [ToolDefinition] {
        PreviewData.toolDefinitions
    }

    func fetchDashboard(location: String?, lat: Double?, lon: Double?) async throws -> DashboardResponse {
        PreviewData.dashboard
    }

    func fetchNaturalLanguageResponse(query: String) async throws -> NaturalLanguageResponse {
        PreviewData.naturalLanguage(query: query)
    }

    func fetchReport(period: String, n: Int) async throws -> HealthReportResponse {
        PreviewData.report(period: period)
    }

    func fetchInsight(metric: String, weeks: Int) async throws -> HealthInsightResponse {
        PreviewData.insight(metric: metric)
    }

    func fetchRecommendation(location: String?, lat: Double?, lon: Double?) async throws -> RunningRecommendResponse {
        PreviewData.recommendation
    }

    func fetchStructuredQuery(metric: String, period: String, limit: Int) async throws -> HealthQueryResponse {
        PreviewData.query(metric: metric, period: period)
    }
}
