import Charts
import SwiftUI
import UIKit

enum AppTheme {
    static let ink = Color(red: 0.11, green: 0.17, blue: 0.27)
    static let sky = Color(red: 0.30, green: 0.63, blue: 0.96)
    static let mint = Color(red: 0.36, green: 0.80, blue: 0.70)
    static let coral = Color(red: 0.99, green: 0.53, blue: 0.42)
    static let sand = Color(red: 0.95, green: 0.97, blue: 0.99)
    static let card = Color.white.opacity(0.86)
    static let shadow = Color.black.opacity(0.08)
}

enum ResponsiveLayout {
    static var screenHeight: CGFloat { UIScreen.main.bounds.height }
    static var isTallPhone: Bool { screenHeight >= 850 }
    static var heroHeight: CGFloat { isTallPhone ? 178 : 154 }
    static var chartHeight: CGFloat { isTallPhone ? 236 : 196 }
    static var editorHeight: CGFloat { isTallPhone ? 138 : 112 }
    static var sectionSpacing: CGFloat { isTallPhone ? 18 : 14 }
}

enum AppChrome {
    static func configure() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        tabAppearance.shadowColor = UIColor.clear
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.sky)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.sky),
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppTheme.ink.opacity(0.55))
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.ink.opacity(0.55)),
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.ink),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.ink),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(AppTheme.sky)
    }
}

enum Formatters {
    static func paceDisplay(_ value: Double) -> String {
        let totalSeconds = Int((value * 60).rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    static func pace(_ value: Double?) -> String {
        guard let value else { return "데이터 없음" }
        return paceDisplay(value) + "/km"
    }

    static func distance(_ value: Double?) -> String {
        guard let value else { return "데이터 없음" }
        return String(format: "%.1fkm", value)
    }

    static func number(_ value: Double?) -> String {
        guard let value else { return "데이터 없음" }
        return String(format: "%.2f", value)
    }

    static func trend(_ value: String?) -> String {
        switch value {
        case "improving":
            return "개선"
        case "worsening":
            return "악화"
        case "stable":
            return "안정"
        case "insufficient_data":
            return "데이터 부족"
        default:
            return value ?? "-"
        }
    }

}

struct RootTabView: View {
    let service: RunningHealthServiceProviding
    @ObservedObject var preferences: AppPreferencesStore

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(viewModel: DashboardViewModel(service: service))
            }
            .tabItem {
                Label("대시보드", systemImage: "gauge.with.dots.needle.50percent")
            }

            NavigationStack {
                NaturalLanguageQueryView(viewModel: NaturalLanguageQueryViewModel(service: service))
            }
            .tabItem {
                Label("질의", systemImage: "text.bubble")
            }

            NavigationStack {
                ReportView(viewModel: ReportViewModel(service: service))
            }
            .tabItem {
                Label("리포트", systemImage: "chart.bar.doc.horizontal")
            }

            NavigationStack {
                InsightView(viewModel: InsightViewModel(service: service))
            }
            .tabItem {
                Label("인사이트", systemImage: "waveform.path.ecg")
            }

            NavigationStack {
                RecommendationView(viewModel: RecommendationViewModel(service: service, preferences: preferences))
            }
            .tabItem {
                Label("코스 추천", systemImage: "map")
            }

            NavigationStack {
                StructuredQueryView(viewModel: StructuredQueryViewModel(service: service))
            }
            .tabItem {
                Label("구조화 조회", systemImage: "line.3.horizontal.decrease.circle")
            }

            NavigationStack {
                SettingsView(preferences: preferences)
            }
            .tabItem {
                Label("설정", systemImage: "slider.horizontal.3")
            }
        }
        .tint(AppTheme.sky)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}

struct AppScreen<Content: View>: View {
    let title: String
    let subtitle: String
    let state: ViewState
    let accent: Color
    let content: Content

    init(title: String, subtitle: String, state: ViewState, accent: Color = AppTheme.sky, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.state = state
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.sand, accent.opacity(0.14), AppTheme.mint.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: ResponsiveLayout.sectionSpacing) {
                    HeroHeader(title: title, subtitle: subtitle, accent: accent)

                    switch state {
                    case .idle, .loaded:
                        content
                            .transition(.asymmetric(insertion: .offset(y: 16).combined(with: .opacity), removal: .opacity))
                    case .loading:
                        SkeletonScreen(accent: accent)
                            .transition(.opacity)
                    case let .empty(message):
                        StatusCard(title: "빈 데이터", message: message, tint: accent)
                    case let .failed(message):
                        StatusCard(title: "오류", message: message, tint: .red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, ResponsiveLayout.isTallPhone ? 34 : 24)
            }
            .scrollIndicators(.hidden)
        }
        .animation(.spring(duration: 0.42, bounce: 0.14), value: stateKey)
    }

    private var stateKey: String {
        switch state {
        case .idle:
            return "idle"
        case .loading:
            return "loading"
        case .loaded:
            return "loaded"
        case .empty:
            return "empty"
        case .failed:
            return "failed"
        }
    }
}

struct StatusCard: View {
    let title: String
    let message: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "exclamationmark.bubble")
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(tint.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    let accent: Color
    let content: Content

    init(title: String, systemImage: String, accent: Color = AppTheme.sky, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .strokeBorder(accent.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    var tone: Color = AppTheme.sky

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(tone.opacity(0.85))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(tone.opacity(0.12))
        .overlay(
            Capsule()
                .strokeBorder(tone.opacity(0.18), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

struct ResultJSONCard: View {
    let title: String
    let payload: JSONValue

    var body: some View {
        SectionCard(title: title, systemImage: "curlybraces") {
            DisclosureGroup("원본 응답 보기") {
                Text(payload.prettyPrinted())
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
            }
            .font(.subheadline.weight(.semibold))
        }
    }
}

struct HeroHeader: View {
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.ink, accent, AppTheme.mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 180, height: 180)
                .offset(x: 170, y: -50)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity)
        .frame(height: ResponsiveLayout.heroHeight)
        .shadow(color: accent.opacity(0.22), radius: 20, y: 10)
    }
}

struct AppTextField: View {
    let title: String
    let text: Binding<String>
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .keyboardType(keyboard)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(.white.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppTheme.sky.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct InsightBanner: View {
    let eyebrow: String
    let headline: String
    let detail: String
    var accent: Color = AppTheme.sky

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)
            Text(headline)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(accent.opacity(0.16), lineWidth: 1)
        )
    }
}

struct ActionButton: View {
    let title: String
    var systemImage: String = "arrow.right"
    var accent: Color = AppTheme.sky
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: systemImage)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct CourseSpotlightCard: View {
    let title: String
    let location: String
    let distance: String
    let description: String?
    let badge: String
    var accent: Color = AppTheme.sky

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.16), .white.opacity(0.9), AppTheme.mint.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent.opacity(0.14), lineWidth: 1)

            Circle()
                .fill(accent.opacity(0.12))
                .frame(width: 110, height: 110)
                .offset(x: 210, y: -14)

            VStack(alignment: .leading, spacing: 10) {
                RouteThumbnail(accent: accent)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                        Text("\(location) · \(distance)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(badge)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(accent.opacity(0.14))
                        .clipShape(Capsule())
                }

                HStack(spacing: 8) {
                    Capsule().fill(accent).frame(width: 34, height: 6)
                    Capsule().fill(AppTheme.mint).frame(width: 22, height: 6)
                    Capsule().fill(AppTheme.coral.opacity(0.8)).frame(width: 14, height: 6)
                }

                if let description, !description.isEmpty {
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: accent.opacity(0.10), radius: 14, y: 8)
    }
}

struct RouteThumbnail: View {
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.18), AppTheme.mint.opacity(0.16), .white.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 110)

            Path { path in
                path.move(to: CGPoint(x: 26, y: 78))
                path.addCurve(to: CGPoint(x: 115, y: 30), control1: CGPoint(x: 44, y: 18), control2: CGPoint(x: 86, y: 94))
                path.addCurve(to: CGPoint(x: 218, y: 70), control1: CGPoint(x: 142, y: 8), control2: CGPoint(x: 188, y: 126))
                path.addCurve(to: CGPoint(x: 290, y: 38), control1: CGPoint(x: 242, y: 48), control2: CGPoint(x: 274, y: 54))
            }
            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round, dash: [1, 0]))
            .foregroundStyle(accent)
            .frame(height: 110)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Label("추천 루트", systemImage: "map")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accent)
                    Text("도심 + 강변 흐름")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
        }
    }
}

struct SkeletonScreen: View {
    let accent: Color

    var body: some View {
        VStack(spacing: ResponsiveLayout.sectionSpacing) {
            SkeletonCard(lines: [18, 12, 12], accent: accent)
            SkeletonMetricsRow(accent: accent)
            SkeletonChartCard(accent: accent)
            SkeletonCard(lines: [14, 14, 10], accent: accent)
        }
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

struct SkeletonMetricsRow: View {
    let accent: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 24)
                        .fill(accent.opacity(0.14))
                        .frame(width: 118, height: 62)
                }
            }
        }
    }
}

struct SkeletonChartCard: View {
    let accent: Color

    var body: some View {
        SectionCard(title: "로딩 중", systemImage: "chart.xyaxis.line", accent: accent) {
            RoundedRectangle(cornerRadius: 18)
                .fill(accent.opacity(0.12))
                .frame(height: ResponsiveLayout.chartHeight)
        }
    }
}

struct SkeletonCard: View {
    let lines: [CGFloat]
    let accent: Color

    var body: some View {
        SectionCard(title: "불러오는 중", systemImage: "sparkles", accent: accent) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, width in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accent.opacity(index == 0 ? 0.18 : 0.10))
                        .frame(width: width * 12, height: 14)
                }
            }
        }
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.8

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.35), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .rotationEffect(.degrees(20))
                    .offset(x: proxy.size.width * phase)
                    .blendMode(.plusLighter)
                }
                .mask(content)
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                    phase = 1.1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

struct TagWrap: View {
    let items: [String]
    var accent: Color = AppTheme.sky

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunked(items, size: 2), id: \.self) { row in
                HStack {
                    ForEach(row, id: \.self) { item in
                        Text(item)
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(accent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func chunked(_ items: [String], size: Int) -> [[String]] {
        stride(from: 0, to: items.count, by: size).map {
            Array(items[$0 ..< min($0 + size, items.count)])
        }
    }
}
