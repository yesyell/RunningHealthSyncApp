import SwiftUI

struct NaturalLanguageQueryView: View {
    @StateObject private var viewModel: NaturalLanguageQueryViewModel

    init(viewModel: NaturalLanguageQueryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AppScreen(
            title: "자연어 질의",
            subtitle: "러닝 기록에 대해 평소 말하듯 질문하고 핵심 답변을 확인합니다.",
            state: viewModel.state,
            accent: AppTheme.coral,
            onRetry: { Task { await viewModel.submit() } }
        ) {
            InsightBanner(
                eyebrow: "질문",
                headline: "궁금한 내용을 그대로 입력하세요",
                detail: "기간이나 지표를 정확히 몰라도 앱이 질문 의도를 정리해 답변합니다.",
                accent: AppTheme.coral
            )

            SectionCard(title: "질문 입력", systemImage: "text.cursor", accent: AppTheme.coral) {
                TextEditor(text: $viewModel.queryText)
                    .font(.body)
                    .frame(minHeight: ResponsiveLayout.editorHeight)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                SuggestionChips(items: [
                    "최근 4주 페이스 좋아지고 있어?",
                    "이번 달 거리 얼마나 뛰었어?",
                    "회복 상태 어때?",
                    "오늘 마포구에서 어디 달릴까?"
                ], accent: AppTheme.coral) { suggestion in
                    viewModel.queryText = suggestion
                }

                ActionButton(title: "답변 받기", systemImage: "sparkles", accent: AppTheme.coral, isLoading: viewModel.state.isLoading) {
                    Task { await viewModel.submit() }
                }
            }

            if let response = viewModel.response {
                SectionCard(title: "질문 이해", systemImage: "brain.head.profile", accent: AppTheme.sky) {
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
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                SectionCard(title: "확인한 항목", systemImage: "point.3.connected.trianglepath.dotted", accent: AppTheme.mint) {
                    ForEach(response.interpretation.nextActions) { action in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(displayName(for: action.tool))
                                    .font(.headline)
                                Spacer()
                                Text("확인됨")
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
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                SectionCard(title: "코치 요약", systemImage: "text.alignleft", accent: AppTheme.coral) {
                    Text(response.reply)
                        .textSelection(.enabled)
                        .lineSpacing(4)
                }

                ForEach(Array(response.toolResults.enumerated()), id: \.offset) { index, result in
                    SectionCard(title: "상세 결과 \(index + 1)", systemImage: "server.rack", accent: AppTheme.sky) {
                        Text(result.reason ?? "후속 실행 결과")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ResultJSONCard(title: "원본 데이터", payload: result.result)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func displayName(for tool: String) -> String {
        switch tool {
        case "health_query":
            return "기록 조회"
        case "health_insight":
            return "추세 분석"
        case "health_report":
            return "리포트 확인"
        case "running_recommend":
            return "코스 추천"
        default:
            return "분석 항목"
        }
    }
}

#Preview {
    NavigationStack {
        NaturalLanguageQueryView(viewModel: NaturalLanguageQueryViewModel(service: PreviewRunningHealthService.shared))
    }
}
