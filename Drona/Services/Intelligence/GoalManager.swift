import Foundation
import Combine

class GoalManager: ObservableObject {

    @Published var productiveGoalHours: Double = UserDefaults.standard.double(forKey: "productiveGoalHours") > 0 ? UserDefaults.standard.double(forKey: "productiveGoalHours") : 6 {
        didSet {
            UserDefaults.standard.set(productiveGoalHours, forKey: "productiveGoalHours")
            SettingsManager.shared.update { settings in
                settings.productiveGoalHours = productiveGoalHours
            }
        }
    }

    func progress(
        productiveTime: TimeInterval
    ) -> Double {

        let goalSeconds =
            productiveGoalHours * 3600

        return min(
            productiveTime / goalSeconds,
            1.0
        )
    }
}
