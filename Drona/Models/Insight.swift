import Foundation

struct Insight: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var category: InsightCategory
    var priority: InsightPriority
    var evidence: String
}

enum InsightCategory: String, CaseIterable, Hashable {
    case productivity = "Productivity"
    case distraction = "Distraction"
    case recovery = "Recovery"
    case boost = "Boost"
    case consistency = "Consistency"
    case efficiency = "Efficiency"
    case trend = "Trend"
}

enum InsightPriority: String, Hashable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}
