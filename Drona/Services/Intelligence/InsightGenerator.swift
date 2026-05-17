import Foundation

struct InsightGenerator {
    func generate(snapshot: BehaviorSnapshot) -> [Insight] {
        var insights: [Insight] = []

        if let peak = snapshot.hourlyProductivity.max(by: { $0.score < $1.score }), peak.score > 0 {
            insights.append(
                Insight(
                    title: "Peak productivity is around \(formatHour(peak.hour)).",
                    detail: "Protect this window for demanding work before adding meetings or shallow tasks.",
                    category: .productivity,
                    priority: .high,
                    evidence: String(format: "Average signal %.0f%%", peak.score)
                )
            )
        }

        if let riskHour = snapshot.distraction.highestRiskHour {
            insights.append(
                Insight(
                    title: "Distraction risk peaks around \(formatHour(riskHour)).",
                    detail: "Use stricter blocking or plan a deliberate break before this window starts.",
                    category: .distraction,
                    priority: .high,
                    evidence: "\(snapshot.distraction.mostTemptingAttempts) attempts on top target"
                )
            )
        }

        if snapshot.rest.restDayCount > 0 {
            let lift = snapshot.rest.averagePostRestScore - snapshot.rest.averageNonRestScore
            insights.append(
                Insight(
                    title: lift >= 0 ? "Rest days are followed by stronger scores." : "Rest days are not yet improving next-day scores.",
                    detail: lift >= 0 ? "Keep rest rules predictable; recovery is supporting focus." : "Shorten late work sessions before adding more strictness.",
                    category: .recovery,
                    priority: .medium,
                    evidence: String(format: "Post-rest delta %.0f pts", lift)
                )
            )
        }

        if snapshot.boost.boostDays > 0 {
            insights.append(
                Insight(
                    title: String(format: "Boost Mode changes score by %.0f points.", snapshot.boost.boostScoreLift),
                    detail: snapshot.boost.boostScoreLift >= 0 ? "Use Boost Mode for high-value sessions, not as the default day shape." : "Reserve Boost Mode for clearer goals or shorter blocks.",
                    category: .boost,
                    priority: .medium,
                    evidence: "\(snapshot.boost.boostDays) boost days analyzed"
                )
            )
        }

        insights.append(
            Insight(
                title: String(format: "Consistency is %.0f%%.", snapshot.consistency.score),
                detail: "This combines goal completion and score volatility.",
                category: .consistency,
                priority: snapshot.consistency.score >= 70 ? .medium : .high,
                evidence: String(format: "Volatility %.0f pts", snapshot.consistency.volatility)
            )
        )

        insights.append(
            Insight(
                title: snapshot.efficiency.interpretation,
                detail: "Learning outputs are compared with productive hours and project session time.",
                category: .efficiency,
                priority: .medium,
                evidence: String(format: "%.2f solves per hour", snapshot.efficiency.outputPerHour)
            )
        )

        if snapshot.trend.direction != .stable || snapshot.trend.plateauDetected {
            insights.append(
                Insight(
                    title: trendTitle(snapshot.trend),
                    detail: "Weekly score movement is measured across recent historical summaries.",
                    category: .trend,
                    priority: snapshot.trend.direction == .declining ? .high : .medium,
                    evidence: String(format: "%.0f%% recent change", snapshot.trend.changePercent)
                )
            )
        }

        return insights.sorted { lhs, rhs in
            priorityRank(lhs.priority) < priorityRank(rhs.priority)
        }
    }

    private func trendTitle(_ trend: BehaviorTrendAnalysis) -> String {
        if trend.plateauDetected {
            return "Focus quality appears to be plateauing."
        }

        switch trend.direction {
        case .improving:
            return "Focus quality is improving."
        case .declining:
            return "Focus quality is declining recently."
        case .stable:
            return "Focus quality is stable."
        }
    }

    private func priorityRank(_ priority: InsightPriority) -> Int {
        switch priority {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let normalized = hour % 24
        if normalized == 0 { return "12am" }
        if normalized < 12 { return "\(normalized)am" }
        if normalized == 12 { return "12pm" }
        return "\(normalized - 12)pm"
    }
}
