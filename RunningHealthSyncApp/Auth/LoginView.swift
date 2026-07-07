import SwiftUI

struct LoginView: View {
    @ObservedObject var auth: StravaAuthManager

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(AppTheme.coral)

                    Text("Runners Hello")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text("Strava 러닝 기록을 가져와 주간 흐름, 페이스 변화, 회복 상태, 오늘 달릴 코스를 한 화면에서 보여줍니다.")
                        .font(.body)
                        .foregroundStyle(AppTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    LoginBenefitRow(icon: "chart.line.uptrend.xyaxis", title: "최근 기록 요약", detail: "거리와 페이스 변화를 바로 확인")
                    LoginBenefitRow(icon: "heart.text.square", title: "회복 상태 확인", detail: "부하와 휴식 간격을 함께 표시")
                    LoginBenefitRow(icon: "map", title: "러닝 코스 추천", detail: "위치와 날씨를 반영한 추천")
                }
                .padding(18)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: AppTheme.shadow, radius: 12, y: 6)

                if let error = auth.errorMessage {
                    StatusCard(
                        title: "로그인할 수 없습니다",
                        message: error,
                        systemImage: "exclamationmark.triangle",
                        tint: .red
                    )
                }

                ActionButton(
                    title: auth.isAuthenticating ? "Strava 연결 중" : "Strava로 계속하기",
                    systemImage: "arrow.right",
                    accent: AppTheme.coral,
                    isLoading: auth.isAuthenticating
                ) {
                    Task { await auth.login() }
                }

                Text("로그인 후 앱 세션 토큰만 기기에 저장됩니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 24)
            }
            .padding(24)
        }
    }
}

private struct LoginBenefitRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(AppTheme.sky)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
