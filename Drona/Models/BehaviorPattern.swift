import Foundation

struct BehaviorSnapshot {
    var insights: [Insight]
    var hourlyProductivity: [HourlyBehaviorPoint]
    var distractionHeatmap: [HourlyBehaviorPoint]
    var focusDistribution: [FocusSessionBucket]
    var weeklyConsistency: [ConsistencyPoint]
    var patterns: [BehaviorPattern]
    var focus: FocusAnalysis
    var distraction: DistractionPatternAnalysis
    var rest: RestBehaviorAnalysis
    var boost: BoostEffectivenessAnalysis
    var consistency: ConsistencyAnalysis
    var efficiency: EfficiencyAnalysis
    var trend: BehaviorTrendAnalysis
}

struct BehaviorPattern: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var value: String
    var detail: String
    var category: InsightCategory
}

struct HourlyBehaviorPoint: Identifiable, Hashable {
    let id = UUID()
    var hour: Int
    var score: Double
    var productiveHours: Double
    var distractionAttempts: Int
}

struct FocusSessionBucket: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var sessionCount: Int
    var averageScore: Double
}

struct ConsistencyPoint: Identifiable, Hashable {
    let id = UUID()
    var weekStart: Date
    var consistencyScore: Double
    var volatility: Double
    var goalCompletion: Double
}

struct FocusAnalysis: Hashable {
    var averageDeepWorkHours: Double
    var deepWorkDays: Int
    var bestDayOfWeek: String
    var bestDayScore: Double
}

struct DistractionPatternAnalysis: Hashable {
    var mostTemptingTarget: String
    var mostTemptingAttempts: Int
    var highestRiskHour: Int?
    var escalationRate: Double
}

struct RestBehaviorAnalysis: Hashable {
    var restDayCount: Int
    var averagePostRestScore: Double
    var averageNonRestScore: Double
    var burnoutRisk: Double
}

struct BoostEffectivenessAnalysis: Hashable {
    var boostDays: Int
    var boostScoreLift: Double
    var sustainabilityScore: Double
}

struct ConsistencyAnalysis: Hashable {
    var score: Double
    var volatility: Double
    var goalCompletionRate: Double
    var stableWeeks: Int
}

struct EfficiencyAnalysis: Hashable {
    var outputPerHour: Double
    var bestEfficiencyDay: Date?
    var shortSessionAdvantage: Double
    var interpretation: String
}

struct BehaviorTrendAnalysis: Hashable {
    var direction: TrendDirection
    var changePercent: Double
    var consecutiveImprovingWeeks: Int
    var plateauDetected: Bool
}

enum TrendDirection: String, Hashable {
    case improving = "Improving"
    case declining = "Declining"
    case stable = "Stable"
}
