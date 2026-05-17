import Foundation
import Combine

@MainActor
final class PortfolioManager: ObservableObject {
    @Published private(set) var snapshot: GitHubPortfolioSnapshot = .empty
    @Published private(set) var isSyncing = false
    @Published private(set) var lastError: String?
    @Published var searchText = ""
    @Published var selectedLanguage = "All"
    @Published var quickFilter: PortfolioQuickFilter = .all
    @Published var sortMode: PortfolioSortMode = .featured
    @Published var isAuthenticationPresented = false
    @Published private(set) var hasGitHubToken = false

    private let service = GitHubPortfolioService()
    private let tokenStore = GitHubTokenStore.shared
    private let storeURL: URL
    private let pinnedProjectsKey = "portfolio_pinned_projects"
    private let syncInterval: UInt64 = 20 * 60 * 1_000_000_000

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storeURL = documents.appendingPathComponent("githubPortfolio.json")
        hasGitHubToken = tokenStore.load() != nil
        load()
        publishPortfolioSummaryToWidgets()
    }

    var filteredProjects: [GitHubPortfolioProject] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var projects = snapshot.projects

        if selectedLanguage != "All" {
            projects = projects.filter { project in
                project.languageBreakdown.contains { $0.name == selectedLanguage } || project.primaryLanguage == selectedLanguage
            }
        }

        projects = projects.filter { matchesQuickFilter($0) }

        if !query.isEmpty {
            projects = projects.filter { project in
                project.name.lowercased().contains(query)
                || project.description.lowercased().contains(query)
                || project.topics.contains { $0.lowercased().contains(query) }
                || project.readmeIntro.lowercased().contains(query)
                || project.languageBreakdown.contains { $0.name.lowercased().contains(query) }
            }
        }

        return sort(projects)
    }

    var featuredProjects: [GitHubPortfolioProject] {
        snapshot.projects
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
                return lhs.showcaseScore > rhs.showcaseScore
            }
            .prefix(4)
            .map { $0 }
    }

    var availableLanguages: [String] {
        ["All"] + snapshot.analytics.languageBreakdown.map(\.name)
    }

    func syncPortfolio() async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            let token = tokenStore.load()
            hasGitHubToken = token != nil
            snapshot = try await service.fetchPortfolio(token: token, pinnedProjectNames: pinnedProjectNames)
            lastError = nil
            save()
            publishPortfolioSummaryToWidgets()
        } catch {
            print("Portfolio sync failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
            if snapshot.projects.isEmpty {
                isAuthenticationPresented = true
            }
        }
    }

    func runAutomaticSync() async {
        await syncPortfolio()

        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: syncInterval)
            await syncPortfolio()
        }
    }

    func saveGitHubToken(_ token: String) {
        do {
            try tokenStore.save(token)
            hasGitHubToken = true
            isAuthenticationPresented = false
            Task { await syncPortfolio() }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func disconnectGitHubToken() {
        tokenStore.delete()
        hasGitHubToken = false
        Task { await syncPortfolio() }
    }

    func togglePinned(_ project: GitHubPortfolioProject) {
        var names = pinnedProjectNames
        if names.contains(project.name) {
            names.remove(project.name)
        } else {
            names.insert(project.name)
        }
        UserDefaults.standard.set(Array(names), forKey: pinnedProjectsKey)

        snapshot.projects = snapshot.projects.map { existing in
            var copy = existing
            if existing.id == project.id {
                copy.isPinned.toggle()
            }
            return copy
        }
        save()
        publishPortfolioSummaryToWidgets()
    }

    private var pinnedProjectNames: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: pinnedProjectsKey) ?? [])
    }

    private func matchesQuickFilter(_ project: GitHubPortfolioProject) -> Bool {
        let searchable = ([project.name, project.description, project.primaryLanguage ?? ""] + project.topics + project.languageBreakdown.map(\.name))
            .joined(separator: " ")
            .lowercased()

        switch quickFilter {
        case .all:
            return true
        case .aiML:
            return searchable.contains("ai") || searchable.contains("ml") || searchable.contains("machine") || searchable.contains("neural") || searchable.contains("model")
        case .macOS:
            return searchable.contains("macos") || searchable.contains("swift") || searchable.contains("appkit") || searchable.contains("swiftui")
        case .python:
            return searchable.contains("python")
        case .swift:
            return searchable.contains("swift")
        case .web:
            return searchable.contains("web") || searchable.contains("html") || searchable.contains("css") || searchable.contains("javascript") || searchable.contains("typescript")
        }
    }

    private func sort(_ projects: [GitHubPortfolioProject]) -> [GitHubPortfolioProject] {
        switch sortMode {
        case .featured:
            return projects.sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
                return lhs.showcaseScore > rhs.showcaseScore
            }
        case .recentlyUpdated:
            return projects.sorted { $0.updatedAt > $1.updatedAt }
        case .mostActive:
            return projects.sorted { $0.commitActivityScore > $1.commitActivityScore }
        case .stars:
            return projects.sorted { $0.stars > $1.stars }
        case .name:
            return projects.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            print("Failed saving portfolio data: \(error.localizedDescription)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: storeURL)
            snapshot = try JSONDecoder().decode(GitHubPortfolioSnapshot.self, from: data)
        } catch {
            snapshot = .empty
        }
    }

    private func publishPortfolioSummaryToWidgets() {
        SharedDataProvider.shared.savePortfolioSummary(snapshot)
        WidgetRefreshManager.refreshAllWidgets(force: true)
    }
}
