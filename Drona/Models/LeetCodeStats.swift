import Foundation

struct LeetCodeStats: Codable, Equatable {
    var username: String
    var totalSolved: Int
    var easySolved: Int
    var mediumSolved: Int
    var hardSolved: Int
    var dailyStreak: Int
    var totalActiveDays: Int
    var activeYears: [Int]
    var recentSubmissions: [LeetCodeSubmission]
    var activityHistory: [CodingActivityDay]
    var fetchedAt: Date

    static let empty = LeetCodeStats(
        username: "",
        totalSolved: 0,
        easySolved: 0,
        mediumSolved: 0,
        hardSolved: 0,
        dailyStreak: 0,
        totalActiveDays: 0,
        activeYears: [],
        recentSubmissions: [],
        activityHistory: [],
        fetchedAt: Date.distantPast
    )

    init(
        username: String,
        totalSolved: Int,
        easySolved: Int,
        mediumSolved: Int,
        hardSolved: Int,
        dailyStreak: Int,
        totalActiveDays: Int,
        activeYears: [Int],
        recentSubmissions: [LeetCodeSubmission],
        activityHistory: [CodingActivityDay],
        fetchedAt: Date
    ) {
        self.username = username
        self.totalSolved = totalSolved
        self.easySolved = easySolved
        self.mediumSolved = mediumSolved
        self.hardSolved = hardSolved
        self.dailyStreak = dailyStreak
        self.totalActiveDays = totalActiveDays
        self.activeYears = activeYears
        self.recentSubmissions = recentSubmissions
        self.activityHistory = activityHistory
        self.fetchedAt = fetchedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        totalSolved = try container.decodeIfPresent(Int.self, forKey: .totalSolved) ?? 0
        easySolved = try container.decodeIfPresent(Int.self, forKey: .easySolved) ?? 0
        mediumSolved = try container.decodeIfPresent(Int.self, forKey: .mediumSolved) ?? 0
        hardSolved = try container.decodeIfPresent(Int.self, forKey: .hardSolved) ?? 0
        dailyStreak = try container.decodeIfPresent(Int.self, forKey: .dailyStreak) ?? 0
        totalActiveDays = try container.decodeIfPresent(Int.self, forKey: .totalActiveDays) ?? 0
        activeYears = try container.decodeIfPresent([Int].self, forKey: .activeYears) ?? []
        recentSubmissions = try container.decodeIfPresent([LeetCodeSubmission].self, forKey: .recentSubmissions) ?? []
        activityHistory = try container.decodeIfPresent([CodingActivityDay].self, forKey: .activityHistory) ?? []
        fetchedAt = try container.decodeIfPresent(Date.self, forKey: .fetchedAt) ?? Date.distantPast
    }
}

struct LeetCodeSubmission: Codable, Identifiable, Equatable {
    var id: String {
        "\(titleSlug)-\(timestamp.timeIntervalSince1970)-\(statusDisplay)"
    }

    var title: String
    var titleSlug: String
    var timestamp: Date
    var statusDisplay: String
    var language: String
}

struct LeetCodeDailyRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var solvedCount: Int
    var easySolved: Int
    var mediumSolved: Int
    var hardSolved: Int
    var totalSolved: Int
    var submissions: [LeetCodeSubmission]
}

struct CodingActivityDay: Codable, Identifiable, Equatable {
    var id: String { CodingActivityDay.dayFormatter.string(from: date) }
    var date: Date
    var count: Int

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
