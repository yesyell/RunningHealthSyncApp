import SwiftUI

@main
struct RunningHealthSyncAppApp: App {
    private let baseService: RunningHealthAPIService
    private let personalizedService: PersonalizedRunningHealthService
    @StateObject private var preferences: AppPreferencesStore

    init() {
        let preferences = AppPreferencesStore()
        let baseService = RunningHealthAPIService(configuration: AppConfiguration())
        self.baseService = baseService
        personalizedService = PersonalizedRunningHealthService(base: baseService, preferences: preferences)
        _preferences = StateObject(wrappedValue: preferences)
        AppChrome.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                service: personalizedService,
                preferences: preferences
            )
        }
    }
}
