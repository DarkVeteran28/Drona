import Foundation

struct GitHubPortfolioService {
    static let username = "DarkVeteran28"
    static let profileURL = URL(string: "https://github.com/DarkVeteran28")!

    enum PortfolioError: LocalizedError {
        case invalidURL(String)
        case invalidResponse(endpoint: String, statusCode: Int, payload: String)

        var errorDescription: String? {
            switch self {
            case let .invalidURL(endpoint):
                return "The GitHub portfolio endpoint could not be created: \(endpoint)."
            case let .invalidResponse(endpoint, statusCode, payload):
                return "GitHub returned HTTP \(statusCode) for \(endpoint): \(payload.prefix(220))"
            }
        }
    }

    func fetchPortfolio(token: String? = nil, pinnedProjectNames: Set<String>) async throws -> GitHubPortfolioSnapshot {
        let repositories = try await fetchAllRepositories(token: token)
        var projects: [GitHubPortfolioProject] = []

        for repository in repositories where !repository.archived {
            let languageBreakdown = try await fetchLanguages(repositoryFullName: repository.fullName, token: token)
            let readmeMarkdown = (try? await fetchReadme(repositoryFullName: repository.fullName, token: token)) ?? ""
            let commits = (try? await fetchLatestCommits(repositoryFullName: repository.fullName, token: token)) ?? []
            let project = GitHubPortfolioProject(
                id: repository.id,
                name: repository.name,
                fullName: repository.fullName,
                description: repository.description ?? "A public GitHub project by DarkVeteran28.",
                htmlURL: repository.htmlURL,
                homepageURL: repository.homepageURL,
                primaryLanguage: repository.language ?? languageBreakdown.first?.name,
                languageBreakdown: languageBreakdown,
                topics: repository.topics,
                stars: repository.stargazersCount,
                forks: repository.forksCount,
                watchers: repository.watchersCount,
                openIssues: repository.openIssuesCount,
                sizeKB: repository.size,
                isFork: repository.fork,
                createdAt: repository.createdAt,
                updatedAt: repository.updatedAt,
                pushedAt: repository.pushedAt,
                readmeMarkdown: readmeMarkdown,
                readmeIntro: Self.makeReadmeIntro(markdown: readmeMarkdown, fallback: repository.description),
                latestCommits: commits,
                commitActivityScore: commits.filter { Date().timeIntervalSince($0.committedAt) < 30 * 86_400 }.count,
                isPinned: pinnedProjectNames.contains(repository.name)
            )
            projects.append(project)
        }

        let sortedProjects = projects.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.showcaseScore > rhs.showcaseScore
        }

        return GitHubPortfolioSnapshot(
            username: Self.username,
            profileURL: Self.profileURL,
            projects: sortedProjects,
            analytics: makeAnalytics(projects: sortedProjects),
            fetchedAt: Date()
        )
    }

    private func fetchAllRepositories(token: String?) async throws -> [GitHubRepositoryPortfolioResponse] {
        var page = 1
        var repositories: [GitHubRepositoryPortfolioResponse] = []

        while true {
            let endpoint = "https://api.github.com/users/\(Self.username)/repos?per_page=100&page=\(page)&sort=updated&type=owner"
            let pageItems: [GitHubRepositoryPortfolioResponse] = try await getJSON(endpoint: endpoint, token: token)
            repositories.append(contentsOf: pageItems)

            if pageItems.count < 100 {
                break
            }
            page += 1
        }

        return repositories
    }

    private func fetchLanguages(repositoryFullName: String, token: String?) async throws -> [GitHubPortfolioLanguage] {
        let endpoint = "https://api.github.com/repos/\(repositoryFullName)/languages"
        let languages: [String: Int] = try await getJSON(endpoint: endpoint, token: token)
        let totalBytes = max(languages.values.reduce(0, +), 1)

        return languages.map { name, bytes in
            GitHubPortfolioLanguage(
                name: name,
                bytes: bytes,
                colorHex: Self.languageColor(for: name),
                percentage: Double(bytes) / Double(totalBytes)
            )
        }
        .sorted { $0.bytes > $1.bytes }
    }

    private func fetchReadme(repositoryFullName: String, token: String?) async throws -> String {
        let endpoint = "https://api.github.com/repos/\(repositoryFullName)/readme"
        let response: GitHubReadmeResponse = try await getJSON(endpoint: endpoint, token: token)
        let normalizedContent = response.content.replacingOccurrences(of: "\n", with: "")
        guard let data = Data(base64Encoded: normalizedContent),
              let markdown = String(data: data, encoding: .utf8) else {
            return ""
        }
        return markdown
    }

    private func fetchLatestCommits(repositoryFullName: String, token: String?) async throws -> [GitHubPortfolioCommit] {
        let endpoint = "https://api.github.com/repos/\(repositoryFullName)/commits?per_page=12"
        let responses: [GitHubCommitPortfolioResponse] = try await getJSON(endpoint: endpoint, token: token)
        return responses.map { response in
            GitHubPortfolioCommit(
                id: response.sha,
                message: response.commit.message.components(separatedBy: .newlines).first ?? response.commit.message,
                authorName: response.commit.author.name,
                committedAt: response.commit.author.date,
                url: response.htmlURL
            )
        }
    }

    private func getJSON<T: Decodable>(endpoint: String, token: String?) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw PortfolioError.invalidURL(endpoint)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Drona-Portfolio-macOS", forHTTPHeaderField: "User-Agent")
        if let token, !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PortfolioError.invalidResponse(endpoint: endpoint, statusCode: -1, payload: debugPayload(from: data))
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let payload = debugPayload(from: data)
            print("GitHub portfolio request failed: HTTP \(httpResponse.statusCode) \(endpoint) \(payload)")
            throw PortfolioError.invalidResponse(endpoint: endpoint, statusCode: httpResponse.statusCode, payload: payload)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    private func makeAnalytics(projects: [GitHubPortfolioProject]) -> GitHubPortfolioAnalytics {
        let languageTotals = Dictionary(grouping: projects.flatMap(\.languageBreakdown), by: \.name)
            .map { name, languages in
                GitHubPortfolioLanguage(
                    name: name,
                    bytes: languages.reduce(0) { $0 + $1.bytes },
                    colorHex: Self.languageColor(for: name),
                    percentage: 0
                )
            }
            .sorted { $0.bytes > $1.bytes }
        let totalLanguageBytes = max(languageTotals.reduce(0) { $0 + $1.bytes }, 1)
        let normalizedLanguages = languageTotals.map { language in
            GitHubPortfolioLanguage(
                name: language.name,
                bytes: language.bytes,
                colorHex: language.colorHex,
                percentage: Double(language.bytes) / Double(totalLanguageBytes)
            )
        }
        let mostActive = projects.max { $0.commitActivityScore < $1.commitActivityScore }?.name ?? "None"
        let longestMaintained = projects.max {
            $0.updatedAt.timeIntervalSince($0.createdAt) < $1.updatedAt.timeIntervalSince($1.createdAt)
        }?.name ?? "None"

        return GitHubPortfolioAnalytics(
            totalRepositories: projects.count,
            totalStars: projects.reduce(0) { $0 + $1.stars },
            totalForks: projects.reduce(0) { $0 + $1.forks },
            totalCommitsLoaded: projects.reduce(0) { $0 + $1.latestCommits.count },
            mostUsedLanguage: normalizedLanguages.first?.name ?? "None",
            mostActiveProject: mostActive,
            longestMaintainedProject: longestMaintained,
            languageBreakdown: normalizedLanguages
        )
    }

    private func debugPayload(from data: Data) -> String {
        String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
    }

    static func makeReadmeIntro(markdown: String, fallback: String?) -> String {
        let strippedLines = markdown
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                !line.isEmpty && !line.hasPrefix("!") && !line.hasPrefix("#") && !line.hasPrefix("[")
            }

        let intro = strippedLines.prefix(5).joined(separator: "\n")
        if intro.isEmpty {
            return fallback ?? "A public project from the DarkVeteran28 GitHub portfolio."
        }
        return String(intro.prefix(700))
    }

    static func languageColor(for language: String) -> String {
        switch language.lowercased() {
        case "swift": return "#F05138"
        case "python": return "#3572A5"
        case "javascript": return "#F1E05A"
        case "typescript": return "#3178C6"
        case "html": return "#E34C26"
        case "css": return "#563D7C"
        case "c++", "cpp": return "#F34B7D"
        case "java": return "#B07219"
        case "jupyter notebook": return "#DA5B0B"
        case "shell": return "#89E051"
        default: return "#7C8EA3"
        }
    }
}

private struct GitHubRepositoryPortfolioResponse: Decodable {
    var id: Int
    var name: String
    var fullName: String
    var description: String?
    var htmlURL: URL
    var homepageURL: URL?
    var language: String?
    var topics: [String]
    var stargazersCount: Int
    var forksCount: Int
    var watchersCount: Int
    var openIssuesCount: Int
    var size: Int
    var fork: Bool
    var archived: Bool
    var createdAt: Date
    var updatedAt: Date
    var pushedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case description
        case htmlURL = "html_url"
        case homepageURL = "homepage"
        case language
        case topics
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case watchersCount = "watchers_count"
        case openIssuesCount = "open_issues_count"
        case size
        case fork
        case archived
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case pushedAt = "pushed_at"
    }
}

private struct GitHubReadmeResponse: Decodable {
    var content: String
}

private struct GitHubCommitPortfolioResponse: Decodable {
    var sha: String
    var htmlURL: URL?
    var commit: GitHubCommitDetailResponse

    enum CodingKeys: String, CodingKey {
        case sha
        case htmlURL = "html_url"
        case commit
    }
}

private struct GitHubCommitDetailResponse: Decodable {
    var message: String
    var author: GitHubCommitAuthorResponse
}

private struct GitHubCommitAuthorResponse: Decodable {
    var name: String
    var date: Date
}
