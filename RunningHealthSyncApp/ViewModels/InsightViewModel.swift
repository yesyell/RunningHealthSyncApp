import Foundation

@MainActor
final class InsightViewModel: ObservableObject {
    @Published var metric: String = "pace"
    @Published var weeks: Double = 4
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var response: HealthInsightResponse?

    private let service: RunningHealthServiceProviding

    init(service: RunningHealthServiceProviding) {
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            let result = try await service.fetchInsight(metric: metric, weeks: Int(weeks))
            response = result
            state = result.series.isEmpty ? .empty("인사이트를 계산할 데이터가 부족합니다.") : .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
