import Charts
import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AppScreen(
            title: "러닝 대시보드",
            subtitle: "목표, 주간 거리, 페이스, 회복, 추천 코스를 한 화면에서 봅니다.",
            state: viewModel.state,
            accent: AppTheme.sky
        ) {
            if let dashboard = viewModel.dashboard {
                InsightBanner(
                    eyebrow: "이번 주 포커스",
                    headline: "\(dashboard.userProfile.name)님의 목표는 \(dashboard.userProfile.runningGoal)",
                    detail: "선호 지역은 \(dashboard.userProfile.preferredArea), 선호 거리는 \(dashboard.userProfile.preferredDistanceKm.map { String(Int($0)) + "km" }.joined(separator: ", ")) 입니다.",
                    accent: AppTheme.sky
                )

                SectionCard(title: "오늘의 코칭", systemImage: "figure.cooldown", accent: AppTheme.coral) {
                    let coaching = todayCoaching(for: dashboard)
                    InsightBanner(
                        eyebrow: coaching.eyebrow,
                        headline: coaching.title,
                        detail: coaching.detail,
                        accent: coaching.tint
                    )
                }

                SectionCard(title: "사용자 목표", systemImage: "person.crop.circle", accent: AppTheme.sky) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("목표 러너 프로필")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.sky)
                            Text("\(dashboard.userProfile.name)님")
                                .font(.title3.bold())
                            Text(dashboard.userProfile.notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            MetricPill(title: "목표 페이스", value: dashboard.userProfile.targetPaceDisplay + "/km", tone: AppTheme.sky)
                            MetricPill(title: "주간 목표", value: Formatters.distance(dashboard.userProfile.weeklyTargetKm), tone: AppTheme.mint)
                            MetricPill(title: "안정시 심박", value: "\(dashboard.userProfile.restingHeartRate)bpm", tone: AppTheme.coral)
                        }
                    }
                }

                SectionCard(title: "최근 주간 거리", systemImage: "figure.run", accent: AppTheme.mint) {
                    if let latest = dashboard.weeklyReport.series.first {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                MetricPill(title: "최근 거리", value: Formatters.distance(latest.totalKm), tone: AppTheme.mint)
                                MetricPill(title: "세션 수", value: "\(latest.sessionCount ?? 0)회", tone: AppTheme.sky)
                                MetricPill(title: "누적 리포트", value: Formatters.distance(dashboard.weeklyReport.summary.totalKm), tone: AppTheme.coral)
                            }
                        }
                    }
                    Chart(dashboard.weeklyReport.series) { point in
                        BarMark(
                            x: .value("주", point.label),
                            y: .value("거리", point.totalKm ?? 0)
                        )
                        .foregroundStyle(AppTheme.mint.gradient)
                    }
                    .frame(height: ResponsiveLayout.chartHeight)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }

                SectionCard(title: "페이스 추세", systemImage: "speedometer", accent: AppTheme.coral) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            MetricPill(title: "최근 페이스", value: Formatters.pace(dashboard.paceInsight.analysis.latestValue), tone: AppTheme.coral)
                            MetricPill(title: "추세", value: Formatters.trend(dashboard.paceInsight.analysis.trend), tone: AppTheme.sky)
                            MetricPill(title: "목표 차이", value: Formatters.number(dashboard.paceInsight.analysis.gapToTarget), tone: AppTheme.mint)
                        }
                    }
                    Text(dashboard.paceInsight.analysis.insight)
                        .foregroundStyle(.secondary)

                    Chart(dashboard.paceInsight.series) { point in
                        LineMark(
                            x: .value("주", point.weekStart),
                            y: .value("페이스", point.avgPace ?? 0)
                        )
                        .foregroundStyle(AppTheme.coral)
                        PointMark(
                            x: .value("주", point.weekStart),
                            y: .value("페이스", point.avgPace ?? 0)
                        )
                        .foregroundStyle(AppTheme.coral)
                    }
                    .frame(height: ResponsiveLayout.chartHeight)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }

                SectionCard(title: "회복 상태", systemImage: "heart.text.square", accent: AppTheme.coral) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            MetricPill(title: "상태", value: dashboard.recoveryInsight.analysis.status == "caution" ? "주의" : "안정", tone: AppTheme.coral)
                            MetricPill(title: "휴식 간격", value: "\(Formatters.number(dashboard.recoveryInsight.analysis.avgRestDays))일", tone: AppTheme.sky)
                            MetricPill(title: "부하 비율", value: Formatters.number(dashboard.recoveryInsight.analysis.loadRatio), tone: AppTheme.mint)
                        }
                    }
                    Text(dashboard.recoveryInsight.analysis.insight)
                        .foregroundStyle(.secondary)
                }

                SectionCard(title: "추천 코스 요약", systemImage: "map.fill", accent: AppTheme.sky) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            MetricPill(title: "기온", value: "\(Formatters.number(dashboard.recommendation.weather.tempC))°C", tone: AppTheme.sky)
                            MetricPill(title: "권장 페이스", value: Formatters.pace(dashboard.recommendation.suggestedPaceMinKm), tone: AppTheme.mint)
                        }
                    }
                    ForEach(dashboard.recommendation.courses.prefix(3)) { course in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(course.name ?? "이름 없는 코스")
                                    .font(.headline)
                                Text("\(course.location ?? "-") · \(Formatters.distance(course.distanceKm))")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(AppTheme.sky)
                        }
                        .padding(14)
                        .background(AppTheme.sky.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private func todayCoaching(for dashboard: DashboardResponse) -> (eyebrow: String, title: String, detail: String, tint: Color) {
        let recoveryStatus = dashboard.recoveryInsight.analysis.status ?? "ok"
        let paceGap = dashboard.paceInsight.analysis.gapToTarget ?? 0
        let temp = dashboard.recommendation.weather.tempC ?? 0
        let basePace = dashboard.recommendation.suggestedPaceMinKm ?? dashboard.paceInsight.analysis.latestValue ?? 6.8

        if recoveryStatus == "caution" {
            return (
                "회복 우선",
                "오늘은 강도보다 회복 런이 더 적절합니다",
                "주간 부하가 올라간 상태라 30~40분 이지런이나 휴식이 더 안전합니다. 페이스는 \(Formatters.pace(basePace + 0.2)) 수준으로 여유 있게 잡는 편이 좋습니다.",
                AppTheme.coral
            )
        }

        if temp <= 5 {
            return (
                "추운 날 가이드",
                "워밍업을 길게 가져가고 천천히 시작하세요",
                "현재 기온은 \(Formatters.number(temp))°C입니다. 권장 페이스는 \(Formatters.pace(dashboard.recommendation.suggestedPaceMinKm))이며 초반 1km는 목표보다 느리게 시작하는 편이 좋습니다.",
                AppTheme.sky
            )
        }

        if paceGap > 0.5 {
            return (
                "페이스 보정",
                "오늘은 목표 추격보다 일정한 리듬 유지에 집중하세요",
                "최근 페이스가 목표보다 \(Formatters.number(paceGap))분 느립니다. 6~8km 구간을 균일한 호흡으로 유지하는 훈련이 더 효과적입니다.",
                AppTheme.mint
            )
        }

        return (
            "리듬 유지",
            "오늘은 자신감 있게 평소 루틴을 이어가도 됩니다",
            "회복과 추세가 안정적입니다. 선호 거리 범위에서 \(dashboard.userProfile.preferredArea) 코스를 선택해 리듬감을 유지해보세요.",
            AppTheme.mint
        )
    }
}

#Preview {
    NavigationStack {
        DashboardView(viewModel: DashboardViewModel(service: PreviewRunningHealthService.shared))
    }
}
