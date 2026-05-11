import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var dashboard: DashboardResponse?

    private let service: RunningHealthServiceProviding

    init(service: RunningHealthServiceProviding) {
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            let response = try await service.fetchDashboard(location: nil, lat: nil, lon: nil)
            dashboard = response
            if response.weeklyReport.series.isEmpty {
                state = .empty("최근 주간 데이터가 없습니다.")
            } else {
                state = .loaded
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
