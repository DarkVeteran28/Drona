import Foundation

final class BehaviorAnalyzer {
    private let calendar = Calendar.current
    private let trendEngine = TrendEngine()
    private let efficiencyAnalyzer = EfficiencyAnalyzer()
    private let insightGenerator = InsightGenerator()

    func analyze(
        productivity: AnalyticsSnapshot,
        learning: LearningSnapshot,
        violations: [ViolationEvent]
    ) -> BehaviorSnapshot {
        let hourlyProductivity = makeHourlyProductivity(from: productivity.sessionTimeline)
        let distractionHeatmap = makeDistractionHeatmap(from: violations)
        let focus = makeFocusAnalysis(from: productivity.trends)
        let distraction = makeDistractionAnalysis(from: productivity.violations, violations: violations)
        let rest = makeRestAnalysis(days: productivity.contributionDays, trends: productivity.trends)
        let boost = makeBoostAnalysis(trends: productivity.trends, boost: productivity.boost)
        let consistencyPoints = trendEngine.consistencyPoints(from: productivity.trends)
        let consistency = makeConsistencyAnalysis(points: consistencyPoints)
        let efficiency = efficiencyAnalyzer.analyze(output: learning.outputEfficiency)
        let trend = trendEngine.analyze(trends: productivity.trends)
        let focusDistribution = makeFocusDistribution(from: productivity.trends)
        let patterns = makePatterns(
            hourlyProductivity: hourlyProductivity,
            distraction: distraction,
            focus: focus,
            rest: rest,
            boost: boost,
            consistency: consistency,
            efficiency: efficiency,
            trend: trend
        )

        var snapshot = BehaviorSnapshot(
            insights: [],
            hourlyProductivity: hourlyProductivity,
            distractionHeatmap: distractionHeatmap,
            focusDistribution: focusDistribution,
            weeklyConsistency: consistencyPoints,
            patterns: patterns,
            focus: focus,
            distraction: distraction,
            rest: rest,
            boost: boost,
            consistency: consistency,
            efficiency: efficiency,
            trend: trend
        )
        snapshot.insights = insightGenerator.generate(snapshot: snapshot)
        return snapshot
    }

    private func makeHourlyProductivity(from blocks: [SessionTimelineBlock]) -> [HourlyBehaviorPoint] {
        var points = (0..<24).map { hour in
            HourlyBehaviorPoint(hour: hour, score: 0, productiveHours: 0, distractionAttempts: 0)
        }

        for block in blocks {
            let hourRange = max(block.startHour, 0)..<min(block.endHour, 24)
            for hour in hourRange {
                let score: Double
                switch block.category {
                case .productive:
                    score = 90
                case .neutral:
                    score = 50
                case .distracting:
                    score = 20
                }

                points[hour] = HourlyBehaviorPoint(
                    hour: hour,
                    score: max(points[hour].score, score),
                    productiveHours: points[hour].productiveHours + (block.category == .productive ? block.durationHours / Double(max(hourRange.count, 1)) : 0),
                    distractionAttempts: points[hour].distractionAttempts
                )
            }
        }

        return points
    }

    private func makeDistractionHeatmap(from violations: [ViolationEvent]) -> [HourlyBehaviorPoint] {
        let grouped = Dictionary(grouping: violations) { event in
            calendar.component(.hour, from: event.timestamp)
        }

        return (0..<24).map { hour in
            HourlyBehaviorPoint(
                hour: hour,
                score: Double(grouped[hour]?.count ?? 0),
                productiveHours: 0,
                distractionAttempts: grouped[hour]?.count ?? 0
            )
        }
    }

    private func makeFocusAnalysis(from trends: [DailyTrendPoint]) -> FocusAnalysis {
        let deepWorkDays = trends.filter { $0.productiveHours >= 4 }
        let byWeekday = Dictionary(grouping: trends) { point in
            calendar.component(.weekday, from: point.date)
        }
        let best = byWeekday
            .map { (weekday: $0.key, score: $0.value.map(\.productivityScore).average) }
            .max { $0.score < $1.score }

        return FocusAnalysis(
            averageDeepWorkHours: deepWorkDays.map(\.productiveHours).average,
            deepWorkDays: deepWorkDays.count,
            bestDayOfWeek: weekdayName(best?.weekday ?? 1),
            bestDayScore: best?.score ?? 0
        )
    }

    private func makeDistractionAnalysis(
        from analytics: ViolationAnalytics,
        violations: [ViolationEvent]
    ) -> DistractionPatternAnalysis {
        let hourly = makeDistractionHeatmap(from: violations)
        let highestRisk = hourly.max { $0.distractionAttempts < $1.distractionAttempts }
        let firstHalf = analytics.frequency.prefix(max(analytics.frequency.count / 2, 1)).map { Double($0.violations) }.average
        let secondHalf = analytics.frequency.suffix(max(analytics.frequency.count / 2, 1)).map { Double($0.violations) }.average
        let top = analytics.mostAttempted.first

        return DistractionPatternAnalysis(
            mostTemptingTarget: top?.name ?? "No target recorded",
            mostTemptingAttempts: top?.attempts ?? 0,
            highestRiskHour: (highestRisk?.distractionAttempts ?? 0) > 0 ? highestRisk?.hour : nil,
            escalationRate: firstHalf == 0 ? secondHalf : ((secondHalf - firstHalf) / firstHalf) * 100
        )
    }

    private func makeRestAnalysis(days: [ContributionDay], trends: [DailyTrendPoint]) -> RestBehaviorAnalysis {
        let restDays = Set(days.filter(\.isRestDay).map { calendar.startOfDay(for: $0.date) })
        let trendByDay = Dictionary(uniqueKeysWithValues: trends.map { (calendar.startOfDay(for: $0.date), $0) })
        let postRestScores = restDays.compactMap { restDay -> Double? in
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: restDay) else {
                return nil
            }
            return trendByDay[nextDay]?.productivityScore
        }
        let nonRestScores = trends
            .filter { !restDays.contains(calendar.startOfDay(for: $0.date)) }
            .map(\.productivityScore)
        let recentLowScoreDays = trends.suffix(7).filter { $0.productivityScore < 50 }.count
        let recentHighDistractionDays = trends.suffix(7).filter { $0.distractingHours > $0.productiveHours }.count

        return RestBehaviorAnalysis(
            restDayCount: restDays.count,
            averagePostRestScore: postRestScores.average,
            averageNonRestScore: nonRestScores.average,
            burnoutRisk: min(Double(recentLowScoreDays + recentHighDistractionDays) / 7 * 100, 100)
        )
    }

    private func makeBoostAnalysis(trends: [DailyTrendPoint], boost: BoostAnalytics) -> BoostEffectivenessAnalysis {
        let baseline = trends.filter { $0.productivityScore < 85 }.map(\.productivityScore).average
        let boostScore = boost.averageBoostScore
        let lift = boost.boostDays == 0 ? 0 : boostScore - baseline
        let sustainability = max(0, min(100, (boost.averageGoalCompletion * 70) + max(0, 30 - abs(lift) * 0.4)))

        return BoostEffectivenessAnalysis(
            boostDays: boost.boostDays,
            boostScoreLift: lift,
            sustainabilityScore: sustainability
        )
    }

    private func makeConsistencyAnalysis(points: [ConsistencyPoint]) -> ConsistencyAnalysis {
        ConsistencyAnalysis(
            score: points.map(\.consistencyScore).average,
            volatility: points.map(\.volatility).average,
            goalCompletionRate: points.map(\.goalCompletion).average,
            stableWeeks: points.filter { $0.consistencyScore >= 70 }.count
        )
    }

    private func makeFocusDistribution(from trends: [DailyTrendPoint]) -> [FocusSessionBucket] {
        let short = trends.filter { $0.productiveHours > 0 && $0.productiveHours < 2 }
        let medium = trends.filter { $0.productiveHours >= 2 && $0.productiveHours < 4 }
        let deep = trends.filter { $0.productiveHours >= 4 }

        return [
            FocusSessionBucket(label: "Short", sessionCount: short.count, averageScore: short.map(\.productivityScore).average),
            FocusSessionBucket(label: "Focused", sessionCount: medium.count, averageScore: medium.map(\.productivityScore).average),
            FocusSessionBucket(label: "Deep Work", sessionCount: deep.count, averageScore: deep.map(\.productivityScore).average)
        ]
    }

    private func makePatterns(
        hourlyProductivity: [HourlyBehaviorPoint],
        distraction: DistractionPatternAnalysis,
        focus: FocusAnalysis,
        rest: RestBehaviorAnalysis,
        boost: BoostEffectivenessAnalysis,
        consistency: ConsistencyAnalysis,
        efficiency: EfficiencyAnalysis,
        trend: BehaviorTrendAnalysis
    ) -> [BehaviorPattern] {
        let peak = hourlyProductivity.max { $0.score < $1.score }

        return [
            BehaviorPattern(title: "Peak Productivity", value: peak?.score == 0 ? "Needs data" : formatHour(peak?.hour ?? 0), detail: "Strongest current productivity hour signal.", category: .productivity),
            BehaviorPattern(title: "Highest Distraction Risk", value: distraction.highestRiskHour.map(formatHour) ?? "Needs data", detail: "Based on logged violation timestamps.", category: .distraction),
            BehaviorPattern(title: "Average Deep Work", value: formatHours(focus.averageDeepWorkHours), detail: "Average productive time on days above four hours.", category: .productivity),
            BehaviorPattern(title: "Best Day", value: focus.bestDayOfWeek, detail: String(format: "Average score %.0f%%", focus.bestDayScore), category: .trend),
            BehaviorPattern(title: "Burnout Risk", value: String(format: "%.0f%%", rest.burnoutRisk), detail: "Recent low-score and high-distraction signal.", category: .recovery),
            BehaviorPattern(title: "Boost Lift", value: String(format: "%.0f pts", boost.boostScoreLift), detail: "Boost score compared with baseline days.", category: .boost),
            BehaviorPattern(title: "Consistency", value: String(format: "%.0f%%", consistency.score), detail: "Stability across weekly score and goal data.", category: .consistency),
            BehaviorPattern(title: "Efficiency", value: String(format: "%.2f/hr", efficiency.outputPerHour), detail: "Learning outputs per productive/session hour.", category: .efficiency),
            BehaviorPattern(title: "Trend", value: trend.direction.rawValue, detail: String(format: "Recent change %.0f%%", trend.changePercent), category: .trend)
        ]
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = calendar.weekdaySymbols
        let index = max(0, min(weekday - 1, symbols.count - 1))
        return symbols[index]
    }

    private func formatHour(_ hour: Int) -> String {
        let normalized = hour % 24
        if normalized == 0 { return "12am" }
        if normalized < 12 { return "\(normalized)am" }
        if normalized == 12 { return "12pm" }
        return "\(normalized - 12)pm"
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }

        return String(format: "%.1fh", hours)
    }
}
