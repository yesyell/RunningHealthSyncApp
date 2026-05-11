import Foundation

@MainActor
final class NaturalLanguageQueryViewModel: ObservableObject {
    @Published var queryText: String = "최근 4주 페이스 좋아지고 있어?"
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var response: NaturalLanguageResponse?

    private let service: RunningHealthServiceProviding

    init(service: RunningHealthServiceProviding) {
        self.service = service
    }

    func submit() async {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .empty("질문을 입력해주세요.")
            response = nil
            return
        }
        state = .loading
        do {
            let result = try await service.fetchNaturalLanguageResponse(query: trimmed)
            response = result
            state = result.toolResults.isEmpty ? .empty("해석은 되었지만 연결된 tool 실행이 없습니다.") : .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
