import Foundation

@MainActor
final class RecommendationViewModel: ObservableObject {
    @Published var location: String
    @Published var latitude: String
    @Published var longitude: String
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var response: RunningRecommendResponse?

    private let service: RunningHealthServiceProviding

    init(service: RunningHealthServiceProviding, preferences: AppPreferencesStore? = nil) {
        self.service = service
        location = preferences?.preferredArea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? preferences?.preferredArea ?? "마포구" : "마포구"
        latitude = preferences?.latitude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? preferences?.latitude ?? "37.5665" : "37.5665"
        longitude = preferences?.longitude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? preferences?.longitude ?? "126.9780" : "126.9780"
    }

    func load() async {
        state = .loading
        do {
            let result = try await service.fetchRecommendation(
                location: location,
                lat: Double(latitude),
                lon: Double(longitude)
            )
            response = result
            state = result.courses.isEmpty ? .empty("조건에 맞는 코스가 없습니다.") : .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
