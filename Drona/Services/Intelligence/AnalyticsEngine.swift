import Foundation

struct AnalyticsSnapshot {
    var today: TodayAnalytics
    var trends: [DailyTrendPoint]
    var contributionDays: [ContributionDay]
    var monthRankings: [MonthPerformance]
    var appBreakdown: [AppBreakdownItem]
    var violations: ViolationAnalytics
    var rest: RestAnalytics
    var boost: BoostAnalytics
    var sessionTimeline: [SessionTimelineBlock]
    var insightContext: PreparedInsightContext
}

struct TodayAnalytics {
    var productiveHours: Double
    var distractingHours: Double
    var neutralHours: Double
    var productivityScore: Double
    var status: String
    var goalCompletion: Double
    var streak: Int
}

struct DailyTrendPoint: Identifiable {
    let id = UUID()
    var date: Date
    var productiveHours: Double
    var distractingHours: Double
    var productivityScore: Double
    var goalCompletion: Double
    var violations: Int
}

struct ContributionDay: Identifiable {
    let id = UUID()
    var date: Date
    var productiveHours: Double
    var distractingHours: Double
    var violations: Int
    var status: String
    var isRestDay: Bool

    var intensity: Int {
        if isRestDay {
            return -1
        }

        switch productiveHours {
        case ..<0.25:
            return 0
        case ..<2:
            return 1
        case ..<4:
            return 2
        default:
            return 3
        }
    }
}

struct MonthPerformance: Identifiable {
    let id = UUID()
    var monthStart: Date
    var label: String
    var productiveHours: Double
    var consistency: Double
    var goalCompletion: Double
    var violations: Int
    var learningScore: Double
    var rankScore: Double
    var deltaFromPrevious: Double?
}

struct AppBreakdownItem: Identifiable {
    let id = UUID()
    var appName: String
    var category: ProductivityCategory
    var hours: Double
    var share: Double
}

struct ViolationTarget: Identifiable {
    let id = UUID()
    var name: String
    var attempts: Int
}

struct ViolationAnalytics {
    var totalAttempts: Int
    var mostAttempted: [ViolationTarget]
    var frequency: [DailyTrendPoint]
}

struct RestClassificationCount: Identifiable {
    let id = UUID()
    var classification: String
    var count: Int
}

struct RestAnalytics {
    var totalRestDays: Int
    var classifications: [RestClassificationCount]
    var restDays: [ContributionDay]
}

struct BoostAnalytics {
    var boostDays: Int
    var averageBoostScore: Double
    var averageGoalCompletion: Double
    var productivitySpikes: [DailyTrendPoint]
}

struct SessionTimelineBlock: Identifiable {
    let id = UUID()
    var startHour: Int
    var endHour: Int
    var label: String
    var category: ProductivityCategory
    var durationHours: Double
}

struct PreparedInsightContext {
    var status: String
    var bestMonth: String
    var weakestTargets: [String]
    var restClassifications: [String: Int]
    var averageScore: Double
}

final class AnalyticsEngine {
    private let calendar = Calendar.current
    private let classifier = ProductivityClassifier()

    func makeSnapshot(
        metrics: DailyMetrics,
        summaries: [DailySummary],
        apps: [AppUsage],
        violations: [ViolationEvent],
        goalHours: Double
    ) -> AnalyticsSnapshot {
        let sortedSummaries = summaries.sorted { $0.date < $1.date }
        let trends = makeTrends(from: sortedSummaries, violations: violations, goalHours: goalHours)
        let contributionDays = makeContributionDays(from: sortedSummaries)
        let months = makeMonthRankings(from: sortedSummaries, goalHours: goalHours)
        let appBreakdown = makeAppBreakdown(from: apps)
        let violationAnalytics = makeViolationAnalytics(from: violations)
        let restAnalytics = makeRestAnalytics(from: contributionDays)
        let boostAnalytics = makeBoostAnalytics(from: trends, summaries: sortedSummaries)
        let today = makeToday(metrics: metrics, summaries: sortedSummaries, goalHours: goalHours)
        let timeline = makeSessionTimeline(from: metrics)
        let insightContext = makeInsightContext(
            today: today,
            months: months,
            violations: violationAnalytics,
            rest: restAnalytics,
            trends: trends
        )

        return AnalyticsSnapshot(
            today: today,
            trends: trends,
            contributionDays: contributionDays,
            monthRankings: months,
            appBreakdown: appBreakdown,
            violations: violationAnalytics,
            rest: restAnalytics,
            boost: boostAnalytics,
            sessionTimeline: timeline,
            insightContext: insightContext
        )
    }

    private func makeToday(metrics: DailyMetrics, summaries: [DailySummary], goalHours: Double) -> TodayAnalytics {
        let goalSeconds = max(goalHours * 3600, 1)

        return TodayAnalytics(
            productiveHours: metrics.productiveTime / 3600,
            distractingHours: metrics.distractingTime / 3600,
            neutralHours: metrics.neutralTime / 3600,
            productivityScore: metrics.productivityScore,
            status: metrics.status.rawValue.uppercased(),
            goalCompletion: min(metrics.productiveTime / goalSeconds, 1),
            streak: currentStreak(from: summaries)
        )
    }

    private func makeTrends(
        from summaries: [DailySummary],
        violations: [ViolationEvent],
        goalHours: Double
    ) -> [DailyTrendPoint] {
        let goalSeconds = max(goalHours * 3600, 1)
        let violationCounts = Dictionary(grouping: violations) { event in
            calendar.startOfDay(for: event.timestamp)
        }.mapValues { $0.count }

        return summaries.suffix(90).map { summary in
            let day = calendar.startOfDay(for: summary.date)
            let completion = summary.goalCompletion > 0
                ? min(summary.goalCompletion, 1)
                : min(summary.productiveTime / goalSeconds, 1)

            return DailyTrendPoint(
                date: day,
                productiveHours: summary.productiveTime / 3600,
                distractingHours: summary.distractingTime / 3600,
                productivityScore: summary.productivityScore,
                goalCompletion: completion,
                violations: summary.violationsCount + (violationCounts[day] ?? 0)
            )
        }
    }

    private func makeContributionDays(from summaries: [DailySummary]) -> [ContributionDay] {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -181, to: today) ?? today
        let byDay = Dictionary(grouping: summaries) { summary in
            calendar.startOfDay(for: summary.date)
        }

        return (0...181).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }

            let summary = byDay[date]?.last
            return ContributionDay(
                date: date,
                productiveHours: (summary?.productiveTime ?? 0) / 3600,
                distractingHours: (summary?.distractingTime ?? 0) / 3600,
                violations: summary?.violationsCount ?? 0,
                status: summary?.status ?? "No Work",
                isRestDay: summary?.restModeEnabled ?? false
            )
        }
    }

    private func makeMonthRankings(from summaries: [DailySummary], goalHours: Double) -> [MonthPerformance] {
        let grouped = Dictionary(grouping: summaries) { summary in
            let components = calendar.dateComponents([.year, .month], from: summary.date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: summary.date)
        }

        let ranked = grouped.map { monthStart, items in
            let activeDays = items.filter { $0.productiveTime > 0 || $0.distractingTime > 0 }
            let productiveHours = items.reduce(0) { $0 + $1.productiveTime } / 3600
            let consistency = Double(activeDays.count) / Double(max(daysInMonth(monthStart), 1))
            let goalCompletion = average(items.map { summary in
                summary.goalCompletion > 0 ? summary.goalCompletion : min((summary.productiveTime / 3600) / max(goalHours, 1), 1)
            })
            let violations = items.reduce(0) { $0 + $1.violationsCount }
            let score = average(items.map(\.productivityScore))
            let learningScore = min((score * 0.55) + (goalCompletion * 100 * 0.30) + (consistency * 100 * 0.15), 100)
            let rankScore = max(learningScore - Double(violations) * 0.8, 0)

            return MonthPerformance(
                monthStart: monthStart,
                label: monthFormatter.string(from: monthStart),
                productiveHours: productiveHours,
                consistency: consistency,
                goalCompletion: goalCompletion,
                violations: violations,
                learningScore: learningScore,
                rankScore: rankScore,
                deltaFromPrevious: nil
            )
        }
        .sorted { $0.monthStart < $1.monthStart }

        var withDeltas: [MonthPerformance] = []
        for item in ranked {
            var updated = item
            if let previous = withDeltas.last {
                updated.deltaFromPrevious = updated.rankScore - previous.rankScore
            }
            withDeltas.append(updated)
        }

        return withDeltas.sorted { $0.rankScore > $1.rankScore }
    }

    private func makeAppBreakdown(from apps: [AppUsage]) -> [AppBreakdownItem] {
        let total = max(apps.reduce(0) { $0 + $1.totalTime }, 1)

        return apps
            .sorted { $0.totalTime > $1.totalTime }
            .prefix(12)
            .map { app in
                AppBreakdownItem(
                    appName: app.appName,
                    category: classifier.classify(appName: app.appName),
                    hours: app.totalTime / 3600,
                    share: app.totalTime / total
                )
            }
    }

    private func makeViolationAnalytics(from violations: [ViolationEvent]) -> ViolationAnalytics {
        let targets = Dictionary(grouping: violations, by: \.appName)
            .map { ViolationTarget(name: $0.key, attempts: $0.value.count) }
            .sorted { $0.attempts > $1.attempts }

        let frequency = Dictionary(grouping: violations) { event in
            calendar.startOfDay(for: event.timestamp)
        }
        .map { day, events in
            DailyTrendPoint(
                date: day,
                productiveHours: 0,
                distractingHours: 0,
                productivityScore: 0,
                goalCompletion: 0,
                violations: events.count
            )
        }
        .sorted { $0.date < $1.date }

        return ViolationAnalytics(
            totalAttempts: violations.count,
            mostAttempted: Array(targets.prefix(8)),
            frequency: frequency
        )
    }

    private func makeRestAnalytics(from days: [ContributionDay]) -> RestAnalytics {
        let restDays = days.filter(\.isRestDay)
        let classifications = Dictionary(grouping: restDays) { day in
            classifyRestDay(day)
        }
        .map { RestClassificationCount(classification: $0.key, count: $0.value.count) }
        .sorted { $0.count > $1.count }

        return RestAnalytics(
            totalRestDays: restDays.count,
            classifications: classifications,
            restDays: restDays
        )
    }

    private func makeBoostAnalytics(from trends: [DailyTrendPoint], summaries: [DailySummary]) -> BoostAnalytics {
        let boostSummaries = summaries.filter(\.boostModeEnabled)
        let boostDays = Set(boostSummaries.map { calendar.startOfDay(for: $0.date) })
        let spikes = trends.filter { point in
            point.productivityScore >= 85 || boostDays.contains(calendar.startOfDay(for: point.date))
        }

        return BoostAnalytics(
            boostDays: boostDays.count,
            averageBoostScore: average(spikes.map(\.productivityScore)),
            averageGoalCompletion: average(spikes.map(\.goalCompletion)),
            productivitySpikes: spikes.suffix(14)
        )
    }

    private func makeSessionTimeline(from metrics: DailyMetrics) -> [SessionTimelineBlock] {
        let productiveHours = metrics.productiveTime / 3600
        let neutralHours = metrics.neutralTime / 3600
        let distractingHours = metrics.distractingTime / 3600

        return [
            SessionTimelineBlock(startHour: 9, endHour: 12, label: "Productive", category: .productive, durationHours: productiveHours),
            SessionTimelineBlock(startHour: 12, endHour: 13, label: "Neutral", category: .neutral, durationHours: neutralHours),
            SessionTimelineBlock(startHour: 14, endHour: 17, label: "Distracting", category: .distracting, durationHours: distractingHours)
        ].filter { $0.durationHours > 0 }
    }

    private func makeInsightContext(
        today: TodayAnalytics,
        months: [MonthPerformance],
        violations: ViolationAnalytics,
        rest: RestAnalytics,
        trends: [DailyTrendPoint]
    ) -> PreparedInsightContext {
        PreparedInsightContext(
            status: today.status,
            bestMonth: months.first?.label ?? "No month ranked",
            weakestTargets: violations.mostAttempted.prefix(3).map(\.name),
            restClassifications: Dictionary(uniqueKeysWithValues: rest.classifications.map { ($0.classification, $0.count) }),
            averageScore: average(trends.map(\.productivityScore))
        )
    }

    private func currentStreak(from summaries: [DailySummary]) -> Int {
        summaries.sorted { $0.date > $1.date }.prefix { $0.productivityScore >= 70 }.count
    }

    private func classifyRestDay(_ day: ContributionDay) -> String {
        if day.productiveHours < 0.5 && day.distractingHours < 0.5 {
            return "True Rest"
        }

        if day.productiveHours >= day.distractingHours {
            return "Active Rest"
        }

        return "Fake Rest"
    }

    private func daysInMonth(_ date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else {
            return 0
        }

        return values.reduce(0, +) / Double(values.count)
    }

    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }
}
