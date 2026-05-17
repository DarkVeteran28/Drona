import Foundation

struct LeetCodeService {
    static let defaultUsername = "Darkveteran28"

    enum LeetCodeError: LocalizedError {
        case invalidURL
        case userNotFound
        case invalidResponse(statusCode: Int, payload: String)
        case graphQLErrors(String)
        case malformedCalendar

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "The LeetCode endpoint could not be created."
            case .userNotFound:
                return "No LeetCode profile was found for Darkveteran28."
            case let .invalidResponse(statusCode, payload):
                return "LeetCode returned HTTP \(statusCode): \(payload.prefix(240))"
            case let .graphQLErrors(message):
                return "LeetCode GraphQL error: \(message)"
            case .malformedCalendar:
                return "LeetCode returned an unreadable submission calendar."
            }
        }
    }

    @MainActor
    func fetchStats(username: String = "") async throws -> LeetCodeStats {
        guard let url = URL(string: "https://leetcode.com/graphql") else {
            throw LeetCodeError.invalidURL
        }

        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Self.defaultUsername : username
        let requestBody = LeetCodeGraphQLRequest(
            operationName: "getDronaLeetCodeStats",
            query: Self.profileQuery,
            variables: ["username": normalizedUsername]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Origin")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Referer")
        request.setValue("Drona macOS", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LeetCodeError.invalidResponse(statusCode: -1, payload: debugPayload(from: data))
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let payload = debugPayload(from: data)
            print("LeetCode request failed: HTTP \(httpResponse.statusCode) \(payload)")
            throw LeetCodeError.invalidResponse(statusCode: httpResponse.statusCode, payload: payload)
        }

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LeetCodeGraphQLResponse.self, from: data)
        if let errors = decoded.errors, !errors.isEmpty {
            let message = errors.map(\.message).joined(separator: "; ")
            print("LeetCode GraphQL errors: \(message)")
            throw LeetCodeError.graphQLErrors(message)
        }

        guard let matchedUser = decoded.data?.matchedUser else {
            print("LeetCode matchedUser missing. Payload: \(debugPayload(from: data))")
            throw LeetCodeError.userNotFound
        }

        let counts = Dictionary(
            uniqueKeysWithValues: matchedUser.submitStatsGlobal.acSubmissionNum.map { ($0.difficulty, $0.count) }
        )
        let submissions = (decoded.data?.recentSubmissionList ?? []).compactMap(Self.makeSubmission)
        let activityHistory = try parseSubmissionCalendar(matchedUser.userCalendar.submissionCalendar)

        return LeetCodeStats(
            username: normalizedUsername,
            totalSolved: counts["All"] ?? 0,
            easySolved: counts["Easy"] ?? 0,
            mediumSolved: counts["Medium"] ?? 0,
            hardSolved: counts["Hard"] ?? 0,
            dailyStreak: matchedUser.userCalendar.streak,
            totalActiveDays: matchedUser.userCalendar.totalActiveDays,
            activeYears: matchedUser.userCalendar.activeYears,
            recentSubmissions: submissions,
            activityHistory: activityHistory,
            fetchedAt: Date()
        )
    }

    private static func makeSubmission(_ response: LeetCodeSubmissionResponse) -> LeetCodeSubmission? {
        guard let timestamp = TimeInterval(response.timestamp) else {
            return nil
        }

        return LeetCodeSubmission(
            title: response.title,
            titleSlug: response.titleSlug,
            timestamp: Date(timeIntervalSince1970: timestamp),
            statusDisplay: response.statusDisplay,
            language: response.lang
        )
    }

    private func parseSubmissionCalendar(_ calendarJSON: String) throws -> [CodingActivityDay] {
        guard let data = calendarJSON.data(using: .utf8) else {
            throw LeetCodeError.malformedCalendar
        }

        do {
            let rawCalendar = try JSONDecoder().decode([String: Int].self, from: data)
            return rawCalendar.compactMap { timestamp, count in
                guard let interval = TimeInterval(timestamp) else {
                    return nil
                }
                return CodingActivityDay(date: Date(timeIntervalSince1970: interval), count: count)
            }
            .sorted { $0.date < $1.date }
        } catch {
            print("Failed decoding LeetCode submissionCalendar: \(calendarJSON)")
            throw LeetCodeError.malformedCalendar
        }
    }

    private func debugPayload(from data: Data) -> String {
        String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
    }

    private static let profileQuery = """
    query getDronaLeetCodeStats($username: String!) {
      matchedUser(username: $username) {
        submitStatsGlobal {
          acSubmissionNum {
            difficulty
            count
            submissions
          }
        }
        userCalendar {
          streak
          totalActiveDays
          submissionCalendar
          activeYears
        }
      }
      recentSubmissionList(username: $username, limit: 50) {
        title
        titleSlug
        timestamp
        statusDisplay
        lang
      }
    }
    """
}

private struct LeetCodeGraphQLRequest: Encodable {
    var operationName: String
    var query: String
    var variables: [String: String]
}

private struct LeetCodeGraphQLResponse: Decodable {
    var data: LeetCodeGraphQLData?
    var errors: [LeetCodeGraphQLError]?
}

private struct LeetCodeGraphQLError: Decodable {
    var message: String
}

private struct LeetCodeGraphQLData: Decodable {
    var matchedUser: LeetCodeMatchedUser?
    var recentSubmissionList: [LeetCodeSubmissionResponse]
}

private struct LeetCodeMatchedUser: Decodable {
    var submitStatsGlobal: LeetCodeSubmitStats
    var userCalendar: LeetCodeUserCalendar
}

private struct LeetCodeSubmitStats: Decodable {
    var acSubmissionNum: [LeetCodeSolvedCount]
}

private struct LeetCodeSolvedCount: Decodable {
    var difficulty: String
    var count: Int
    var submissions: Int
}

private struct LeetCodeUserCalendar: Decodable {
    var streak: Int
    var totalActiveDays: Int
    var submissionCalendar: String
    var activeYears: [Int]
}

private struct LeetCodeSubmissionResponse: Decodable {
    var title: String
    var titleSlug: String
    var timestamp: String
    var statusDisplay: String
    var lang: String
}
