import Foundation

@MainActor
final class StructuredQueryViewModel: ObservableObject {
    @Published var metric: String = "pace"
    @Published var period: String = "weekly"
    @Published var limit: Double = 6
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var response: HealthQueryResponse?
    @Published private(set) var tools: [ToolDefinition] = []

    private let service: RunningHealthServiceProviding

    init(service: RunningHealthServiceProviding) {
        self.service = service
    }

    func loadInitial() async {
        do {
            tools = try await service.fetchToolCatalog()
        } catch {
            tools = []
        }
        await load()
    }

    func load() async {
        state = .loading
        do {
            let result = try await service.fetchStructuredQuery(metric: metric, period: period, limit: Int(limit))
            response = result
            state = result.data.isEmpty ? .empty("조회 결과가 없습니다.") : .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
