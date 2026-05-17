import Foundation

class AggregationEngine {

    func totalProductiveHours(
        summaries: [DailySummary]
    ) -> Double {

        let total =
            summaries.reduce(0) {

                $0 + $1.productiveTime
            }

        return total / 3600
    }

    func totalDistractingHours(
        summaries: [DailySummary]
    ) -> Double {

        let total =
            summaries.reduce(0) {

                $0 + $1.distractingTime
            }

        return total / 3600
    }

    func currentStreak(
        summaries: [DailySummary]
    ) -> Int {

        var streak = 0

        for summary in summaries.reversed() {

            if summary.productivityScore >= 70 {

                streak += 1

            } else {

                break
            }
        }

        return streak
    }
}
