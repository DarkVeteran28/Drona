import Foundation

struct GitHubPortfolioProject: Codable, Identifiable, Equatable {
    var id: Int
    var name: String
    var fullName: String
    var description: String
    var htmlURL: URL
    var homepageURL: URL?
    var primaryLanguage: String?
    var languageBreakdown: [GitHubPortfolioLanguage]
    var topics: [String]
    var stars: Int
    var forks: Int
    var watchers: Int
    var openIssues: Int
    var sizeKB: Int
    var isFork: Bool
    var createdAt: Date
    var updatedAt: Date
    var pushedAt: Date?
    var readmeMarkdown: String
    var readmeIntro: String
    var latestCommits: [GitHubPortfolioCommit]
    var commitActivityScore: Int
    var isPinned: Bool

    var showcaseScore: Double {
        let freshness = max(0, 30 - Date().timeIntervalSince(updatedAt) / 86_400) / 30
        let languageDepth = min(Double(languageBreakdown.count) / 4, 1)
        let topicDepth = min(Double(topics.count) / 6, 1)
        return Double(stars * 4 + forks * 2 + commitActivityScore) + freshness * 20 + languageDepth * 10 + topicDepth * 10
    }
}

struct GitHubPortfolioLanguage: Codable, Identifiable, Equatable {
    var id: String { name }
    var name: String
    var bytes: Int
    var colorHex: String

    var percentage: Double
}

struct GitHubPortfolioCommit: Codable, Identifiable, Equatable {
    var id: String
    var message: String
    var authorName: String
    var committedAt: Date
    var url: URL?
}

struct GitHubPortfolioAnalytics: Codable, Equatable {
    var totalRepositories: Int
    var totalStars: Int
    var totalForks: Int
    var totalCommitsLoaded: Int
    var mostUsedLanguage: String
    var mostActiveProject: String
    var longestMaintainedProject: String
    var languageBreakdown: [GitHubPortfolioLanguage]

    static let empty = GitHubPortfolioAnalytics(
        totalRepositories: 0,
        totalStars: 0,
        totalForks: 0,
        totalCommitsLoaded: 0,
        mostUsedLanguage: "None",
        mostActiveProject: "None",
        longestMaintainedProject: "None",
        languageBreakdown: []
    )
}

struct GitHubPortfolioSnapshot: Codable, Equatable {
    var username: String
    var profileURL: URL
    var projects: [GitHubPortfolioProject]
    var analytics: GitHubPortfolioAnalytics
    var fetchedAt: Date

    static let empty = GitHubPortfolioSnapshot(
        username: "DarkVeteran28",
        profileURL: URL(string: "https://github.com/DarkVeteran28")!,
        projects: [],
        analytics: .empty,
        fetchedAt: Date.distantPast
    )
}

enum PortfolioSortMode: String, CaseIterable, Identifiable {
    case featured = "Featured"
    case recentlyUpdated = "Recently Updated"
    case mostActive = "Most Active"
    case stars = "Stars"
    case name = "Name"

    var id: String { rawValue }
}

enum PortfolioQuickFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case aiML = "AI / ML"
    case macOS = "macOS"
    case python = "Python"
    case swift = "Swift"
    case web = "Web"

    var id: String { rawValue }
}
