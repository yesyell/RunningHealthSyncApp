import Foundation

final class PersonalizedRunningHealthService: RunningHealthServiceProviding {
    private let base: RunningHealthServiceProviding
    private let preferences: AppPreferencesStore

    init(base: RunningHealthServiceProviding, preferences: AppPreferencesStore) {
        self.base = base
        self.preferences = preferences
    }

    var baseURLDisplayString: String {
        base.baseURLDisplayString
    }

    func fetchToolCatalog() async throws -> [ToolDefinition] {
        try await base.fetchToolCatalog()
    }

    func fetchDashboard(location: String?, lat: Double?, lon: Double?) async throws -> DashboardResponse {
        let response = try await base.fetchDashboard(
            location: preferences.effectiveLocation(fallback: location),
            lat: lat ?? preferences.latitudeValue,
            lon: lon ?? preferences.longitudeValue
        )
        return preferences.apply(to: response)
    }

    func fetchNaturalLanguageResponse(query: String) async throws -> NaturalLanguageResponse {
        let response = try await base.fetchNaturalLanguageResponse(query: query)
        return preferences.apply(to: response)
    }

    func fetchReport(period: String, n: Int) async throws -> HealthReportResponse {
        let response = try await base.fetchReport(period: period, n: n)
        return preferences.apply(to: response)
    }

    func fetchInsight(metric: String, weeks: Int) async throws -> HealthInsightResponse {
        let response = try await base.fetchInsight(metric: metric, weeks: weeks)
        return preferences.apply(to: response)
    }

    func fetchRecommendation(location: String?, lat: Double?, lon: Double?) async throws -> RunningRecommendResponse {
        let response = try await base.fetchRecommendation(
            location: preferences.effectiveLocation(fallback: location),
            lat: lat ?? preferences.latitudeValue,
            lon: lon ?? preferences.longitudeValue
        )
        return preferences.apply(to: response)
    }

    func fetchStructuredQuery(metric: String, period: String, limit: Int) async throws -> HealthQueryResponse {
        let response = try await base.fetchStructuredQuery(metric: metric, period: period, limit: limit)
        return preferences.apply(to: response)
    }
}
