import Foundation

@MainActor
final class ReportViewModel: ObservableObject {
    @Published var period: String = "weekly"
    @Published var n: Double = 8
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var response: HealthReportResponse?

    private let service: RunningHealthServiceProviding

    init(service: RunningHealthServiceProviding) {
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            let result = try await service.fetchReport(period: period, n: Int(n))
            response = result
            state = result.series.isEmpty ? .empty("리포트 데이터가 없습니다.") : .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
