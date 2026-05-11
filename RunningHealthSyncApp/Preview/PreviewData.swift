import Foundation

enum PreviewData {
    static let user = UserProfile(
        name: "강민정",
        age: 30,
        runningGoal: "10km 마라톤 1시간",
        targetPaceMinKm: 5.683,
        targetPaceDisplay: "5:41",
        weeklyTargetKm: 40,
        preferredDistanceKm: [8, 10],
        preferredArea: "마포구",
        restingHeartRate: 58,
        maxHeartRate: 190,
        fitnessLevel: "intermediate",
        notes: "10km 마라톤 1시간 목표. 주 2~3회 러닝. 마포구 한강 코스 선호."
    )

    static let toolDefinitions = [
        ToolDefinition(name: "health_query", description: "구조화 조회", inputSchema: .object([:])),
        ToolDefinition(name: "health_interpret", description: "질의 해석", inputSchema: .object([:])),
        ToolDefinition(name: "health_report", description: "주간/월간 리포트", inputSchema: .object([:])),
        ToolDefinition(name: "running_recommend", description: "추천 코스", inputSchema: .object([:])),
        ToolDefinition(name: "health_insight", description: "추세 인사이트", inputSchema: .object([:])),
    ]

    static let reportWeeklySeries: [ReportSeriesPoint] = [
        .init(weekStart: "2026-03-16", monthStart: nil, sessionCount: 2, totalKm: 13.01, avgPace: 6.32),
        .init(weekStart: "2026-03-09", monthStart: nil, sessionCount: 2, totalKm: 9.87, avgPace: 6.51),
        .init(weekStart: "2026-03-02", monthStart: nil, sessionCount: 2, totalKm: 8.49, avgPace: 6.89),
        .init(weekStart: "2026-02-23", monthStart: nil, sessionCount: 2, totalKm: 7.44, avgPace: 7.79),
    ]

    static func report(period: String) -> HealthReportResponse {
        HealthReportResponse(
            period: period,
            series: reportWeeklySeries,
            summary: ReportSummary(
                totalKm: 38.81,
                avgPaceOverall: 6.88,
                userGoal: user.runningGoal,
                weeklyTargetKm: user.weeklyTargetKm,
                targetPaceMinKm: user.targetPaceMinKm
            ),
            error: nil
        )
    }

    static func insight(metric: String) -> HealthInsightResponse {
        let analysis: InsightAnalysis
        if metric == "recovery" {
            analysis = InsightAnalysis(
                metric: metric,
                latestValue: 13.01,
                previousValue: 9.87,
                targetValue: nil,
                gapToTarget: nil,
                trend: "stable",
                insight: "회복 상태가 비교적 안정적입니다.",
                guidelines: nil,
                weekOverWeekChange: nil,
                loadRatio: 1.32,
                avgRestDays: 2.4,
                avgSessionBpm: 146.0,
                restingHeartRate: 58.0,
                hrGapFromRest: 88.0,
                status: "ok"
            )
        } else {
            analysis = InsightAnalysis(
                metric: metric,
                latestValue: metric == "pace" ? 6.32 : 13.01,
                previousValue: metric == "pace" ? 6.51 : 9.87,
                targetValue: metric == "pace" ? user.targetPaceMinKm : user.weeklyTargetKm,
                gapToTarget: metric == "pace" ? 0.64 : -26.99,
                trend: "improving",
                insight: metric == "pace" ? "목표 페이스보다 느리지만 최근 흐름은 개선 중입니다." : "주간 거리가 꾸준히 늘고 있습니다.",
                guidelines: metric == "pace" ? ["페이스는 정지구간 제외 기준입니다."] : nil,
                weekOverWeekChange: 3.14,
                loadRatio: nil,
                avgRestDays: nil,
                avgSessionBpm: nil,
                restingHeartRate: nil,
                hrGapFromRest: nil,
                status: nil
            )
        }
        return HealthInsightResponse(
            metric: metric,
            weeks: 4,
            series: [
                WeeklySeriesPoint(weekStart: "2026-03-16", sessionCount: 2, totalKm: 13.01, avgPace: 6.32),
                WeeklySeriesPoint(weekStart: "2026-03-09", sessionCount: 2, totalKm: 9.87, avgPace: 6.51),
                WeeklySeriesPoint(weekStart: "2026-03-02", sessionCount: 2, totalKm: 8.49, avgPace: 6.89),
                WeeklySeriesPoint(weekStart: "2026-02-23", sessionCount: 2, totalKm: 7.44, avgPace: 7.79),
            ],
            analysis: analysis,
            signals: RecoverySignals(avgRestDays: 2.4, avgBpm: 146, restingHeartRate: 58, latestKm: 13.01, previousKm: 9.87, loadRatio: 1.32),
            userContext: InsightUserContext(runningGoal: user.runningGoal, targetPaceMinKm: user.targetPaceMinKm, weeklyTargetKm: user.weeklyTargetKm),
            error: nil
        )
    }

    static let recommendation = RunningRecommendResponse(
        input: RecommendationInput(location: "마포구", lat: 37.5665, lon: 126.9780),
        weather: WeatherSummary(tempC: 3.2, isCold: true, raw: .object([:])),
        recentPaceMinKm: 6.48,
        suggestedPaceMinKm: 6.73,
        courses: [
            RunningCourse(id: 1, name: "마포 한강 북단", location: "마포구", distanceKm: 8.0, coldSuitable: 1, description: "바람을 일부 피할 수 있는 평탄 코스"),
            RunningCourse(id: 2, name: "상암 월드컵공원", location: "마포구", distanceKm: 10.0, coldSuitable: 1, description: "지형 변화가 적고 워밍업 동선이 좋음"),
        ],
        coldTips: [
            "워밍업 최소 5분 필수",
            "목표 페이스보다 30초 느리게 시작",
        ],
        userContext: RecommendationUserContext(runningGoal: user.runningGoal, targetPaceMinKm: user.targetPaceMinKm, preferredDistanceKm: user.preferredDistanceKm),
        error: nil
    )

    static let dashboard = DashboardResponse(
        userProfile: user,
        weeklyReport: report(period: "weekly"),
        paceInsight: insight(metric: "pace"),
        recoveryInsight: insight(metric: "recovery"),
        recommendation: recommendation
    )

    static func naturalLanguage(query: String) -> NaturalLanguageResponse {
        NaturalLanguageResponse(
            userQuery: query,
            interpretation: HealthInterpretResponse(
                matchedConcepts: [
                    MatchedConcept(
                        key: "pace",
                        label: "페이스",
                        dbView: "v_running_pace",
                        dbColumn: "pace_min_per_km",
                        sqlHint: nil,
                        calculation: "정지구간 제외",
                        interpretation: nil,
                        edgeCases: nil,
                        commonMisuse: "정지 시간 포함 평균으로 계산하면 안 됩니다.",
                        guidelines: ["트렌드는 최소 4주 기준"]
                    ),
                ],
                isTrendQuery: true,
                intent: "trend",
                period: InterpretedPeriod(type: "relative_weeks", value: 4),
                aggregation: "latest",
                nextActions: [
                    NextAction(tool: "health_query", arguments: ["metric": .string("pace"), "period": .string("weekly"), "limit": .integer(4)], reason: "구조화 조회"),
                    NextAction(tool: "health_insight", arguments: ["metric": .string("pace"), "weeks": .integer(4)], reason: "추세 인사이트"),
                ],
                userBaseline: user
            ),
            toolResults: [
                NaturalLanguageToolResult(tool: "health_query", arguments: [:], reason: "구조화 조회", result: .object(["data": .array([])])),
                NaturalLanguageToolResult(tool: "health_insight", arguments: [:], reason: "추세 인사이트", result: .object(["analysis": .object(["trend": .string("improving"), "insight": .string("최근 4주 기준 개선 추세입니다.")])])),
            ],
            reply: "최근 4주 기준 페이스는 점진적으로 개선 중입니다. 아직 목표 페이스보다 느리지만 추세는 좋습니다."
        )
    }

    static func query(metric: String, period: String) -> HealthQueryResponse {
        HealthQueryResponse(
            data: [
                StructuredMetricRow(weekStart: "2026-03-16", monthStart: nil, sessionDate: nil, sessionId: nil, avgPace: 6.32, paceMinPerKm: nil, totalKm: 13.01, distanceKm: nil, sessionCount: 2, durationMin: nil, avgBpm: nil),
                StructuredMetricRow(weekStart: "2026-03-09", monthStart: nil, sessionDate: nil, sessionId: nil, avgPace: 6.51, paceMinPerKm: nil, totalKm: 9.87, distanceKm: nil, sessionCount: 2, durationMin: nil, avgBpm: nil),
            ],
            query: QueryDescriptor(mode: "structured", metric: metric, period: period, limit: 6),
            context: QueryContext(userTargetPace: user.targetPaceMinKm, userGoal: user.runningGoal, weeklyTargetKm: user.weeklyTargetKm, preferredDistanceKm: user.preferredDistanceKm, rowCount: 2),
            error: nil
        )
    }
}
