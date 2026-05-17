import WidgetKit
import SwiftUI

private let appGroupIdentifier = "group.com.likhiththejas.drona"
private let widgetStyleStorageKey = "widget_style_configuration"
private let widgetRefreshInterval: TimeInterval = 300

private enum WidgetStyleKind: String, Codable, CaseIterable {
    case productivity
    case status
    case streak
    case goal
    case contribution
    case rest
    case portfolio

    var title: String {
        switch self {
        case .productivity: return "Productivity"
        case .status: return "Status"
        case .streak: return "Streak"
        case .goal: return "Daily Goal"
        case .contribution: return "Contributions"
        case .rest: return "Recovery"
        case .portfolio: return "Portfolio"
        }
    }

    var systemImage: String {
        switch self {
        case .productivity: return "gauge.with.dots.needle.67percent"
        case .status: return "sparkle.magnifyingglass"
        case .streak: return "flame.fill"
        case .goal: return "target"
        case .contribution: return "square.grid.3x3.fill"
        case .rest: return "moon.stars.fill"
        case .portfolio: return "sparkles.rectangle.stack.fill"
        }
    }
}

private enum WidgetBackgroundStyle: String, Codable {
    case flat
    case gradient
    case glass
    case minimalDark
    case glow
    case neon
    case elegant
}

private enum WidgetTypographyDesign: String, Codable {
    case system
    case rounded
    case monospaced
}

private enum WidgetFontWeightOption: String, Codable {
    case regular
    case medium
    case semibold
    case bold
}

private struct RGBAColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    static let white = RGBAColor(red: 1, green: 1, blue: 1, alpha: 1)
    static let softWhite = RGBAColor(red: 0.92, green: 0.96, blue: 1, alpha: 1)
    static let dark = RGBAColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 1)
}

private struct SharedWidgetStyleModel: Codable, Equatable {
    var widgetKind: WidgetStyleKind
    var backgroundStyle: WidgetBackgroundStyle
    var gradientStart: RGBAColor
    var gradientMiddle: RGBAColor
    var gradientEnd: RGBAColor
    var gradientAngle: Double
    var primaryText: RGBAColor
    var secondaryText: RGBAColor
    var accent: RGBAColor
    var borderColor: RGBAColor
    var cornerRadius: Double
    var borderThickness: Double
    var shadowIntensity: Double
    var glowIntensity: Double
    var padding: Double
    var fontScale: Double
    var fontWeight: WidgetFontWeightOption
    var typography: WidgetTypographyDesign
    var heatmapLow: RGBAColor
    var heatmapMedium: RGBAColor
    var heatmapHigh: RGBAColor
    var restDayColor: RGBAColor
    var gridSpacing: Double
    var cellRadius: Double
    var animationsEnabled: Bool
    var hoverGlowEnabled: Bool
    var pulseEffectsEnabled: Bool
}

private struct SharedWidgetStyleConfiguration: Codable, Equatable {
    var styles: [SharedWidgetStyleModel]
    var updatedAt: Date

    func style(for kind: WidgetStyleKind) -> SharedWidgetStyleModel {
        styles.first { $0.widgetKind == kind } ?? .defaultStyle(for: kind)
    }
}

private struct DronaWidgetSummary: Codable, Equatable {
    var productiveHours: Double
    var distractingHours: Double
    var productivityScore: Double
    var status: String
    var streak: Int
    var goalProgress: Double
    var leetCodeStreak: Int
    var leetCodeSolved: Int
    var leetCodeSolvedToday: Int
    var gitHubCommitsToday: Int
    var gitHubWeeklyCommits: Int
    var gitHubStreak: Int
    var codingActivity: [DronaCodingActivityDay]
    var portfolioRepositoryCount: Int
    var portfolioFeaturedProject: String
    var portfolioActiveProject: String
    var portfolioLatestCommit: String

    init(
        productiveHours: Double,
        distractingHours: Double,
        productivityScore: Double,
        status: String,
        streak: Int,
        goalProgress: Double,
        leetCodeStreak: Int = 0,
        leetCodeSolved: Int = 0,
        leetCodeSolvedToday: Int = 0,
        gitHubCommitsToday: Int = 0,
        gitHubWeeklyCommits: Int = 0,
        gitHubStreak: Int = 0,
        codingActivity: [DronaCodingActivityDay] = [],
        portfolioRepositoryCount: Int = 0,
        portfolioFeaturedProject: String = "None",
        portfolioActiveProject: String = "None",
        portfolioLatestCommit: String = "No commits loaded"
    ) {
        self.productiveHours = productiveHours
        self.distractingHours = distractingHours
        self.productivityScore = productivityScore
        self.status = status
        self.streak = streak
        self.goalProgress = goalProgress
        self.leetCodeStreak = leetCodeStreak
        self.leetCodeSolved = leetCodeSolved
        self.leetCodeSolvedToday = leetCodeSolvedToday
        self.gitHubCommitsToday = gitHubCommitsToday
        self.gitHubWeeklyCommits = gitHubWeeklyCommits
        self.gitHubStreak = gitHubStreak
        self.codingActivity = codingActivity
        self.portfolioRepositoryCount = portfolioRepositoryCount
        self.portfolioFeaturedProject = portfolioFeaturedProject
        self.portfolioActiveProject = portfolioActiveProject
        self.portfolioLatestCommit = portfolioLatestCommit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productiveHours = try container.decodeIfPresent(Double.self, forKey: .productiveHours) ?? 0
        distractingHours = try container.decodeIfPresent(Double.self, forKey: .distractingHours) ?? 0
        productivityScore = try container.decodeIfPresent(Double.self, forKey: .productivityScore) ?? 0
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "unknown"
        streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        goalProgress = try container.decodeIfPresent(Double.self, forKey: .goalProgress) ?? 0
        leetCodeStreak = try container.decodeIfPresent(Int.self, forKey: .leetCodeStreak) ?? 0
        leetCodeSolved = try container.decodeIfPresent(Int.self, forKey: .leetCodeSolved) ?? 0
        leetCodeSolvedToday = try container.decodeIfPresent(Int.self, forKey: .leetCodeSolvedToday) ?? 0
        gitHubCommitsToday = try container.decodeIfPresent(Int.self, forKey: .gitHubCommitsToday) ?? 0
        gitHubWeeklyCommits = try container.decodeIfPresent(Int.self, forKey: .gitHubWeeklyCommits) ?? 0
        gitHubStreak = try container.decodeIfPresent(Int.self, forKey: .gitHubStreak) ?? 0
        codingActivity = try container.decodeIfPresent([DronaCodingActivityDay].self, forKey: .codingActivity) ?? []
        portfolioRepositoryCount = try container.decodeIfPresent(Int.self, forKey: .portfolioRepositoryCount) ?? 0
        portfolioFeaturedProject = try container.decodeIfPresent(String.self, forKey: .portfolioFeaturedProject) ?? "None"
        portfolioActiveProject = try container.decodeIfPresent(String.self, forKey: .portfolioActiveProject) ?? "None"
        portfolioLatestCommit = try container.decodeIfPresent(String.self, forKey: .portfolioLatestCommit) ?? "No commits loaded"
    }
}

private struct DronaCodingActivityDay: Codable, Equatable {
    var date: Date
    var count: Int
}

private struct DronaWidgetEntry: TimelineEntry {
    let date: Date
    let summary: DronaWidgetSummary
    let style: SharedWidgetStyleModel
}

private struct DronaWidgetProvider: TimelineProvider {
    var kind: WidgetStyleKind

    func placeholder(in context: Context) -> DronaWidgetEntry {
        DronaWidgetEntry(date: Date(), summary: .placeholder, style: .defaultStyle(for: kind))
    }

    func getSnapshot(in context: Context, completion: @escaping (DronaWidgetEntry) -> Void) {
        completion(makeEntry(summary: loadSummary() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DronaWidgetEntry>) -> Void) {
        let entry = makeEntry(summary: loadSummary() ?? .empty)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(widgetRefreshInterval))))
    }

    private func makeEntry(summary: DronaWidgetSummary) -> DronaWidgetEntry {
        let configuration = loadStyleConfiguration()
        return DronaWidgetEntry(date: Date(), summary: summary, style: configuration.style(for: kind))
    }

    private func loadSummary() -> DronaWidgetSummary? {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: "widget_summary") else {
            return nil
        }
        return try? JSONDecoder().decode(DronaWidgetSummary.self, from: data)
    }

    private func loadStyleConfiguration() -> SharedWidgetStyleConfiguration {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: widgetStyleStorageKey),
              let configuration = try? JSONDecoder().decode(SharedWidgetStyleConfiguration.self, from: data) else {
            return .defaultConfiguration()
        }
        return configuration
    }
}

struct DronaProductivityWidget: Widget {
    let kind = "DronaProductivityWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DronaWidgetProvider(kind: .productivity)) { entry in
            ProductivityWidgetView(entry: entry)
        }
        .configurationDisplayName("Drona Productivity")
        .description("Focused time, distraction time, and today's score.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DronaStatusWidget: Widget {
    let kind = "DronaStatusWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DronaWidgetProvider(kind: .status)) { entry in
            StatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Drona Status")
        .description("A calm read on your current focus state.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DronaStreakWidget: Widget {
    let kind = "DronaStreakWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DronaWidgetProvider(kind: .streak)) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Drona Streak")
        .description("Current consistency streak and daily momentum.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DronaContributionWidget: Widget {
    let kind = "DronaContributionWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DronaWidgetProvider(kind: .contribution)) { entry in
            ContributionWidgetView(entry: entry)
        }
        .configurationDisplayName("Drona Contributions")
        .description("A compact focus heatmap for maintaining momentum.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct DronaGoalWidget: Widget {
    let kind = "DronaGoalWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DronaWidgetProvider(kind: .goal)) { entry in
            GoalWidgetView(entry: entry)
        }
        .configurationDisplayName("Drona Goal")
        .description("Daily goal progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DronaRestWidget: Widget {
    let kind = "DronaRestWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DronaWidgetProvider(kind: .rest)) { entry in
            RestWidgetView(entry: entry)
        }
        .configurationDisplayName("Drona Rest")
        .description("Recovery-focused context for sustainable productivity.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DronaPortfolioWidget: Widget {
    let kind = "DronaPortfolioWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DronaWidgetProvider(kind: .portfolio)) { entry in
            PortfolioWidgetView(entry: entry)
        }
        .configurationDisplayName("Drona Portfolio")
        .description("Featured project, active repository, and latest GitHub activity.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct ProductivityWidgetView: View {
    let entry: DronaWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        WidgetCard(entry: entry) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    WidgetHeader(kind: .productivity, style: entry.style)
                    Text(String(format: "%.0f%%", entry.summary.productivityScore))
                        .font(widgetFont(size: family == .systemSmall ? 36 : 44, style: entry.style))
                        .monospacedDigit()
                        .foregroundStyle(entry.style.primaryText.color)
                    Text("\(formatHours(entry.summary.productiveHours)) focused")
                        .font(widgetFont(size: 12, style: entry.style))
                        .foregroundStyle(entry.style.secondaryText.color)
                }
                Spacer(minLength: 4)
                ScoreRing(score: entry.summary.productivityScore, style: entry.style, lineWidth: 9)
                    .frame(width: family == .systemSmall ? 54 : 74, height: family == .systemSmall ? 54 : 74)
            }

            if family != .systemSmall {
                HStack(spacing: 10) {
                    PillMetric(label: "Deep", value: formatHours(entry.summary.productiveHours), style: entry.style)
                    PillMetric(label: "Drift", value: formatHours(entry.summary.distractingHours), style: entry.style)
                }
            }
        }
    }
}

private struct StatusWidgetView: View {
    let entry: DronaWidgetEntry
    var body: some View {
        WidgetCard(entry: entry) {
            WidgetHeader(kind: .status, style: entry.style)
            Spacer(minLength: 4)
            Text(entry.summary.status.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(widgetFont(size: 29, style: entry.style))
                .foregroundStyle(entry.style.primaryText.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(entry.summary.productivityScore >= 70 ? "Protect the current rhythm." : "Reset with one focused block.")
                .font(widgetFont(size: 12, style: entry.style))
                .foregroundStyle(entry.style.secondaryText.color)
                .lineLimit(2)
        }
    }
}

private struct StreakWidgetView: View {
    let entry: DronaWidgetEntry
    var body: some View {
        WidgetCard(entry: entry) {
            WidgetHeader(kind: .streak, style: entry.style)
            Spacer(minLength: 4)
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(max(entry.summary.leetCodeStreak, entry.summary.gitHubStreak, entry.summary.streak))")
                    .font(widgetFont(size: 48, style: entry.style))
                    .monospacedDigit()
                    .foregroundStyle(entry.style.primaryText.color)
                Text("days")
                    .font(widgetFont(size: 17, style: entry.style))
                    .foregroundStyle(entry.style.primaryText.color)
            }
            Text("LC \(entry.summary.leetCodeSolvedToday) today · GH \(entry.summary.gitHubCommitsToday) commits")
                .font(widgetFont(size: 12, style: entry.style))
                .foregroundStyle(entry.style.secondaryText.color)
        }
    }
}

private struct ContributionWidgetView: View {
    let entry: DronaWidgetEntry
    @Environment(\.widgetFamily) private var family

    private var columnCount: Int { family == .systemLarge ? 14 : 10 }
    private var cellSize: CGFloat { family == .systemLarge ? 14 : 12 }

    var body: some View {
        WidgetCard(entry: entry) {
            WidgetHeader(kind: .contribution, style: entry.style)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: entry.style.gridSpacing), count: columnCount), spacing: entry.style.gridSpacing) {
                ForEach(0..<gridCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: entry.style.cellRadius, style: .continuous)
                        .fill(color(for: index))
                        .frame(width: cellSize, height: cellSize)
                }
            }
            Spacer(minLength: 2)
            Text("LC \(entry.summary.leetCodeSolved) solved · GH \(entry.summary.gitHubWeeklyCommits) weekly commits")
                .font(widgetFont(size: 12, style: entry.style))
                .foregroundStyle(entry.style.secondaryText.color)
        }
    }

    private var gridCount: Int { family == .systemLarge ? 98 : 50 }

    private func color(for index: Int) -> Color {
        let activity = normalizedActivity
        guard index < activity.count else {
            return entry.style.gradientEnd.color
        }

        let count = activity[index]
        if count >= 4 { return entry.style.heatmapHigh.color }
        if count >= 2 { return entry.style.heatmapMedium.color }
        if count >= 1 { return entry.style.heatmapLow.color }
        return entry.style.gradientEnd.color
    }

    private var normalizedActivity: [Int] {
        let counts = entry.summary.codingActivity.suffix(gridCount).map(\.count)
        if counts.count >= gridCount {
            return counts
        }

        return Array(repeating: 0, count: gridCount - counts.count) + counts
    }
}

private struct GoalWidgetView: View {
    let entry: DronaWidgetEntry
    var body: some View {
        WidgetCard(entry: entry) {
            WidgetHeader(kind: .goal, style: entry.style)
            Spacer(minLength: 6)
            ProgressBar(progress: entry.summary.goalProgress, style: entry.style)
                .frame(height: 12)
            Text(entry.summary.goalProgress.formatted(.percent.precision(.fractionLength(0))))
                .font(widgetFont(size: 39, style: entry.style))
                .monospacedDigit()
                .foregroundStyle(entry.style.primaryText.color)
            Text("\(formatHours(entry.summary.productiveHours)) logged")
                .font(widgetFont(size: 12, style: entry.style))
                .foregroundStyle(entry.style.secondaryText.color)
        }
    }
}

private struct RestWidgetView: View {
    let entry: DronaWidgetEntry
    var body: some View {
        WidgetCard(entry: entry) {
            WidgetHeader(kind: .rest, style: entry.style)
            Spacer(minLength: 6)
            Text(entry.summary.productivityScore >= 75 ? "Good day. Stop clean." : "Reset without pressure.")
                .font(widgetFont(size: 25, style: entry.style))
                .foregroundStyle(entry.style.primaryText.color)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
            Text("Sustainable focus needs clean shutdowns.")
                .font(widgetFont(size: 12, style: entry.style))
                .foregroundStyle(entry.style.secondaryText.color)
        }
    }
}

private struct PortfolioWidgetView: View {
    let entry: DronaWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        WidgetCard(entry: entry) {
            WidgetHeader(kind: .portfolio, style: entry.style)
            Spacer(minLength: 4)
            Text(entry.summary.portfolioFeaturedProject)
                .font(widgetFont(size: family == .systemSmall ? 24 : 29, style: entry.style))
                .foregroundStyle(entry.style.primaryText.color)
                .lineLimit(2)
                .minimumScaleFactor(0.68)
            Text("\(entry.summary.portfolioRepositoryCount) repositories · streak \(max(entry.summary.gitHubStreak, entry.summary.leetCodeStreak))d")
                .font(widgetFont(size: 12, style: entry.style))
                .foregroundStyle(entry.style.secondaryText.color)
                .lineLimit(1)
            if family != .systemSmall {
                PillMetric(label: "Active", value: entry.summary.portfolioActiveProject, style: entry.style)
                Text(entry.summary.portfolioLatestCommit)
                    .font(widgetFont(size: 11, style: entry.style))
                    .foregroundStyle(entry.style.secondaryText.color)
                    .lineLimit(2)
            }
        }
    }
}

private struct WidgetCard<Content: View>: View {
    let entry: DronaWidgetEntry
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(entry.style.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay {
            RoundedRectangle(cornerRadius: entry.style.cornerRadius, style: .continuous)
                .stroke(entry.style.borderColor.color, lineWidth: entry.style.borderThickness)
        }
        .containerBackground(for: .widget) {
            backgroundGradient(for: entry.style)
        }
    }
}

private struct WidgetHeader: View {
    var kind: WidgetStyleKind
    var style: SharedWidgetStyleModel

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: kind.systemImage)
            Text(kind.title.uppercased())
                .tracking(0.8)
            Spacer(minLength: 0)
        }
        .font(widgetFont(size: 11, style: style))
        .foregroundStyle(style.secondaryText.color)
    }
}

private struct ScoreRing: View {
    var score: Double
    var style: SharedWidgetStyleModel
    var lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(style.gradientMiddle.color, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(score / 100, 0), 1))
                .stroke(style.primaryText.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

private struct PillMetric: View {
    var label: String
    var value: String
    var style: SharedWidgetStyleModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(widgetFont(size: 10, style: style))
                .foregroundStyle(style.secondaryText.color)
            Text(value)
                .font(widgetFont(size: 12, style: style))
                .monospacedDigit()
                .foregroundStyle(style.primaryText.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.accent.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ProgressBar: View {
    var progress: Double
    var style: SharedWidgetStyleModel

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(style.gradientMiddle.color)
                Capsule()
                    .fill(style.primaryText.color)
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
    }
}

private func backgroundGradient(for style: SharedWidgetStyleModel) -> LinearGradient {
    let colors: [Color]
    switch style.backgroundStyle {
    case .flat:
        colors = [style.gradientMiddle.color, style.gradientMiddle.color]
    case .minimalDark:
        colors = [Color(red: 0.08, green: 0.09, blue: 0.12), style.gradientEnd.color]
    case .glow, .neon:
        colors = [style.accent.color, style.gradientStart.color, style.gradientEnd.color]
    case .glass, .elegant, .gradient:
        colors = [style.gradientStart.color, style.gradientMiddle.color, style.gradientEnd.color]
    }

    return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
}

private func widgetFont(size: CGFloat, style: SharedWidgetStyleModel) -> Font {
    .system(size: size * style.fontScale, weight: fontWeight(style.fontWeight), design: fontDesign(style.typography))
}

private func fontWeight(_ option: WidgetFontWeightOption) -> Font.Weight {
    switch option {
    case .regular: return .regular
    case .medium: return .medium
    case .semibold: return .semibold
    case .bold: return .bold
    }
}

private func fontDesign(_ design: WidgetTypographyDesign) -> Font.Design {
    switch design {
    case .system: return .default
    case .rounded: return .rounded
    case .monospaced: return .monospaced
    }
}

private func formatHours(_ hours: Double) -> String {
    if hours < 1 { return "\(Int(hours * 60))m" }
    return String(format: "%.1fh", hours)
}

private extension SharedWidgetStyleConfiguration {
    static func defaultConfiguration() -> SharedWidgetStyleConfiguration {
        SharedWidgetStyleConfiguration(styles: WidgetStyleKind.allCases.map { .defaultStyle(for: $0) }, updatedAt: Date())
    }
}

private extension SharedWidgetStyleModel {
    static func defaultStyle(for kind: WidgetStyleKind) -> SharedWidgetStyleModel {
        SharedWidgetStyleModel(
            widgetKind: kind,
            backgroundStyle: .gradient,
            gradientStart: .init(red: 0, green: 0.58, blue: 0.38, alpha: 1),
            gradientMiddle: .init(red: 0, green: 0.44, blue: 0.72, alpha: 1),
            gradientEnd: .init(red: 0.05, green: 0.08, blue: 0.14, alpha: 1),
            gradientAngle: 135,
            primaryText: .white,
            secondaryText: .softWhite,
            accent: .init(red: 0.22, green: 0.38, blue: 0.34, alpha: 1),
            borderColor: .init(red: 1, green: 1, blue: 1, alpha: 1),
            cornerRadius: 22,
            borderThickness: 0,
            shadowIntensity: 0.35,
            glowIntensity: 0.25,
            padding: 16,
            fontScale: 1,
            fontWeight: .bold,
            typography: .rounded,
            heatmapLow: .init(red: 0.22, green: 0.38, blue: 0.34, alpha: 1),
            heatmapMedium: .init(red: 0.24, green: 0.78, blue: 0.56, alpha: 1),
            heatmapHigh: .init(red: 0.80, green: 1, blue: 0.88, alpha: 1),
            restDayColor: kind == .portfolio ? .init(red: 0.88, green: 0.78, blue: 1, alpha: 1) : .init(red: 0.48, green: 0.68, blue: 1, alpha: 1),
            gridSpacing: 5,
            cellRadius: 3,
            animationsEnabled: true,
            hoverGlowEnabled: true,
            pulseEffectsEnabled: false
        )
    }
}

private extension DronaWidgetSummary {
    static let placeholder = DronaWidgetSummary(productiveHours: 4.2, distractingHours: 1.0, productivityScore: 81, status: "winning", streak: 5, goalProgress: 0.72, leetCodeStreak: 3, leetCodeSolved: 42, leetCodeSolvedToday: 2, gitHubCommitsToday: 4, gitHubWeeklyCommits: 18, gitHubStreak: 5, codingActivity: placeholderActivity, portfolioRepositoryCount: 12, portfolioFeaturedProject: "Drona", portfolioActiveProject: "binance-bot", portfolioLatestCommit: "Refine portfolio dashboard")
    static let empty = DronaWidgetSummary(productiveHours: 0, distractingHours: 0, productivityScore: 0, status: "unknown", streak: 0, goalProgress: 0)

    private static var placeholderActivity: [DronaCodingActivityDay] {
        (0..<98).compactMap { offset in
            guard let date = Calendar.current.date(byAdding: .day, value: offset - 97, to: Date()) else {
                return nil
            }
            return DronaCodingActivityDay(date: date, count: offset % 5)
        }
    }
}
