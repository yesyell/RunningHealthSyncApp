import Charts
import SwiftUI

struct ReportView: View {
    @StateObject private var viewModel: ReportViewModel

    init(viewModel: ReportViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AppScreen(
            title: "리포트",
            subtitle: "주간/월간 리포트를 조회하고 누적 거리와 평균 페이스를 확인합니다.",
            state: viewModel.state,
            accent: AppTheme.mint,
            onRetry: { Task { await viewModel.load() } }
        ) {
            InsightBanner(
                eyebrow: "리포트",
                headline: "주간 흐름과 월간 누적을 빠르게 비교",
                detail: "누적 거리와 평균 페이스를 함께 보면서 목표 대비 진행 상태를 읽습니다.",
                accent: AppTheme.mint
            )

            SectionCard(title: "조건", systemImage: "slider.horizontal.3", accent: AppTheme.mint) {
                Picker("기간", selection: $viewModel.period) {
                    Text("주간").tag("weekly")
                    Text("월간").tag("monthly")
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading) {
                    Text("최근 \(Int(viewModel.n))개 기간")
                    Slider(value: $viewModel.n, in: 1 ... 12, step: 1)
                }

                ActionButton(title: "리포트 조회", systemImage: "chart.bar", accent: AppTheme.mint, isLoading: viewModel.state.isLoading) {
                    Task { await viewModel.load() }
                }
            }

            if let response = viewModel.response {
                SectionCard(title: "요약", systemImage: "doc.text", accent: AppTheme.sky) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            MetricPill(title: "누적 거리", value: Formatters.distance(response.summary.totalKm), tone: AppTheme.mint)
                            MetricPill(title: "평균 페이스", value: Formatters.pace(response.summary.avgPaceOverall), tone: AppTheme.sky)
                            MetricPill(title: "목표 페이스", value: Formatters.pace(response.summary.targetPaceMinKm), tone: AppTheme.coral)
                        }
                    }
                    Text("목표: \(response.summary.userGoal)")
                    Text("주간 목표 거리 \(Formatters.distance(response.summary.weeklyTargetKm)) · 목표 페이스 \(Formatters.pace(response.summary.targetPaceMinKm))")
                        .foregroundStyle(.secondary)
                }

                SectionCard(title: "차트", systemImage: "chart.xyaxis.line", accent: AppTheme.mint) {
                    Chart(response.series) { point in
                        BarMark(x: .value("기간", point.label), y: .value("거리", point.totalKm ?? 0))
                            .foregroundStyle(AppTheme.mint.gradient)
                        if let pace = point.avgPace {
                            LineMark(x: .value("기간", point.label), y: .value("페이스", pace))
                                .foregroundStyle(AppTheme.coral)
                            PointMark(x: .value("기간", point.label), y: .value("페이스", pace))
                                .foregroundStyle(AppTheme.coral)
                        }
                    }
                    .frame(height: ResponsiveLayout.chartHeight)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }

                SectionCard(title: "리스트", systemImage: "list.bullet.rectangle", accent: AppTheme.sky) {
                    ForEach(response.series) { point in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(point.label)
                                    .font(.headline)
                                Text("\(point.sessionCount ?? 0)회 러닝")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text(Formatters.distance(point.totalKm))
                                Text(Formatters.pace(point.avgPace))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
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
    }
}

#Preview {
    NavigationStack {
        ReportView(viewModel: ReportViewModel(service: PreviewRunningHealthService.shared))
    }
}
