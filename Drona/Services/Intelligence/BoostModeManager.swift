import Foundation
import Combine

class BoostModeManager: ObservableObject {

    @Published var boostEnabled = false

    func adjustedGoal(
        baseGoal: Double
    ) -> Double {

        if boostEnabled {

            return baseGoal + 2
        }

        return baseGoal
    }
}
