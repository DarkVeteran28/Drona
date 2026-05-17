import Foundation

struct TrendEngine {
    func analyze(trends: [DailyTrendPoint]) -> BehaviorTrendAnalysis {
        let weekly = weeklyAverages(from: trends)
        guard weekly.count >= 2 else {
            return BehaviorTrendAnalysis(
                direction: .stable,
                changePercent: 0,
                consecutiveImprovingWeeks: 0,
                plateauDetected: true
            )
        }

        let previous = weekly.dropLast().suffix(2).map(\.score).average
        let current = weekly.suffix(2).map(\.score).average
        let delta = current - previous
        let changePercent = previous == 0 ? 0 : (delta / previous) * 100
        let direction: TrendDirection

        if changePercent > 5 {
            direction = .improving
        } else if changePercent < -5 {
            direction = .declining
        } else {
            direction = .stable
        }

        return BehaviorTrendAnalysis(
            direction: direction,
            changePercent: changePercent,
            consecutiveImprovingWeeks: consecutiveImprovingWeeks(weekly),
            plateauDetected: abs(changePercent) < 3 && weekly.count >= 3
        )
    }

    func consistencyPoints(from trends: [DailyTrendPoint]) -> [ConsistencyPoint] {
        Dictionary(grouping: trends) { point in
            Calendar.current.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
        }
        .map { weekStart, points in
            let scores = points.map(\.productivityScore)
            let completion = points.map(\.goalCompletion).average
            let volatility = standardDeviation(scores)
            let consistency = max(0, min(100, (completion * 65) + (100 - volatility) * 0.35))

            return ConsistencyPoint(
                weekStart: weekStart,
                consistencyScore: consistency,
                volatility: volatility,
                goalCompletion: completion
            )
        }
        .sorted { $0.weekStart < $1.weekStart }
    }

    private func weeklyAverages(from trends: [DailyTrendPoint]) -> [(date: Date, score: Double)] {
        Dictionary(grouping: trends) { point in
            Calendar.current.dateInterval(of: .weekOfYear, for: point.date)?.start ?? point.date
        }
        .map { ($0.key, $0.value.map(\.productivityScore).average) }
        .sorted { $0.date < $1.date }
    }

    private func consecutiveImprovingWeeks(_ weekly: [(date: Date, score: Double)]) -> Int {
        guard weekly.count >= 2 else {
            return 0
        }

        var count = 0
        for index in stride(from: weekly.count - 1, through: 1, by: -1) {
            if weekly[index].score > weekly[index - 1].score {
                count += 1
            } else {
                break
            }
        }

        return count
    }

    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else {
            return 0
        }

        let average = values.average
        let variance = values.reduce(0) { $0 + pow($1 - average, 2) } / Double(values.count)
        return sqrt(variance)
    }
}

extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else {
            return 0
        }

        return reduce(0, +) / Double(count)
    }
}
