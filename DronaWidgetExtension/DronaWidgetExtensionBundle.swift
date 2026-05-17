import WidgetKit
import SwiftUI

@main
struct DronaWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        DronaProductivityWidget()
        DronaStatusWidget()
        DronaStreakWidget()
        DronaContributionWidget()
        DronaGoalWidget()
        DronaRestWidget()
        DronaPortfolioWidget()
    }
}
