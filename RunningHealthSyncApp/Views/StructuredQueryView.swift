import SwiftUI

struct StructuredQueryView: View {
    @StateObject private var viewModel: StructuredQueryViewModel

    init(viewModel: StructuredQueryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AppScreen(
            title: "구조화 조회",
            subtitle: "지표와 기간을 골라 러닝 기록을 표 형태로 확인합니다.",
            state: viewModel.state,
            accent: AppTheme.mint,
            onRetry: { Task { await viewModel.load() } }
        ) {
            InsightBanner(
                eyebrow: "상세 조회",
                headline: "보고 싶은 지표만 골라 확인하세요",
                detail: "페이스, 주간 거리, 심박처럼 필요한 항목을 기간별로 비교합니다.",
                accent: AppTheme.mint
            )

            SectionCard(title: "조회 조건", systemImage: "line.3.horizontal.decrease.circle", accent: AppTheme.mint) {
                Picker("지표", selection: $viewModel.metric) {
                    Text("페이스").tag("pace")
                    Text("주간 거리").tag("weekly_mileage")
                    Text("거리").tag("distance")
                    Text("세션").tag("sessions")
                    Text("심박").tag("heart_rate")
                }
                .pickerStyle(.segmented)

                Picker("기간", selection: $viewModel.period) {
                    Text("주간").tag("weekly")
                    Text("월간").tag("monthly")
                    Text("최근 세션").tag("recent_sessions")
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading) {
                    Text("결과 수 \(Int(viewModel.limit))")
                    Slider(value: $viewModel.limit, in: 1 ... 12, step: 1)
                }

                ActionButton(title: "조회하기", systemImage: "bolt.horizontal.circle", accent: AppTheme.mint, isLoading: viewModel.state.isLoading) {
                    Task { await viewModel.load() }
                }
            }

            if let response = viewModel.response {
                SectionCard(title: "조회 요약", systemImage: "shippingbox", accent: AppTheme.sky) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            MetricPill(title: "조회 방식", value: response.query.mode, tone: AppTheme.sky)
                            MetricPill(title: "결과 수", value: "\(response.context.rowCount)", tone: AppTheme.mint)
                            MetricPill(title: "목표", value: response.context.userGoal ?? "-", tone: AppTheme.coral)
                        }
                    }
                }

                SectionCard(title: "데이터", systemImage: "tablecells", accent: AppTheme.mint) {
                    ForEach(response.data) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(row.primaryLabel)
                                .font(.headline)
                            Text(row.detailPairs.map { "\($0.0): \($0.1)" }.joined(separator: " · "))
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.62))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                if !viewModel.tools.isEmpty {
                    SectionCard(title: "사용 가능한 분석", systemImage: "wrench.and.screwdriver", accent: AppTheme.coral) {
                        TagWrap(items: viewModel.tools.map { displayName(for: $0.name) }, accent: AppTheme.coral)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if case .idle = viewModel.state {
                await viewModel.loadInitial()
            }
        }
    }

    private func displayName(for tool: String) -> String {
        switch tool {
        case "health_query":
            return "기록 조회"
        case "health_interpret":
            return "질문 이해"
        case "health_report":
            return "리포트"
        case "running_recommend":
            return "코스 추천"
        case "health_insight":
            return "추세 분석"
        default:
            return tool
        }
    }
}

#Preview {
    NavigationStack {
        StructuredQueryView(viewModel: StructuredQueryViewModel(service: PreviewRunningHealthService.shared))
    }
}
