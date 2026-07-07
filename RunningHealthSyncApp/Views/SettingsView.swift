import SwiftUI

struct SettingsView: View {
    let service: RunningHealthServiceProviding
    @ObservedObject var preferences: AppPreferencesStore
    @ObservedObject private var sessionStore = KeychainSessionStore.shared
    @State private var dashboard: DashboardResponse?
    @State private var isLoadingProfile = false
    @State private var profileStatusMessage: String?
    @State private var profileStatusIsError = false

    var body: some View {
        AppScreen(
            title: "러너 설정",
            subtitle: "목표, 선호 위치, 추천 기준을 내 러닝 스타일에 맞게 조정합니다.",
            state: .loaded,
            accent: AppTheme.sky
        ) {
            InsightBanner(
                eyebrow: sessionStore.isLoggedIn ? "Strava Connected" : "Signed Out",
                headline: dashboard.map { "\($0.userProfile.name)님의 러닝 기록을 동기화했습니다" } ?? "Strava 세션을 확인 중입니다",
                detail: dashboard.map(profileSummary) ?? "로그인 후 Strava 활동을 기반으로 리포트와 추천이 생성됩니다.",
                accent: AppTheme.sky
            )

            SectionCard(title: "Strava 연결", systemImage: "figure.run.circle", accent: AppTheme.coral) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: sessionStore.isLoggedIn ? "checkmark.seal.fill" : "xmark.seal")
                        .font(.title2)
                        .foregroundStyle(sessionStore.isLoggedIn ? AppTheme.mint : AppTheme.coral)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(sessionStore.isLoggedIn ? "연결됨" : "연결 필요")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text(dashboard.map { "Athlete ID 기반으로 \($0.weeklyReport.series.count)개 주간 요약을 불러왔습니다." } ?? "서버 프로필을 불러오면 최근 기록 요약이 표시됩니다.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let dashboard {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            MetricPill(title: "이름", value: dashboard.userProfile.name, tone: AppTheme.sky)
                            MetricPill(title: "최근 거리", value: Formatters.distance(dashboard.weeklyReport.series.first?.totalKm), tone: AppTheme.mint)
                            MetricPill(title: "최근 페이스", value: Formatters.pace(dashboard.paceInsight.analysis.latestValue), tone: AppTheme.coral)
                        }
                    }
                }

                if let profileStatusMessage {
                    Text(profileStatusMessage)
                        .font(.footnote)
                        .foregroundStyle(profileStatusIsError ? .red : .secondary)
                }

                HStack {
                    ActionButton(
                        title: isLoadingProfile ? "동기화 확인 중" : "Strava 기록 새로고침",
                        systemImage: "arrow.clockwise",
                        accent: AppTheme.sky,
                        isLoading: isLoadingProfile
                    ) {
                        Task { await loadProfile() }
                    }

                    ActionButton(
                        title: "로그아웃",
                        systemImage: "rectangle.portrait.and.arrow.right",
                        accent: AppTheme.coral
                    ) {
                        sessionStore.clear()
                    }
                }
            }

            SectionCard(title: "표시 프로필", systemImage: "person.crop.circle", accent: AppTheme.sky) {
                AppTextField(title: "이름", text: $preferences.name)
                AppTextField(title: "러닝 목표", text: $preferences.runningGoal)
                VStack(alignment: .leading, spacing: 6) {
                    Text("메모")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $preferences.notes)
                        .frame(minHeight: ResponsiveLayout.editorHeight)
                        .padding(10)
                        .background(.white.opacity(0.82))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(AppTheme.sky.opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            SectionCard(title: "훈련 목표", systemImage: "target", accent: AppTheme.mint) {
                AppTextField(title: "목표 페이스", text: $preferences.targetPace, keyboard: .numbersAndPunctuation)
                Text("입력 형식: `5:30` 또는 `5.5`")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                AppTextField(title: "주간 목표 거리(km)", text: $preferences.weeklyTargetKm, keyboard: .decimalPad)
                AppTextField(title: "선호 거리(km, 쉼표 구분)", text: $preferences.preferredDistances, keyboard: .numbersAndPunctuation)
                AppTextField(title: "안정시 심박", text: $preferences.restingHeartRate, keyboard: .numberPad)
            }

            SectionCard(title: "선호 위치", systemImage: "location", accent: AppTheme.coral) {
                AppTextField(title: "선호 지역", text: $preferences.preferredArea)
                HStack {
                    AppTextField(title: "기본 위도", text: $preferences.latitude, keyboard: .decimalPad)
                    AppTextField(title: "기본 경도", text: $preferences.longitude, keyboard: .decimalPad)
                }
                Text("추천 코스와 대시보드 추천 요청에 기본값으로 사용됩니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            SectionCard(title: "현재 반영값", systemImage: "checkmark.circle", accent: AppTheme.sky) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        MetricPill(title: "목표 페이스", value: effectivePaceText, tone: AppTheme.sky)
                        MetricPill(title: "주간 목표", value: effectiveWeeklyTargetText, tone: AppTheme.mint)
                        MetricPill(title: "선호 지역", value: effectiveAreaText, tone: AppTheme.coral)
                    }
                }

                if preferences.hasOverrides {
                    ActionButton(title: "로컬 오버라이드 해제", systemImage: "arrow.counterclockwise", accent: AppTheme.coral) {
                        preferences.resetOverrides()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if dashboard == nil {
                await loadProfile()
            }
        }
        .refreshable {
            await loadProfile()
        }
    }

    private var effectivePaceText: String {
        if let value = preferences.targetPaceMinKm ?? dashboard?.userProfile.targetPaceMinKm {
            return Formatters.pace(value)
        }
        return "서버 기본값"
    }

    private var effectiveWeeklyTargetText: String {
        if let value = preferences.weeklyTargetKmValue ?? dashboard?.userProfile.weeklyTargetKm {
            return Formatters.distance(value)
        }
        return "서버 기본값"
    }

    private var effectiveAreaText: String {
        preferences.effectiveLocation(fallback: dashboard?.userProfile.preferredArea) ?? "서버 기본값"
    }

    private func profileSummary(_ dashboard: DashboardResponse) -> String {
        let total = Formatters.distance(dashboard.weeklyReport.summary.totalKm)
        let pace = Formatters.pace(dashboard.paceInsight.analysis.latestValue)
        return "최근 동기화된 러닝 누적 거리는 \(total), 최근 주간 페이스는 \(pace)입니다."
    }

    @MainActor
    private func loadProfile() async {
        isLoadingProfile = true
        profileStatusIsError = false
        profileStatusMessage = "Strava 기록을 확인하는 중입니다."
        defer { isLoadingProfile = false }

        do {
            dashboard = try await service.fetchDashboard(location: nil, lat: nil, lon: nil)
            profileStatusMessage = "서버 프로필과 최근 러닝 요약을 불러왔습니다."
        } catch {
            profileStatusIsError = true
            profileStatusMessage = "Strava 기록을 불러오지 못했습니다: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(service: PreviewRunningHealthService.shared, preferences: AppPreferencesStore())
    }
}
