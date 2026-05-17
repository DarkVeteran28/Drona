import Foundation

struct GitHubService {
    static let defaultUsername = "DarkVeteran28"
    static let defaultProfileURL = URL(string: "https://github.com/DarkVeteran28")

    enum GitHubError: LocalizedError {
        case invalidURL(String)
        case invalidResponse(endpoint: String, statusCode: Int, payload: String)

        var errorDescription: String? {
            switch self {
            case let .invalidURL(endpoint):
                return "The GitHub endpoint could not be created: \(endpoint)."
            case let .invalidResponse(endpoint, statusCode, payload):
                return "GitHub returned HTTP \(statusCode) for \(endpoint): \(payload.prefix(240))"
            }
        }
    }

    @MainActor
    func fetchStats(username: String = "") async throws -> GitHubStats {
        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Self.defaultUsername : username

        let profileResponse: GitHubUserResponse = try await getJSON(
            endpoint: "https://api.github.com/users/\(normalizedUsername)"
        )
        let eventResponses: [GitHubEventResponse] = try await getJSON(
            endpoint: "https://api.github.com/users/\(normalizedUsername)/events/public?per_page=100"
        )
        let repositoryResponses: [GitHubRepositoryResponse] = try await getJSON(
            endpoint: "https://api.github.com/users/\(normalizedUsername)/repos?per_page=100&sort=updated&type=owner"
        )
        let pushEvents = eventResponses.filter { $0.type == "PushEvent" }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        let dailyCommits = pushEvents
            .filter { calendar.isDate($0.createdAt, inSameDayAs: today) }
            .reduce(0) { $0 + $1.commitCount }
        let weeklyCommits = pushEvents
            .filter { $0.createdAt >= weekStart }
            .reduce(0) { $0 + $1.commitCount }
        let activeRepositories = Array(Set(eventResponses.map(\.repo.name))).sorted()
        let activityHistory = makeActivityHistory(from: eventResponses)
        let recentEvents = eventResponses.map { event in
            GitHubActivity(
                id: event.id,
                type: event.type,
                repository: event.repo.name,
                commitCount: event.commitCount,
                createdAt: event.createdAt
            )
        }

        return GitHubStats(
            username: profileResponse.login,
            profileURL: profileResponse.htmlURL ?? Self.defaultProfileURL,
            repositoryCount: profileResponse.publicRepos ?? repositoryResponses.count,
            publicGists: profileResponse.publicGists ?? 0,
            followers: profileResponse.followers ?? 0,
            following: profileResponse.following ?? 0,
            dailyCommits: dailyCommits,
            weeklyCommits: weeklyCommits,
            activeRepositories: activeRepositories,
            contributionStreak: contributionStreak(from: activityHistory),
            activityHistory: activityHistory,
            recentEvents: recentEvents,
            fetchedAt: Date()
        )
    }

    @MainActor
    private func getJSON<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw GitHubError.invalidURL(endpoint)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Drona-macOS", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse(endpoint: endpoint, statusCode: -1, payload: debugPayload(from: data))
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let payload = debugPayload(from: data)
            print("GitHub request failed: HTTP \(httpResponse.statusCode) \(endpoint) \(payload)")
            throw GitHubError.invalidResponse(endpoint: endpoint, statusCode: httpResponse.statusCode, payload: payload)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    private func makeActivityHistory(from events: [GitHubEventResponse]) -> [CodingActivityDay] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.createdAt)
        }

        return grouped.map { date, dayEvents in
            let contributionCount = dayEvents.reduce(0) { total, event in
                total + max(event.commitCount, event.type == "PushEvent" ? 1 : 0)
            }
            return CodingActivityDay(date: date, count: contributionCount)
        }
        .sorted { $0.date < $1.date }
    }

    private func contributionStreak(from history: [CodingActivityDay]) -> Int {
        let calendar = Calendar.current
        let activeDays = Set(history.filter { $0.count > 0 }.map { calendar.startOfDay(for: $0.date) })
        var cursor = calendar.startOfDay(for: Date())
        var streak = 0

        while activeDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }

        return streak
    }

    private func debugPayload(from data: Data) -> String {
        String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
    }
}

private struct GitHubUserResponse: Decodable {
    var login: String
    var htmlURL: URL?
    var publicRepos: Int?
    var publicGists: Int?
    var followers: Int?
    var following: Int?

    enum CodingKeys: String, CodingKey {
        case login
        case htmlURL = "html_url"
        case publicRepos = "public_repos"
        case publicGists = "public_gists"
        case followers
        case following
    }
}

private struct GitHubRepositoryResponse: Decodable {
    var name: String
}

private struct GitHubEventResponse: Decodable {
    var id: String
    var type: String
    var repo: GitHubRepoResponse
    var payload: GitHubPayloadResponse
    var createdAt: Date

    var commitCount: Int {
        payload.commits?.count ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case repo
        case payload
        case createdAt = "created_at"
    }
}

private struct GitHubRepoResponse: Decodable {
    var name: String
}

private struct GitHubPayloadResponse: Decodable {
    var commits: [GitHubCommitResponse]?
}

private struct GitHubCommitResponse: Decodable {
    var sha: String
}
