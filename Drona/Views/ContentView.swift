import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var tracker = ActivityTracker()
    @StateObject private var learningTracker = LearningTracker()
    @StateObject private var portfolioManager = PortfolioManager()
    @StateObject private var startupManager = StartupManager()
    @StateObject private var loggingManager = LoggingManager.shared
    @StateObject private var performanceManager: PerformanceManager
    @StateObject private var recoveryManager: RecoveryManager
    @StateObject private var healthManager: SystemHealthManager
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var onboardingManager = OnboardingManager.shared
    @SceneStorage("selectedAnalysisSection") private var selectedSectionRaw = AnalysisSection.overview.rawValue

    private let analyticsEngine = AnalyticsEngine()
    private let learningAnalyticsEngine = LearningAnalyticsEngine()
    private let behaviorAnalyzer = BehaviorAnalyzer()

    init() {
        let performanceManager = PerformanceManager()
        let recoveryManager = RecoveryManager()
        _performanceManager = StateObject(wrappedValue: performanceManager)
        _recoveryManager = StateObject(wrappedValue: recoveryManager)
        _healthManager = StateObject(wrappedValue: SystemHealthManager(performanceManager: performanceManager, recoveryManager: recoveryManager))
    }

    var body: some View {
        Group {
            if onboardingManager.hasCompletedOnboarding {
                appShell
            } else {
                OnboardingView(settingsManager: settingsManager) {
                    onboardingManager.complete()
                    tracker.ruleEngine.goalManager.productiveGoalHours = settingsManager.settings.productiveGoalHours
                }
            }
        }
        .onAppear {
            tracker.ruleEngine.goalManager.productiveGoalHours = settingsManager.settings.productiveGoalHours
            recoveryManager.markRunning()
            healthManager.startMonitoring(tracker: tracker)
        }
        .task {
            await learningTracker.runAutomaticRefresh(productiveHoursThisWeek: productiveHoursThisWeek)
        }
        .task {
            await portfolioManager.runAutomaticSync()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                tracker.flushData(reason: "App entered background")
                recoveryManager.markRunning()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            tracker.flushData(reason: "Application terminating")
            recoveryManager.markCleanShutdown()
            healthManager.stopMonitoring()
        }
    }

    private var appShell: some View {
        NavigationSplitView {
            List(selection: selectionBinding) {
                Section("Analysis") {
                    ForEach(AnalysisSection.analysisCases) { section in
                        Label(section.title, systemImage: section.systemImage)
                            .tag(section)
                    }
                }

                Section("Learning") {
                    ForEach(AnalysisSection.learningCases) { section in
                        Label(section.title, systemImage: section.systemImage)
                            .tag(section)
                    }
                }

                Section("Portfolio") {
                    ForEach(AnalysisSection.portfolioCases) { section in
                        Label(section.title, systemImage: section.systemImage)
                            .tag(section)
                    }
                }

                Section("Intelligence") {
                    ForEach(AnalysisSection.intelligenceCases) { section in
                        Label(section.title, systemImage: section.systemImage)
                            .tag(section)
                    }
                }

                Section("System") {
                    ForEach(AnalysisSection.systemCases) { section in
                        Label(section.title, systemImage: section.systemImage)
                            .tag(section)
                    }
                }
            }
            .navigationTitle("Drona")
        } detail: {
            sectionView(selectionBinding.wrappedValue)
        }
        .frame(minWidth: 1100, minHeight: 720)
        .dronaPageBackground()
    }

    private var snapshot: AnalyticsSnapshot {
        analyticsEngine.makeSnapshot(
            metrics: tracker.ruleEngine.metrics,
            summaries: tracker.ruleEngine.historyManager.summaries,
            apps: tracker.trackedApps,
            violations: tracker.focusMonitor.logger.violations,
            goalHours: tracker.ruleEngine.goalManager.productiveGoalHours
        )
    }

    private var learningSnapshot: LearningSnapshot {
        learningAnalyticsEngine.makeSnapshot(
            leetCodeStats: learningTracker.leetCodeStats,
            leetCodeRecords: learningTracker.leetCodeRecords,
            sessions: learningTracker.sessions,
            achievements: learningTracker.achievements,
            productivityTrends: snapshot.trends
        )
    }

    private var behaviorSnapshot: BehaviorSnapshot {
        behaviorAnalyzer.analyze(
            productivity: snapshot,
            learning: learningSnapshot,
            violations: tracker.focusMonitor.logger.violations
        )
    }

    private var productiveHoursThisWeek: Double {
        Array(snapshot.trends.suffix(7)).reduce(0) { $0 + $1.productiveHours }
    }

    private var selectionBinding: Binding<AnalysisSection> {
        Binding {
            AnalysisSection(rawValue: selectedSectionRaw) ?? .overview
        } set: { newValue in
            selectedSectionRaw = newValue.rawValue
        }
    }

    @ViewBuilder
    private func sectionView(_ section: AnalysisSection) -> some View {
        switch section {
        case .overview:
            DashboardView(snapshot: snapshot)
        case .contributionGraph:
            ContributionGraphView(days: snapshot.contributionDays)
        case .analytics:
            AnalyticsView(snapshot: snapshot)
        case .violations:
            ViolationsView(analytics: snapshot.violations)
        case .restAnalysis:
            RestAnalysisView(analytics: snapshot.rest)
        case .boostAnalysis:
            BoostAnalysisView(analytics: snapshot.boost)
        case .sessionTimeline:
            SessionTimelineView(blocks: snapshot.sessionTimeline)
        case .learning:
            LearningView(learningTracker: learningTracker, snapshot: learningSnapshot)
        case .leetCode:
            LeetCodeView(
                learningTracker: learningTracker,
                analytics: learningSnapshot.leetCode,
                productiveHoursThisWeek: productiveHoursThisWeek
            )
        case .projects:
            ProjectsView(
                learningTracker: learningTracker,
                analytics: learningSnapshot.projects,
                currentProductivityScore: snapshot.today.productivityScore
            )
        case .portfolioProjects, .gitHubShowcase:
            GitHubPortfolioView(portfolioManager: portfolioManager)
        case .achievements:
            AchievementsView(achievements: learningSnapshot.achievements)
        case .learningTimeline:
            LearningTimelineView(events: learningSnapshot.timeline)
        case .insights:
            InsightsView(behavior: behaviorSnapshot)
        case .patterns:
            PatternsView(behavior: behaviorSnapshot)
        case .focusAnalysis:
            FocusAnalysisView(behavior: behaviorSnapshot)
        case .efficiency:
            EfficiencyView(behavior: behaviorSnapshot, learning: learningSnapshot)
        case .behaviorTrends:
            BehaviorTrendsView(behavior: behaviorSnapshot)
        case .systemHealth:
            SystemHealthView(
                healthManager: healthManager,
                startupManager: startupManager,
                loggingManager: loggingManager,
                tracker: tracker
            )
        case .widgetStudio:
            WidgetCustomizationView()
        case .settings:
            SettingsView(
                goalManager: tracker.ruleEngine.goalManager,
                startupManager: startupManager,
                tracker: tracker
            )
        }
    }
}

private enum AnalysisSection: String, CaseIterable, Identifiable {
    case overview
    case contributionGraph
    case analytics
    case violations
    case restAnalysis
    case boostAnalysis
    case sessionTimeline
    case learning
    case leetCode
    case projects
    case portfolioProjects
    case gitHubShowcase
    case achievements
    case learningTimeline
    case insights
    case patterns
    case focusAnalysis
    case efficiency
    case behaviorTrends
    case systemHealth
    case widgetStudio
    case settings

    static var analysisCases: [AnalysisSection] {
        [.overview, .contributionGraph, .analytics, .violations, .restAnalysis, .boostAnalysis, .sessionTimeline]
    }

    static var learningCases: [AnalysisSection] {
        [.learning, .leetCode, .projects, .achievements, .learningTimeline]
    }

    static var portfolioCases: [AnalysisSection] {
        [.portfolioProjects, .gitHubShowcase]
    }

    static var intelligenceCases: [AnalysisSection] {
        [.insights, .patterns, .focusAnalysis, .efficiency, .behaviorTrends]
    }

    static var systemCases: [AnalysisSection] {
        [.systemHealth, .widgetStudio, .settings]
    }

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .overview:
            return "Overview"
        case .contributionGraph:
            return "Contribution Graph"
        case .analytics:
            return "Analytics"
        case .violations:
            return "Violations"
        case .restAnalysis:
            return "Rest Analysis"
        case .boostAnalysis:
            return "Boost Analysis"
        case .sessionTimeline:
            return "Session Timeline"
        case .learning:
            return "Learning"
        case .leetCode:
            return "LeetCode"
        case .projects:
            return "Projects"
        case .portfolioProjects:
            return "Projects"
        case .gitHubShowcase:
            return "GitHub Showcase"
        case .achievements:
            return "Achievements"
        case .learningTimeline:
            return "Learning Timeline"
        case .insights:
            return "Insights"
        case .patterns:
            return "Patterns"
        case .focusAnalysis:
            return "Focus Analysis"
        case .efficiency:
            return "Efficiency"
        case .behaviorTrends:
            return "Behavior Trends"
        case .systemHealth:
            return "System Health"
        case .widgetStudio:
            return "Widget Studio"
        case .settings:
            return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .overview:
            return "gauge.with.dots.needle.67percent"
        case .contributionGraph:
            return "square.grid.3x3.fill"
        case .analytics:
            return "chart.xyaxis.line"
        case .violations:
            return "exclamationmark.triangle"
        case .restAnalysis:
            return "moon"
        case .boostAnalysis:
            return "bolt"
        case .sessionTimeline:
            return "timeline.selection"
        case .learning:
            return "brain.head.profile"
        case .leetCode:
            return "checkmark.seal"
        case .projects:
            return "folder.badge.gearshape"
        case .portfolioProjects:
            return "rectangle.stack.badge.person.crop"
        case .gitHubShowcase:
            return "sparkles.rectangle.stack"
        case .achievements:
            return "medal"
        case .learningTimeline:
            return "list.bullet.rectangle"
        case .insights:
            return "sparkle.magnifyingglass"
        case .patterns:
            return "point.3.connected.trianglepath.dotted"
        case .focusAnalysis:
            return "scope"
        case .efficiency:
            return "speedometer"
        case .behaviorTrends:
            return "chart.line.uptrend.xyaxis"
        case .systemHealth:
            return "heart.text.square"
        case .widgetStudio:
            return "paintpalette"
        case .settings:
            return "slider.horizontal.3"
        }
    }
}

#Preview {
    ContentView()
}
