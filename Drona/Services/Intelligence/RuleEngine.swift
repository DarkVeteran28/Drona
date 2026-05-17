import Foundation
import Combine

class RuleEngine: ObservableObject {

    @Published var metrics =
        DailyMetrics()

    let classifier =
        ProductivityClassifier()

    let goalManager =
        GoalManager()
    
    let historyManager =
        HistoryManager()
    
    func saveTodaySummary() {

        let summary = DailySummary(

            date: Date(),

            productiveTime:
                metrics.productiveTime,

            neutralTime:
                metrics.neutralTime,

            distractingTime:
                metrics.distractingTime,

            productivityScore:
                metrics.productivityScore,

            goalCompletion: 0,

            status:
                metrics.status.rawValue,

            restModeEnabled: false,

            boostModeEnabled: false,

            violationsCount: 0
        )

        historyManager.saveSummary(
            summary
        )
    }
    
    private func updateWidgets() {

        let summary = WidgetSummary(

            productiveHours:
                metrics.productiveTime / 3600,

            distractingHours:
                metrics.distractingTime / 3600,

            productivityScore:
                metrics.productivityScore,

            status:
                metrics.status.rawValue,

            streak: 0,

            goalProgress: 0
        )

        SharedDataProvider.shared
            .saveSummary(summary)

        WidgetRefreshManager
            .refreshAllWidgets()
    }

    func processActivity(
        appName: String,
        duration: TimeInterval
    ) {

        let category =
            classifier.classify(
                appName: appName
            )

        switch category {

        case .productive:

            metrics.productiveTime += duration

        case .neutral:

            metrics.neutralTime += duration

        case .distracting:

            metrics.distractingTime += duration
        }

        updateScore()

        evaluateStatus()
        updateWidgets()
    }

    private func updateScore() {

        let productive =
            metrics.productiveTime

        let distracting =
            metrics.distractingTime

        let total =
            productive + distracting

        guard total > 0 else {

            metrics.productivityScore = 0

            return
        }

        metrics.productivityScore =
            (productive / total) * 100
    }

    private func evaluateStatus() {

        let score =
            metrics.productivityScore

        if score >= 80 {

            metrics.status = .winning

        } else if score >= 50 {

            metrics.status = .onTrack

        } else {

            metrics.status = .losing
        }
    }
}
