import SwiftUI

struct StructuredQueryView: View {
    @StateObject private var viewModel: StructuredQueryViewModel

    init(viewModel: StructuredQueryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AppScreen(
            title: "구조화 조회",
            subtitle: "`health_query`를 metric / period / limit 기반으로 직접 호출합니다.",
            state: viewModel.state,
            accent: AppTheme.mint
        ) {
            InsightBanner(
                eyebrow: "직접 조회",
                headline: "도구 스키마 기반으로 구조화 호출",
                detail: "metric, period, limit를 바꾸면서 MCP가 반환하는 실제 데이터를 바로 확인할 수 있습니다.",
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

                ActionButton(title: "조회 실행", systemImage: "bolt.horizontal.circle", accent: AppTheme.mint) {
                    Task { await viewModel.load() }
                }
            }

            if let response = viewModel.response {
                SectionCard(title: "응답 메타", systemImage: "shippingbox", accent: AppTheme.sky) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            MetricPill(title: "mode", value: response.query.mode, tone: AppTheme.sky)
                            MetricPill(title: "rows", value: "\(response.context.rowCount)", tone: AppTheme.mint)
                            MetricPill(title: "goal", value: response.context.userGoal ?? "-", tone: AppTheme.coral)
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
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }

                if !viewModel.tools.isEmpty {
                    SectionCard(title: "사용 가능한 Tools", systemImage: "wrench.and.screwdriver", accent: AppTheme.coral) {
                        TagWrap(items: viewModel.tools.map(\.name), accent: AppTheme.coral)
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
}

#Preview {
    NavigationStack {
        StructuredQueryView(viewModel: StructuredQueryViewModel(service: PreviewRunningHealthService.shared))
    }
}
