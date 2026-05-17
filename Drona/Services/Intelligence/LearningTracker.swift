import Foundation
import Combine

@MainActor
final class LearningTracker: ObservableObject {
    @Published private(set) var leetCodeStats: LeetCodeStats = .empty
    @Published private(set) var leetCodeRecords: [LeetCodeDailyRecord] = []
    @Published private(set) var sessions: [LearningSession] = []
    @Published private(set) var achievements: [Achievement] = []
    @Published private(set) var gitHubStats: GitHubStats = .empty
    @Published private(set) var gitHubRecords: [GitHubDailyRecord] = []
    @Published var leetCodeUsername = LeetCodeService.defaultUsername
    @Published var gitHubUsername = GitHubService.defaultUsername
    @Published var lastIntegrationError: String?
    @Published var isRefreshingLeetCode = false
    @Published var isRefreshingGitHub = false

    private let leetCodeService = LeetCodeService()
    private let gitHubService = GitHubService()
    private let achievementEngine = AchievementEngine()
    private let storeURL: URL
    private let automaticRefreshInterval: UInt64 = 15 * 60 * 1_000_000_000

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storeURL = documents.appendingPathComponent("learningData.json")
        load()
        applyHardcodedAccounts()
        publishCodingSummaryToWidgets()
    }

    func addSession(
        projectName: String,
        category: LearningCategory,
        tags: [String],
        durationHours: Double,
        productivityScore: Double,
        notes: String
    ) {
        let trimmedProject = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedProject.isEmpty, durationHours > 0 else {
            return
        }

        let session = LearningSession(
            projectName: trimmedProject,
            category: category,
            tags: tags,
            startDate: Date(),
            duration: durationHours * 3600,
            productivityScore: productivityScore,
            notes: notes
        )

        sessions.append(session)
        reevaluateAchievements(productiveHoursThisWeek: 0)
        save()
    }

    func refreshAllCodingData(productiveHoursThisWeek: Double) async {
        await refreshLeetCode(username: LeetCodeService.defaultUsername, productiveHoursThisWeek: productiveHoursThisWeek)
        await refreshGitHub(username: GitHubService.defaultUsername)
    }

    func runAutomaticRefresh(productiveHoursThisWeek: Double) async {
        await refreshAllCodingData(productiveHoursThisWeek: productiveHoursThisWeek)

        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: automaticRefreshInterval)
            await refreshAllCodingData(productiveHoursThisWeek: productiveHoursThisWeek)
        }
    }

    func refreshLeetCode(username: String = "", productiveHoursThisWeek: Double) async {
        let trimmedUsername = normalizedLeetCodeUsername(username)

        isRefreshingLeetCode = true
        defer { isRefreshingLeetCode = false }

        do {
            let stats = try await leetCodeService.fetchStats(username: trimmedUsername)
            leetCodeUsername = LeetCodeService.defaultUsername
            leetCodeStats = stats
            mergeLeetCodeHistory(from: stats)
            reevaluateAchievements(productiveHoursThisWeek: productiveHoursThisWeek)
            lastIntegrationError = nil
            save()
            publishCodingSummaryToWidgets()
        } catch {
            print("LeetCode refresh failed: \(error.localizedDescription)")
            lastIntegrationError = error.localizedDescription
        }
    }

    func refreshGitHub(username: String = "") async {
        let trimmedUsername = normalizedGitHubUsername(username)

        isRefreshingGitHub = true
        defer { isRefreshingGitHub = false }

        do {
            gitHubUsername = GitHubService.defaultUsername
            gitHubStats = try await gitHubService.fetchStats(username: trimmedUsername)
            mergeGitHubHistory(from: gitHubStats)
            lastIntegrationError = nil
            save()
            publishCodingSummaryToWidgets()
        } catch {
            print("GitHub refresh failed: \(error.localizedDescription)")
            lastIntegrationError = error.localizedDescription
        }
    }

    func reevaluateAchievements(productiveHoursThisWeek: Double) {
        achievements = achievementEngine.detectAchievements(
            leetCodeRecords: leetCodeRecords,
            sessions: sessions,
            productiveHoursThisWeek: productiveHoursThisWeek,
            existing: achievements
        )
        save()
    }

    private func normalizedLeetCodeUsername(_ username: String) -> String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? LeetCodeService.defaultUsername : LeetCodeService.defaultUsername
    }

    private func normalizedGitHubUsername(_ username: String) -> String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? GitHubService.defaultUsername : GitHubService.defaultUsername
    }

    private func applyHardcodedAccounts() {
        leetCodeUsername = LeetCodeService.defaultUsername
        gitHubUsername = GitHubService.defaultUsername

        if leetCodeStats.username.isEmpty {
            leetCodeStats.username = LeetCodeService.defaultUsername
        }
        if gitHubStats.username.isEmpty {
            gitHubStats.username = GitHubService.defaultUsername
            gitHubStats.profileURL = GitHubService.defaultProfileURL
        }
    }

    private func mergeLeetCodeHistory(from stats: LeetCodeStats) {
        let calendar = Calendar.current
        var recordsByDay = Dictionary(uniqueKeysWithValues: leetCodeRecords.map { (calendar.startOfDay(for: $0.date), $0) })

        for activity in stats.activityHistory {
            let day = calendar.startOfDay(for: activity.date)
            let submissions = stats.recentSubmissions.filter {
                $0.statusDisplay == "Accepted" && calendar.isDate($0.timestamp, inSameDayAs: day)
            }
            let existing = recordsByDay[day]
            recordsByDay[day] = LeetCodeDailyRecord(
                id: existing?.id ?? UUID(),
                date: day,
                solvedCount: max(activity.count, submissions.count, existing?.solvedCount ?? 0),
                easySolved: existing?.easySolved ?? 0,
                mediumSolved: existing?.mediumSolved ?? 0,
                hardSolved: existing?.hardSolved ?? 0,
                totalSolved: existing?.totalSolved ?? stats.totalSolved,
                submissions: submissions.isEmpty ? (existing?.submissions ?? []) : submissions
            )
        }

        upsertTodayLeetCodeRecord(from: stats, recordsByDay: &recordsByDay)
        leetCodeRecords = recordsByDay.values.sorted { $0.date < $1.date }
    }

    private func upsertTodayLeetCodeRecord(from stats: LeetCodeStats, recordsByDay: inout [Date: LeetCodeDailyRecord]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let previousRecord = recordsByDay.values
            .filter { !calendar.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.date < $1.date }
            .last
        let acceptedToday = stats.recentSubmissions.filter { submission in
            submission.statusDisplay == "Accepted" && calendar.isDate(submission.timestamp, inSameDayAs: today)
        }
        let activityToday = stats.activityHistory.first { calendar.isDate($0.date, inSameDayAs: today) }?.count ?? 0
        let solvedDelta = max(stats.totalSolved - (previousRecord?.totalSolved ?? stats.totalSolved), acceptedToday.count, activityToday)
        let easyDelta = max(stats.easySolved - (previousRecord?.easySolved ?? stats.easySolved), 0)
        let mediumDelta = max(stats.mediumSolved - (previousRecord?.mediumSolved ?? stats.mediumSolved), 0)
        let hardDelta = max(stats.hardSolved - (previousRecord?.hardSolved ?? stats.hardSolved), 0)
        let existing = recordsByDay[today]

        recordsByDay[today] = LeetCodeDailyRecord(
            id: existing?.id ?? UUID(),
            date: today,
            solvedCount: max(solvedDelta, existing?.solvedCount ?? 0),
            easySolved: easyDelta,
            mediumSolved: mediumDelta,
            hardSolved: hardDelta,
            totalSolved: stats.totalSolved,
            submissions: acceptedToday.isEmpty ? (existing?.submissions ?? []) : acceptedToday
        )
    }

    private func mergeGitHubHistory(from stats: GitHubStats) {
        let calendar = Calendar.current
        var recordsByDay = Dictionary(uniqueKeysWithValues: gitHubRecords.map { (calendar.startOfDay(for: $0.date), $0) })

        for activity in stats.activityHistory {
            let day = calendar.startOfDay(for: activity.date)
            let events = stats.recentEvents.filter { calendar.isDate($0.createdAt, inSameDayAs: day) }
            let repositories = Array(Set(events.map(\.repository))).sorted()
            let existing = recordsByDay[day]

            recordsByDay[day] = GitHubDailyRecord(
                id: existing?.id ?? UUID(),
                date: day,
                commitCount: max(activity.count, existing?.commitCount ?? 0),
                eventCount: max(events.count, existing?.eventCount ?? 0),
                repositories: repositories.isEmpty ? (existing?.repositories ?? []) : repositories
            )
        }

        gitHubRecords = recordsByDay.values.sorted { $0.date < $1.date }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(
                LearningStore(
                    leetCodeStats: leetCodeStats,
                    leetCodeRecords: leetCodeRecords,
                    sessions: sessions,
                    achievements: achievements,
                    gitHubStats: gitHubStats,
                    gitHubRecords: gitHubRecords,
                    leetCodeUsername: leetCodeUsername,
                    gitHubUsername: gitHubUsername
                )
            )
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            print("Failed saving learning data: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: storeURL)
            let store = try JSONDecoder().decode(LearningStore.self, from: data)
            leetCodeStats = store.leetCodeStats
            leetCodeRecords = store.leetCodeRecords
            sessions = store.sessions
            achievements = store.achievements
            gitHubStats = store.gitHubStats
            gitHubRecords = store.gitHubRecords
            leetCodeUsername = store.leetCodeUsername
            gitHubUsername = store.gitHubUsername
        } catch {
            leetCodeStats = .empty
            leetCodeRecords = []
            sessions = []
            achievements = []
            gitHubStats = .empty
            gitHubRecords = []
        }
    }

    private func publishCodingSummaryToWidgets() {
        SharedDataProvider.shared.saveCodingSummary(
            leetCodeStats: leetCodeStats,
            leetCodeRecords: leetCodeRecords,
            gitHubStats: gitHubStats
        )
        WidgetRefreshManager.refreshAllWidgets(force: true)
    }
}

private struct LearningStore: Codable {
    var leetCodeStats: LeetCodeStats
    var leetCodeRecords: [LeetCodeDailyRecord]
    var sessions: [LearningSession]
    var achievements: [Achievement]
    var gitHubStats: GitHubStats
    var gitHubRecords: [GitHubDailyRecord]
    var leetCodeUsername: String
    var gitHubUsername: String

    init(
        leetCodeStats: LeetCodeStats,
        leetCodeRecords: [LeetCodeDailyRecord],
        sessions: [LearningSession],
        achievements: [Achievement],
        gitHubStats: GitHubStats,
        gitHubRecords: [GitHubDailyRecord],
        leetCodeUsername: String,
        gitHubUsername: String
    ) {
        self.leetCodeStats = leetCodeStats
        self.leetCodeRecords = leetCodeRecords
        self.sessions = sessions
        self.achievements = achievements
        self.gitHubStats = gitHubStats
        self.gitHubRecords = gitHubRecords
        self.leetCodeUsername = leetCodeUsername
        self.gitHubUsername = gitHubUsername
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        leetCodeStats = try container.decodeIfPresent(LeetCodeStats.self, forKey: .leetCodeStats) ?? .empty
        leetCodeRecords = try container.decodeIfPresent([LeetCodeDailyRecord].self, forKey: .leetCodeRecords) ?? []
        sessions = try container.decodeIfPresent([LearningSession].self, forKey: .sessions) ?? []
        achievements = try container.decodeIfPresent([Achievement].self, forKey: .achievements) ?? []
        gitHubStats = try container.decodeIfPresent(GitHubStats.self, forKey: .gitHubStats) ?? .empty
        gitHubRecords = try container.decodeIfPresent([GitHubDailyRecord].self, forKey: .gitHubRecords) ?? []
        leetCodeUsername = try container.decodeIfPresent(String.self, forKey: .leetCodeUsername) ?? LeetCodeService.defaultUsername
        gitHubUsername = try container.decodeIfPresent(String.self, forKey: .gitHubUsername) ?? GitHubService.defaultUsername
    }
}
