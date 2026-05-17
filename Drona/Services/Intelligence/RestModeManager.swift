import Foundation
import Combine

class RestModeManager: ObservableObject {

    @Published var restModeEnabled = false

    @Published var restDaysUsed = 0

    let maxRestDays = 6

    func activateRestMode() {

        guard restDaysUsed < maxRestDays
        else {
            return
        }

        restModeEnabled = true

        restDaysUsed += 1
    }

    func disableRestMode() {

        restModeEnabled = false
    }
}
