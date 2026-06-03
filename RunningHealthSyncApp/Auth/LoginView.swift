import SwiftUI

struct LoginView: View {
    @ObservedObject var auth: StravaAuthManager

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "figure.run")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("Runners Hello")
                .font(.largeTitle.bold())

            Text("Strava 계정으로 로그인하면 러닝 기록을 분석합니다.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let error = auth.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task { await auth.login() }
            } label: {
                HStack {
                    if auth.isAuthenticating {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(auth.isAuthenticating ? "연결 중" : "Strava로 로그인")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(auth.isAuthenticating)
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}
