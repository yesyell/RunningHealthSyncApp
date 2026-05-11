import Combine
import Foundation

final class AppPreferencesStore: ObservableObject {
    @Published var name: String {
        didSet { persist(name, forKey: Keys.name) }
    }
    @Published var runningGoal: String {
        didSet { persist(runningGoal, forKey: Keys.runningGoal) }
    }
    @Published var targetPace: String {
        didSet { persist(targetPace, forKey: Keys.targetPace) }
    }
    @Published var weeklyTargetKm: String {
        didSet { persist(weeklyTargetKm, forKey: Keys.weeklyTargetKm) }
    }
    @Published var preferredDistances: String {
        didSet { persist(preferredDistances, forKey: Keys.preferredDistances) }
    }
    @Published var preferredArea: String {
        didSet { persist(preferredArea, forKey: Keys.preferredArea) }
    }
    @Published var restingHeartRate: String {
        didSet { persist(restingHeartRate, forKey: Keys.restingHeartRate) }
    }
    @Published var notes: String {
        didSet { persist(notes, forKey: Keys.notes) }
    }
    @Published var latitude: String {
        didSet { persist(latitude, forKey: Keys.latitude) }
    }
    @Published var longitude: String {
        didSet { persist(longitude, forKey: Keys.longitude) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        name = defaults.string(forKey: Keys.name) ?? ""
        runningGoal = defaults.string(forKey: Keys.runningGoal) ?? ""
        targetPace = defaults.string(forKey: Keys.targetPace) ?? ""
        weeklyTargetKm = defaults.string(forKey: Keys.weeklyTargetKm) ?? ""
        preferredDistances = defaults.string(forKey: Keys.preferredDistances) ?? ""
        preferredArea = defaults.string(forKey: Keys.preferredArea) ?? ""
        restingHeartRate = defaults.string(forKey: Keys.restingHeartRate) ?? ""
        notes = defaults.string(forKey: Keys.notes) ?? ""
        latitude = defaults.string(forKey: Keys.latitude) ?? ""
        longitude = defaults.string(forKey: Keys.longitude) ?? ""
    }

    var hasOverrides: Bool {
        ![
            name,
            runningGoal,
            targetPace,
            weeklyTargetKm,
            preferredDistances,
            preferredArea,
            restingHeartRate,
            notes,
            latitude,
            longitude,
        ]
        .joined()
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .isEmpty
    }

    var targetPaceMinKm: Double? {
        Self.parsePace(targetPace)
    }

    var weeklyTargetKmValue: Double? {
        Double(weeklyTargetKm.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var preferredDistanceKmValues: [Double]? {
        let values = preferredDistances
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        return values.isEmpty ? nil : values
    }

    var restingHeartRateValue: Int? {
        Int(restingHeartRate.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var latitudeValue: Double? {
        Double(latitude.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var longitudeValue: Double? {
        Double(longitude.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func resetOverrides() {
        name = ""
        runningGoal = ""
        targetPace = ""
        weeklyTargetKm = ""
        preferredDistances = ""
        preferredArea = ""
        restingHeartRate = ""
        notes = ""
        latitude = ""
        longitude = ""
    }

    func effectiveLocation(fallback: String?) -> String? {
        let custom = preferredArea.trimmingCharacters(in: .whitespacesAndNewlines)
        return custom.isEmpty ? fallback : custom
    }

    func apply(to userProfile: UserProfile) -> UserProfile {
        UserProfile(
            name: trimmedOrFallback(name, fallback: userProfile.name),
            age: userProfile.age,
            runningGoal: trimmedOrFallback(runningGoal, fallback: userProfile.runningGoal),
            targetPaceMinKm: targetPaceMinKm ?? userProfile.targetPaceMinKm,
            targetPaceDisplay: targetPaceMinKm.map(Formatters.paceDisplay) ?? userProfile.targetPaceDisplay,
            weeklyTargetKm: weeklyTargetKmValue ?? userProfile.weeklyTargetKm,
            preferredDistanceKm: preferredDistanceKmValues ?? userProfile.preferredDistanceKm,
            preferredArea: trimmedOrFallback(preferredArea, fallback: userProfile.preferredArea),
            restingHeartRate: restingHeartRateValue ?? userProfile.restingHeartRate,
            maxHeartRate: userProfile.maxHeartRate,
            fitnessLevel: userProfile.fitnessLevel,
            notes: trimmedOrFallback(notes, fallback: userProfile.notes)
        )
    }

    func apply(to response: DashboardResponse) -> DashboardResponse {
        DashboardResponse(
            userProfile: apply(to: response.userProfile),
            weeklyReport: apply(to: response.weeklyReport),
            paceInsight: apply(to: response.paceInsight),
            recoveryInsight: apply(to: response.recoveryInsight),
            recommendation: apply(to: response.recommendation)
        )
    }

    func apply(to response: HealthReportResponse) -> HealthReportResponse {
        HealthReportResponse(
            period: response.period,
            series: response.series,
            summary: ReportSummary(
                totalKm: response.summary.totalKm,
                avgPaceOverall: response.summary.avgPaceOverall,
                userGoal: trimmedOrFallback(runningGoal, fallback: response.summary.userGoal),
                weeklyTargetKm: weeklyTargetKmValue ?? response.summary.weeklyTargetKm,
                targetPaceMinKm: targetPaceMinKm ?? response.summary.targetPaceMinKm
            ),
            error: response.error
        )
    }

    func apply(to response: HealthInsightResponse) -> HealthInsightResponse {
        let targetPace = targetPaceMinKm
        let targetWeeklyKm = weeklyTargetKmValue
        let updatedAnalysis: InsightAnalysis

        switch response.metric {
        case "pace":
            let targetValue = targetPace ?? response.analysis.targetValue
            let gap = response.analysis.latestValue.flatMap { latest in
                targetValue.map { round(latest - $0, places: 3) }
            }
            updatedAnalysis = InsightAnalysis(
                metric: response.analysis.metric,
                latestValue: response.analysis.latestValue,
                previousValue: response.analysis.previousValue,
                targetValue: targetValue,
                gapToTarget: gap,
                trend: response.analysis.trend,
                insight: response.analysis.insight,
                guidelines: response.analysis.guidelines,
                weekOverWeekChange: response.analysis.weekOverWeekChange,
                loadRatio: response.analysis.loadRatio,
                avgRestDays: response.analysis.avgRestDays,
                avgSessionBpm: response.analysis.avgSessionBpm,
                restingHeartRate: response.analysis.restingHeartRate,
                hrGapFromRest: response.analysis.hrGapFromRest,
                status: response.analysis.status
            )
        case "weekly_mileage":
            let targetValue = targetWeeklyKm ?? response.analysis.targetValue
            let gap = response.analysis.latestValue.flatMap { latest in
                targetValue.map { round(latest - $0, places: 2) }
            }
            updatedAnalysis = InsightAnalysis(
                metric: response.analysis.metric,
                latestValue: response.analysis.latestValue,
                previousValue: response.analysis.previousValue,
                targetValue: targetValue,
                gapToTarget: gap,
                trend: response.analysis.trend,
                insight: response.analysis.insight,
                guidelines: response.analysis.guidelines,
                weekOverWeekChange: response.analysis.weekOverWeekChange,
                loadRatio: response.analysis.loadRatio,
                avgRestDays: response.analysis.avgRestDays,
                avgSessionBpm: response.analysis.avgSessionBpm,
                restingHeartRate: response.analysis.restingHeartRate,
                hrGapFromRest: response.analysis.hrGapFromRest,
                status: response.analysis.status
            )
        case "recovery":
            updatedAnalysis = InsightAnalysis(
                metric: response.analysis.metric,
                latestValue: response.analysis.latestValue,
                previousValue: response.analysis.previousValue,
                targetValue: response.analysis.targetValue,
                gapToTarget: response.analysis.gapToTarget,
                trend: response.analysis.trend,
                insight: response.analysis.insight,
                guidelines: response.analysis.guidelines,
                weekOverWeekChange: response.analysis.weekOverWeekChange,
                loadRatio: response.analysis.loadRatio,
                avgRestDays: response.analysis.avgRestDays,
                avgSessionBpm: response.analysis.avgSessionBpm,
                restingHeartRate: restingHeartRateValue.map(Double.init) ?? response.analysis.restingHeartRate,
                hrGapFromRest: response.analysis.hrGapFromRest,
                status: response.analysis.status
            )
        default:
            updatedAnalysis = response.analysis
        }

        return HealthInsightResponse(
            metric: response.metric,
            weeks: response.weeks,
            series: response.series,
            analysis: updatedAnalysis,
            signals: response.signals,
            userContext: InsightUserContext(
                runningGoal: trimmedOrFallback(runningGoal, fallback: response.userContext.runningGoal),
                targetPaceMinKm: targetPace ?? response.userContext.targetPaceMinKm,
                weeklyTargetKm: targetWeeklyKm ?? response.userContext.weeklyTargetKm
            ),
            error: response.error
        )
    }

    func apply(to response: RunningRecommendResponse) -> RunningRecommendResponse {
        RunningRecommendResponse(
            input: RecommendationInput(
                location: effectiveLocation(fallback: response.input.location) ?? response.input.location,
                lat: latitudeValue ?? response.input.lat,
                lon: longitudeValue ?? response.input.lon
            ),
            weather: response.weather,
            recentPaceMinKm: response.recentPaceMinKm,
            suggestedPaceMinKm: response.suggestedPaceMinKm,
            courses: response.courses,
            coldTips: response.coldTips,
            userContext: RecommendationUserContext(
                runningGoal: trimmedOrFallback(runningGoal, fallback: response.userContext.runningGoal),
                targetPaceMinKm: targetPaceMinKm ?? response.userContext.targetPaceMinKm,
                preferredDistanceKm: preferredDistanceKmValues ?? response.userContext.preferredDistanceKm
            ),
            error: response.error
        )
    }

    func apply(to response: HealthQueryResponse) -> HealthQueryResponse {
        HealthQueryResponse(
            data: response.data,
            query: response.query,
            context: QueryContext(
                userTargetPace: targetPaceMinKm ?? response.context.userTargetPace,
                userGoal: trimmedOrFallback(runningGoal, fallback: response.context.userGoal),
                weeklyTargetKm: weeklyTargetKmValue ?? response.context.weeklyTargetKm,
                preferredDistanceKm: preferredDistanceKmValues ?? response.context.preferredDistanceKm,
                rowCount: response.context.rowCount
            ),
            error: response.error
        )
    }

    func apply(to response: NaturalLanguageResponse) -> NaturalLanguageResponse {
        NaturalLanguageResponse(
            userQuery: response.userQuery,
            interpretation: HealthInterpretResponse(
                matchedConcepts: response.interpretation.matchedConcepts,
                isTrendQuery: response.interpretation.isTrendQuery,
                intent: response.interpretation.intent,
                period: response.interpretation.period,
                aggregation: response.interpretation.aggregation,
                nextActions: response.interpretation.nextActions,
                userBaseline: apply(to: response.interpretation.userBaseline)
            ),
            toolResults: response.toolResults,
            reply: response.reply
        )
    }

    private func persist(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    private func trimmedOrFallback(_ value: String, fallback: String?) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func trimmedOrFallback(_ value: String, fallback: String) -> String {
        trimmedOrFallback(value, fallback: Optional(fallback)) ?? fallback
    }

    private func round(_ value: Double, places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (value * multiplier).rounded() / multiplier
    }

    static func parsePace(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":")
            guard parts.count == 2,
                  let minutes = Double(parts[0]),
                  let seconds = Double(parts[1]),
                  seconds >= 0,
                  seconds < 60 else {
                return nil
            }
            return minutes + seconds / 60
        }
        return Double(trimmed)
    }

    private enum Keys {
        static let name = "preferences.name"
        static let runningGoal = "preferences.runningGoal"
        static let targetPace = "preferences.targetPace"
        static let weeklyTargetKm = "preferences.weeklyTargetKm"
        static let preferredDistances = "preferences.preferredDistances"
        static let preferredArea = "preferences.preferredArea"
        static let restingHeartRate = "preferences.restingHeartRate"
        static let notes = "preferences.notes"
        static let latitude = "preferences.latitude"
        static let longitude = "preferences.longitude"
    }
}
