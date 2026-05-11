import SwiftUI

struct NaturalLanguageQueryView: View {
    @StateObject private var viewModel: NaturalLanguageQueryViewModel

    init(viewModel: NaturalLanguageQueryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AppScreen(
            title: "자연어 질의",
            subtitle: "질문을 해석하고, `next_actions` 기반 tool 호출 결과를 함께 보여줍니다.",
            state: viewModel.state,
            accent: AppTheme.coral
        ) {
            InsightBanner(
                eyebrow: "질문 예시",
                headline: "데이터 조회보다 먼저 해석합니다",
                detail: "`health_interpret`가 의도와 기간을 정리한 뒤, 필요한 tool을 순서대로 호출합니다.",
                accent: AppTheme.coral
            )

            SectionCard(title: "질문 입력", systemImage: "text.cursor", accent: AppTheme.coral) {
                TextEditor(text: $viewModel.queryText)
                    .font(.body)
                    .frame(minHeight: ResponsiveLayout.editorHeight)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                TagWrap(items: [
                    "최근 4주 페이스 좋아지고 있어?",
                    "이번 달 거리 얼마나 뛰었어?",
                    "회복 상태 어때?",
                    "오늘 마포구에서 어디 달릴까?"
                ], accent: AppTheme.coral)

                ActionButton(title: "질문 분석하기", systemImage: "sparkles", accent: AppTheme.coral) {
                    Task { await viewModel.submit() }
                }
            }

            if let response = viewModel.response {
                SectionCard(title: "해석 결과", systemImage: "brain.head.profile", accent: AppTheme.sky) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            MetricPill(title: "의도", value: response.interpretation.intent, tone: AppTheme.coral)
                            MetricPill(title: "기간", value: response.interpretation.period.type, tone: AppTheme.sky)
                            MetricPill(title: "집계", value: response.interpretation.aggregation, tone: AppTheme.mint)
                        }
                    }
                    if !response.interpretation.matchedConcepts.isEmpty {
                        ForEach(response.interpretation.matchedConcepts) { concept in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(concept.label)
                                    .font(.headline)
                                if let guidelines = concept.guidelines, !guidelines.isEmpty {
                                    TagWrap(items: guidelines, accent: AppTheme.sky)
                                }
                                if let misuse = concept.commonMisuse {
                                    Text("주의: \(misuse)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(14)
                            .background(AppTheme.sky.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }

                SectionCard(title: "후속 액션", systemImage: "point.3.connected.trianglepath.dotted", accent: AppTheme.mint) {
                    ForEach(response.interpretation.nextActions) { action in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(action.tool)
                                    .font(.headline)
                                Spacer()
                                Text("자동 실행")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.mint)
                            }
                            Text(action.reason)
                                .foregroundStyle(.secondary)
                            Text(action.arguments.map { "\($0.key)=\($0.value.prettyPrinted())" }.sorted().joined(separator: ", "))
                                .font(.footnote.monospaced())
                        }
                        .padding(14)
                        .background(AppTheme.mint.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }

                SectionCard(title: "코치 요약", systemImage: "text.alignleft", accent: AppTheme.coral) {
                    Text(response.reply)
                        .textSelection(.enabled)
                        .lineSpacing(4)
                }

                ForEach(Array(response.toolResults.enumerated()), id: \.offset) { index, result in
                    SectionCard(title: "실행 결과 \(index + 1) · \(result.tool)", systemImage: "server.rack", accent: AppTheme.sky) {
                        Text(result.reason ?? "후속 실행 결과")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ResultJSONCard(title: "응답 payload", payload: result.result)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        NaturalLanguageQueryView(viewModel: NaturalLanguageQueryViewModel(service: PreviewRunningHealthService.shared))
    }
}
