import Foundation

struct ViolationRecord: Identifiable {

    var id = UUID()

    var timestamp: Date

    var target: String

    var attemptCount: Int
}
