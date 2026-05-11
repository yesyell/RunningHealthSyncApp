import SwiftUI

struct RecommendationView: View {
    @StateObject private var viewModel: RecommendationViewModel

    init(viewModel: RecommendationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AppScreen(
            title: "추천 코스",
            subtitle: "위치와 날씨를 기준으로 코스, 권장 페이스, cold tips를 보여줍니다.",
            state: viewModel.state,
            accent: AppTheme.sky
        ) {
            InsightBanner(
                eyebrow: "코스 추천",
                headline: "위치와 날씨를 함께 고려한 러닝 추천",
                detail: "추운 날은 페이스를 보수적으로 잡고, 선호 거리와 지역을 우선 반영합니다.",
                accent: AppTheme.sky
            )

            SectionCard(title: "입력", systemImage: "location", accent: AppTheme.sky) {
                AppTextField(title: "지역", text: $viewModel.location)
                HStack {
                    AppTextField(title: "위도", text: $viewModel.latitude, keyboard: .decimalPad)
                    AppTextField(title: "경도", text: $viewModel.longitude, keyboard: .decimalPad)
                }
                ActionButton(title: "추천 받기", systemImage: "map.fill", accent: AppTheme.sky) {
                    Task { await viewModel.load() }
                }
            }

            if let response = viewModel.response {
                SectionCard(title: "요약", systemImage: "cloud.sun", accent: AppTheme.mint) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            MetricPill(title: "기온", value: "\(Formatters.number(response.weather.tempC))°C", tone: AppTheme.sky)
                            MetricPill(title: "최근 페이스", value: Formatters.pace(response.recentPaceMinKm), tone: AppTheme.coral)
                            MetricPill(title: "권장 페이스", value: Formatters.pace(response.suggestedPaceMinKm), tone: AppTheme.mint)
                        }
                    }
                    Text(response.weather.isCold ? "추운 날 조건이 감지되어 보수적인 권장 페이스를 반영했습니다." : "일반 기온 기준으로 추천했습니다.")
                        .foregroundStyle(.secondary)
                }

                SectionCard(title: "코스 리스트", systemImage: "figure.run.square.stack", accent: AppTheme.sky) {
                    ForEach(response.courses) { course in
                        CourseSpotlightCard(
                            title: course.name ?? "이름 없는 코스",
                            location: course.location ?? "-",
                            distance: Formatters.distance(course.distanceKm),
                            description: course.description,
                            badge: course.coldSuitable == 1 ? "Cold OK" : "일반",
                            accent: course.coldSuitable == 1 ? AppTheme.mint : AppTheme.sky
                        )
                    }
                }

                if !response.coldTips.isEmpty {
                    SectionCard(title: "Cold Tips", systemImage: "snowflake", accent: AppTheme.coral) {
                        TagWrap(items: response.coldTips, accent: AppTheme.coral)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecommendationView(viewModel: RecommendationViewModel(service: PreviewRunningHealthService.shared))
    }
}
