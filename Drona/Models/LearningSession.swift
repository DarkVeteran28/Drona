import Foundation

struct LearningSession: Codable, Identifiable, Equatable {
    var id = UUID()
    var projectName: String
    var category: LearningCategory
    var tags: [String]
    var startDate: Date
    var duration: TimeInterval
    var productivityScore: Double
    var notes: String

    var durationHours: Double {
        duration / 3600
    }
}

enum LearningCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case deepLearning = "Deep Learning"
    case computerVision = "Computer Vision"
    case backendDevelopment = "Backend Development"
    case systemDesign = "System Design"
    case macOSDevelopment = "macOS Development"
    case algorithms = "Algorithms"
    case research = "Research"
    case other = "Other"

    var id: String {
        rawValue
    }
}
