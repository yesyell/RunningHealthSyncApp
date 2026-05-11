import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: AppPreferencesStore

    var body: some View {
        AppScreen(
            title: "사용자 설정",
            subtitle: "목표와 선호값을 앱 로컬에 저장해 대시보드, 리포트, 추천 화면에 우선 반영합니다.",
            state: .loaded,
            accent: AppTheme.sky
        ) {
            InsightBanner(
                eyebrow: "Local Override",
                headline: preferences.hasOverrides ? "현재 로컬 설정이 서버 프로필보다 우선합니다" : "아직 로컬 오버라이드가 없습니다",
                detail: "Strava 연동 전 단계라 현재 설정은 이 기기에서만 저장됩니다. 비워두면 서버 기본값을 그대로 사용합니다.",
                accent: AppTheme.sky
            )

            SectionCard(title: "기본 프로필", systemImage: "person.crop.circle", accent: AppTheme.sky) {
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
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppTheme.sky.opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                        MetricPill(title: "목표 페이스", value: preferences.targetPaceMinKm.map { Formatters.pace($0) } ?? "서버 기본값", tone: AppTheme.sky)
                        MetricPill(title: "주간 목표", value: preferences.weeklyTargetKmValue.map { Formatters.distance($0) } ?? "서버 기본값", tone: AppTheme.mint)
                        MetricPill(title: "선호 지역", value: preferences.effectiveLocation(fallback: nil) ?? "서버 기본값", tone: AppTheme.coral)
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
    }
}

#Preview {
    NavigationStack {
        SettingsView(preferences: AppPreferencesStore())
    }
}
