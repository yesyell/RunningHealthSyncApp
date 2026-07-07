import Charts
import SwiftUI

struct InsightView: View {
    @StateObject private var viewModel: InsightViewModel

    init(viewModel: InsightViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AppScreen(
            title: "인사이트",
            subtitle: "페이스, 거리, 주간 훈련량, 회복 상태의 변화를 읽기 쉽게 정리합니다.",
            state: viewModel.state,
            accent: AppTheme.coral,
            onRetry: { Task { await viewModel.load() } }
        ) {
            InsightBanner(
                eyebrow: "분석",
                headline: "추세와 목표 차이를 한 번에 읽습니다",
                detail: "페이스, 거리, 주간 거리, 회복 상태를 각각 다른 관점으로 해석합니다.",
                accent: AppTheme.coral
            )

            SectionCard(title: "분석 조건", systemImage: "waveform", accent: AppTheme.coral) {
                Picker("지표", selection: $viewModel.metric) {
                    Text("페이스").tag("pace")
                    Text("거리").tag("distance")
                    Text("주간 거리").tag("weekly_mileage")
                    Text("회복").tag("recovery")
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading) {
                    Text("최근 \(Int(viewModel.weeks))주")
                    Slider(value: $viewModel.weeks, in: 2 ... 12, step: 1)
                }

                ActionButton(title: "인사이트 조회", systemImage: "waveform.path.ecg", accent: AppTheme.coral, isLoading: viewModel.state.isLoading) {
                    Task { await viewModel.load() }
                }
            }

            if let response = viewModel.response {
                SectionCard(title: "분석 결과", systemImage: "sparkles", accent: AppTheme.sky) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            MetricPill(title: "추세", value: Formatters.trend(response.analysis.trend), tone: AppTheme.coral)
                            MetricPill(title: "최근 값", value: response.metric == "pace" ? Formatters.pace(response.analysis.latestValue) : Formatters.number(response.analysis.latestValue), tone: AppTheme.sky)
                            MetricPill(title: "목표 차이", value: Formatters.number(response.analysis.gapToTarget), tone: AppTheme.mint)
                        }
                    }
                    Text(response.analysis.insight)
                        .foregroundStyle(.secondary)
                    if let guidelines = response.analysis.guidelines, !guidelines.isEmpty {
                        TagWrap(items: guidelines, accent: AppTheme.sky)
                    }
                }

                if response.metric == "recovery" {
                    SectionCard(title: "회복 신호", systemImage: "heart.circle", accent: AppTheme.mint) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                MetricPill(title: "휴식 간격", value: "\(Formatters.number(response.analysis.avgRestDays))일", tone: AppTheme.sky)
                                MetricPill(title: "평균 심박", value: "\(Formatters.number(response.analysis.avgSessionBpm))bpm", tone: AppTheme.coral)
                                MetricPill(title: "부하 비율", value: Formatters.number(response.analysis.loadRatio), tone: AppTheme.mint)
                            }
                        }
                    }
                } else {
                    SectionCard(title: "추세 차트", systemImage: "chart.line.uptrend.xyaxis", accent: AppTheme.mint) {
                        Chart(response.series) { point in
                            LineMark(
                                x: .value("주", point.weekStart),
                                y: .value("값", response.metric == "pace" ? (point.avgPace ?? 0) : (point.totalKm ?? 0))
                            )
                            .foregroundStyle(response.metric == "pace" ? AppTheme.coral : AppTheme.sky)
                            PointMark(
                                x: .value("주", point.weekStart),
                                y: .value("값", response.metric == "pace" ? (point.avgPace ?? 0) : (point.totalKm ?? 0))
                            )
                            .foregroundStyle(response.metric == "pace" ? AppTheme.coral : AppTheme.sky)
                        }
                        .frame(height: ResponsiveLayout.chartHeight)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
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
        InsightView(viewModel: InsightViewModel(service: PreviewRunningHealthService.shared))
    }
}
