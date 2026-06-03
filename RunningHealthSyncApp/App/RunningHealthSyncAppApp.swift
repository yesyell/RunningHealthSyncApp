import SwiftUI

@main
struct RunningHealthSyncAppApp: App {
    private let baseService: RunningHealthAPIService
    private let personalizedService: PersonalizedRunningHealthService
    @StateObject private var preferences: AppPreferencesStore
    @StateObject private var sessionStore = KeychainSessionStore.shared
    @StateObject private var auth: StravaAuthManager

    init() {
        let configuration = AppConfiguration()
        let preferences = AppPreferencesStore()
        let baseService = RunningHealthAPIService(configuration: configuration)
        self.baseService = baseService
        personalizedService = PersonalizedRunningHealthService(base: baseService, preferences: preferences)
        _preferences = StateObject(wrappedValue: preferences)
        _auth = StateObject(wrappedValue: StravaAuthManager(baseURL: configuration.baseURL))
        AppChrome.configure()
    }

    var body: some Scene {
        WindowGroup {
            if sessionStore.isLoggedIn {
                RootTabView(
                    service: personalizedService,
                    preferences: preferences
                )
            } else {
                LoginView(auth: auth)
            }
        }
    }
}
