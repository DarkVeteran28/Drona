import Combine
import Foundation

final class PerformanceManager: ObservableObject {
    @Published private(set) var snapshot = PerformanceSnapshot(
        memoryMegabytes: 0,
        trackingInterval: 2,
        batterySavingMode: false,
        lowPowerMode: false
    )

    func refresh() {
        let batterySaving = UserDefaults.standard.bool(forKey: "batterySavingMode")
        let configuredInterval = UserDefaults.standard.double(forKey: "trackingFrequencySeconds")
        let interval = configuredInterval > 0 ? configuredInterval : 2
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

        snapshot = PerformanceSnapshot(
            memoryMegabytes: currentMemoryMegabytes(),
            trackingInterval: max(interval, lowPower || batterySaving ? 5 : 1),
            batterySavingMode: batterySaving,
            lowPowerMode: lowPower
        )
    }

    private func currentMemoryMegabytes() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), reboundPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        return Double(info.resident_size) / 1_048_576
    }
}
