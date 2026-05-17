import Foundation

struct GitHubStats: Codable, Equatable {
    var username: String
    var profileURL: URL?
    var repositoryCount: Int
    var publicGists: Int
    var followers: Int
    var following: Int
    var dailyCommits: Int
    var weeklyCommits: Int
    var activeRepositories: [String]
    var contributionStreak: Int
    var activityHistory: [CodingActivityDay]
    var recentEvents: [GitHubActivity]
    var fetchedAt: Date

    static let empty = GitHubStats(
        username: "",
        profileURL: nil,
        repositoryCount: 0,
        publicGists: 0,
        followers: 0,
        following: 0,
        dailyCommits: 0,
        weeklyCommits: 0,
        activeRepositories: [],
        contributionStreak: 0,
        activityHistory: [],
        recentEvents: [],
        fetchedAt: Date.distantPast
    )

    init(
        username: String,
        profileURL: URL?,
        repositoryCount: Int,
        publicGists: Int,
        followers: Int,
        following: Int,
        dailyCommits: Int,
        weeklyCommits: Int,
        activeRepositories: [String],
        contributionStreak: Int,
        activityHistory: [CodingActivityDay],
        recentEvents: [GitHubActivity],
        fetchedAt: Date
    ) {
        self.username = username
        self.profileURL = profileURL
        self.repositoryCount = repositoryCount
        self.publicGists = publicGists
        self.followers = followers
        self.following = following
        self.dailyCommits = dailyCommits
        self.weeklyCommits = weeklyCommits
        self.activeRepositories = activeRepositories
        self.contributionStreak = contributionStreak
        self.activityHistory = activityHistory
        self.recentEvents = recentEvents
        self.fetchedAt = fetchedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        profileURL = try container.decodeIfPresent(URL.self, forKey: .profileURL)
        repositoryCount = try container.decodeIfPresent(Int.self, forKey: .repositoryCount) ?? 0
        publicGists = try container.decodeIfPresent(Int.self, forKey: .publicGists) ?? 0
        followers = try container.decodeIfPresent(Int.self, forKey: .followers) ?? 0
        following = try container.decodeIfPresent(Int.self, forKey: .following) ?? 0
        dailyCommits = try container.decodeIfPresent(Int.self, forKey: .dailyCommits) ?? 0
        weeklyCommits = try container.decodeIfPresent(Int.self, forKey: .weeklyCommits) ?? dailyCommits
        activeRepositories = try container.decodeIfPresent([String].self, forKey: .activeRepositories) ?? []
        contributionStreak = try container.decodeIfPresent(Int.self, forKey: .contributionStreak) ?? 0
        activityHistory = try container.decodeIfPresent([CodingActivityDay].self, forKey: .activityHistory) ?? []
        recentEvents = try container.decodeIfPresent([GitHubActivity].self, forKey: .recentEvents) ?? []
        fetchedAt = try container.decodeIfPresent(Date.self, forKey: .fetchedAt) ?? Date.distantPast
    }
}

struct GitHubActivity: Codable, Identifiable, Equatable {
    var id: String
    var type: String
    var repository: String
    var commitCount: Int
    var createdAt: Date
}

struct GitHubDailyRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var commitCount: Int
    var eventCount: Int
    var repositories: [String]
}
