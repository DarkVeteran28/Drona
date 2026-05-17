import SwiftUI

struct GitHubPortfolioView: View {
    @ObservedObject var portfolioManager: PortfolioManager
    @State private var selectedProject: GitHubPortfolioProject?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                authAndSyncBar
                analyticsGrid

                if !portfolioManager.featuredProjects.isEmpty {
                    featuredSection
                }

                technologySection
                filterBar
                projectGrid
            }
            .padding(24)
        }
        .navigationTitle("GitHub Showcase")
        .sheet(item: $selectedProject) { project in
            PortfolioProjectDetailView(project: project) {
                portfolioManager.togglePinned(project)
                selectedProject = nil
            }
            .frame(minWidth: 900, minHeight: 720)
        }
        .sheet(isPresented: $portfolioManager.isAuthenticationPresented) {
            GitHubPortfolioAuthView(portfolioManager: portfolioManager)
                .frame(width: 520)
        }
    }

    private var hero: some View {
        HStack(alignment: .bottom, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("DarkVeteran28")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text("Live developer portfolio powered by GitHub")
                            .foregroundStyle(.secondary)
                    }
                }

                Text("A polished showcase of public projects, README stories, technology choices, and current development momentum.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 760, alignment: .leading)
            }

            Spacer()

            Link(destination: GitHubPortfolioService.profileURL) {
                Label("Open GitHub", systemImage: "arrow.up.right")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(26)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.10, green: 0.18, blue: 0.30), Color(red: 0.10, green: 0.36, blue: 0.45), Color(red: 0.30, green: 0.20, blue: 0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .foregroundStyle(.white)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.18))
        }
    }

    private var authAndSyncBar: some View {
        HStack(spacing: 12) {
            Label(portfolioManager.hasGitHubToken ? "Authenticated GitHub sync" : "Public GitHub sync", systemImage: portfolioManager.hasGitHubToken ? "lock.shield.fill" : "network")
                .font(.headline)

            Text(lastSyncedText)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let error = portfolioManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                portfolioManager.isAuthenticationPresented = true
            } label: {
                Label(portfolioManager.hasGitHubToken ? "Update Token" : "Authenticate", systemImage: "key")
            }

            Button {
                Task { await portfolioManager.syncPortfolio() }
            } label: {
                if portfolioManager.isSyncing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Sync", systemImage: "arrow.clockwise")
                }
            }
            .disabled(portfolioManager.isSyncing)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        }
    }

    private var analyticsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5), spacing: 14) {
            MetricCard(title: "Repositories", value: "\(portfolioManager.snapshot.analytics.totalRepositories)", detail: "Public projects in the portfolio", systemImage: "folder.badge.gearshape", tint: .blue)
            MetricCard(title: "Top Language", value: portfolioManager.snapshot.analytics.mostUsedLanguage, detail: "Dominant technology by bytes", systemImage: "chevron.left.forwardslash.chevron.right", tint: .orange)
            MetricCard(title: "Most Active", value: portfolioManager.snapshot.analytics.mostActiveProject, detail: "Recent commit momentum", systemImage: "bolt.fill", tint: .green)
            MetricCard(title: "Commits", value: "\(portfolioManager.snapshot.analytics.totalCommitsLoaded)", detail: "Latest commits loaded across repos", systemImage: "point.3.connected.trianglepath.dotted", tint: .purple)
            MetricCard(title: "Stars", value: "\(portfolioManager.snapshot.analytics.totalStars)", detail: "Public recognition", systemImage: "star.fill", tint: .yellow)
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Featured Projects")
                    .font(.title2.weight(.bold))
                Spacer()
                Text("Pinned and highest-signal repositories")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(portfolioManager.featuredProjects) { project in
                        FeaturedProjectCard(project: project) {
                            selectedProject = project
                        }
                        .frame(width: 430)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var technologySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Technology Map")
                .font(.title2.weight(.bold))

            if portfolioManager.snapshot.analytics.languageBreakdown.isEmpty {
                EmptyAnalysisState(title: "No language data", message: "Sync GitHub to build the portfolio technology map.")
            } else {
                VStack(spacing: 10) {
                    ForEach(portfolioManager.snapshot.analytics.languageBreakdown.prefix(8)) { language in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: language.colorHex))
                                .frame(width: 10, height: 10)
                            Text(language.name)
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 140, alignment: .leading)
                            ProgressView(value: language.percentage)
                                .tint(Color(hex: language.colorHex))
                            Text(language.percentage.formatted(.percent.precision(.fractionLength(0))))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 42, alignment: .trailing)
                        }
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search projects, README text, topics, or technologies", text: $portfolioManager.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 12) {
                Picker("Filter", selection: $portfolioManager.quickFilter) {
                    ForEach(PortfolioQuickFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 520)

                Picker("Language", selection: $portfolioManager.selectedLanguage) {
                    ForEach(portfolioManager.availableLanguages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .frame(width: 180)

                Picker("Sort", selection: $portfolioManager.sortMode) {
                    ForEach(PortfolioSortMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .frame(width: 190)

                Spacer()
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var projectGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 16)], spacing: 16) {
            ForEach(portfolioManager.filteredProjects) { project in
                PortfolioProjectCard(project: project) {
                    selectedProject = project
                } pinAction: {
                    portfolioManager.togglePinned(project)
                }
            }
        }
        .animation(.snappy(duration: 0.22), value: portfolioManager.filteredProjects.map(\.id))
    }

    private var lastSyncedText: String {
        guard portfolioManager.snapshot.fetchedAt > Date.distantPast else {
            return "Not synced yet"
        }
        return "Updated \(portfolioManager.snapshot.fetchedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))"
    }
}

private struct FeaturedProjectCard: View {
    var project: GitHubPortfolioProject
    var action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    ProjectIcon(project: project, size: 52)
                    Spacer()
                    if project.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(.yellow)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(project.name)
                        .font(.title2.weight(.bold))
                        .lineLimit(1)
                    Text(project.readmeIntro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }

                LanguagePills(project: project, limit: 4)
                ProjectStatsRow(project: project)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 280, alignment: .leading)
            .background(projectGradient(for: project), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(hovering ? 0.36 : 0.14))
            }
            .shadow(color: dominantColor.opacity(hovering ? 0.28 : 0.12), radius: hovering ? 26 : 14, x: 0, y: hovering ? 16 : 8)
            .scaleEffect(hovering ? 1.018 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.snappy(duration: 0.18), value: hovering)
    }

    private var dominantColor: Color {
        Color(hex: project.languageBreakdown.first?.colorHex ?? "#3178C6")
    }
}

private struct PortfolioProjectCard: View {
    var project: GitHubPortfolioProject
    var action: () -> Void
    var pinAction: () -> Void
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        ProjectIcon(project: project, size: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.name)
                                .font(.headline.weight(.bold))
                                .lineLimit(1)
                            Text(project.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }

                    Text(project.readmeIntro)
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.82))
                        .lineLimit(4)
                        .frame(minHeight: 72, alignment: .topLeading)

                    LanguagePills(project: project, limit: 5)
                    ActivityIndicator(project: project)
                    ProjectStatsRow(project: project)
                }
            }
            .buttonStyle(.plain)

            HStack {
                Button {
                    pinAction()
                } label: {
                    Label(project.isPinned ? "Pinned" : "Pin", systemImage: project.isPinned ? "pin.fill" : "pin")
                }
                .buttonStyle(.borderless)

                Spacer()

                Text("Updated \(project.updatedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 330, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(hex: project.languageBreakdown.first?.colorHex ?? "#3178C6").opacity(0.18))
                .frame(width: 88, height: 88)
                .blur(radius: 22)
                .offset(x: 28, y: -26)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(hex: project.languageBreakdown.first?.colorHex ?? "#3178C6").opacity(hovering ? 0.42 : 0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(hovering ? 0.16 : 0.08), radius: hovering ? 20 : 10, x: 0, y: hovering ? 12 : 6)
        .scaleEffect(hovering ? 1.012 : 1)
        .onHover { hovering = $0 }
        .animation(.snappy(duration: 0.18), value: hovering)
    }
}

private struct PortfolioProjectDetailView: View {
    var project: GitHubPortfolioProject
    var pinAction: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                detailHero

                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 20) {
                        readmeSection
                        commitsSection
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 16) {
                        detailStats
                        languageBreakdown
                        topicsSection
                    }
                    .frame(width: 300)
                }
            }
            .padding(26)
        }
    }

    private var detailHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                ProjectIcon(project: project, size: 64)
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.name)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text(project.description)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button("Done") { dismiss() }
            }

            HStack(spacing: 12) {
                Link(destination: project.htmlURL) {
                    Label("Repository", systemImage: "arrow.up.right")
                }
                .buttonStyle(.borderedProminent)

                if let homepage = project.homepageURL, homepage.absoluteString.isEmpty == false {
                    Link(destination: homepage) {
                        Label("Live Link", systemImage: "safari")
                    }
                }

                Button(action: pinAction) {
                    Label(project.isPinned ? "Unpin" : "Pin Project", systemImage: project.isPinned ? "pin.slash" : "pin")
                }
            }
        }
        .padding(24)
        .background(projectGradient(for: project), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.18))
        }
    }

    private var readmeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("README Showcase")
                .font(.title2.weight(.bold))
            MarkdownRenderer(markdown: project.readmeMarkdown.isEmpty ? project.description : project.readmeMarkdown, baseURL: project.htmlURL)
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var commitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Latest Activity")
                .font(.title2.weight(.bold))
            if project.latestCommits.isEmpty {
                EmptyAnalysisState(title: "No commits loaded", message: "Authenticate or sync again to fetch commit activity.")
            } else {
                ForEach(project.latestCommits) { commit in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "smallcircle.filled.circle")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(commit.message)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(2)
                            Text("\(commit.authorName) · \(commit.committedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var detailStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repository Stats")
                .font(.headline)
            StatLine(label: "Stars", value: "\(project.stars)", image: "star.fill")
            StatLine(label: "Forks", value: "\(project.forks)", image: "tuningfork")
            StatLine(label: "Issues", value: "\(project.openIssues)", image: "exclamationmark.circle")
            StatLine(label: "Size", value: "\(project.sizeKB) KB", image: "externaldrive")
            StatLine(label: "Activity", value: "\(project.commitActivityScore)", image: "bolt.fill")
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var languageBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Technologies")
                .font(.headline)
            ForEach(project.languageBreakdown.prefix(8)) { language in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Circle().fill(Color(hex: language.colorHex)).frame(width: 8, height: 8)
                        Text(language.name).font(.caption.weight(.semibold))
                        Spacer()
                        Text(language.percentage.formatted(.percent.precision(.fractionLength(0))))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: language.percentage)
                        .tint(Color(hex: language.colorHex))
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
            if project.topics.isEmpty {
                Text("No topics published")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(project.topics, id: \.self) { topic in
                        Text(topic)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.blue.opacity(0.14), in: Capsule())
                    }
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct GitHubPortfolioAuthView: View {
    @ObservedObject var portfolioManager: PortfolioManager
    @Environment(\.dismiss) private var dismiss
    @State private var token = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("GitHub Authentication")
                .font(.title2.weight(.bold))
            Text("Add a GitHub personal access token to raise API limits and unlock authenticated repository, README, language, and commit syncing. The token is stored in Keychain.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            SecureField("GitHub token", text: $token)
                .textFieldStyle(.roundedBorder)

            Link("Create a fine-grained token on GitHub", destination: URL(string: "https://github.com/settings/personal-access-tokens")!)
                .font(.caption)

            HStack {
                if portfolioManager.hasGitHubToken {
                    Button("Disconnect") {
                        portfolioManager.disconnectGitHubToken()
                        dismiss()
                    }
                }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save & Sync") {
                    portfolioManager.saveGitHubToken(token)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
    }
}

private struct ProjectIcon: View {
    var project: GitHubPortfolioProject
    var size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(Color(hex: project.languageBreakdown.first?.colorHex ?? "#3178C6").gradient)
            Image(systemName: iconName)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    private var iconName: String {
        let searchable = ([project.name, project.description, project.primaryLanguage ?? ""] + project.topics).joined(separator: " ").lowercased()
        if searchable.contains("ai") || searchable.contains("ml") { return "brain.head.profile" }
        if searchable.contains("bot") { return "cpu" }
        if searchable.contains("map") || searchable.contains("algorithm") { return "point.3.connected.trianglepath.dotted" }
        if searchable.contains("web") { return "globe" }
        if searchable.contains("swift") || searchable.contains("macos") { return "macwindow" }
        return "chevron.left.forwardslash.chevron.right"
    }
}

private func projectGradient(for project: GitHubPortfolioProject) -> LinearGradient {
    LinearGradient(
        colors: [
            Color(hex: project.languageBreakdown.first?.colorHex ?? "#3178C6").opacity(0.24),
            Color(red: 0.08, green: 0.11, blue: 0.17).opacity(0.92),
            Color(hex: project.languageBreakdown.dropFirst().first?.colorHex ?? "#7C8EA3").opacity(0.22)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private struct LanguagePills: View {
    var project: GitHubPortfolioProject
    var limit: Int

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(project.languageBreakdown.prefix(limit))) { language in
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: language.colorHex))
                        .frame(width: 6, height: 6)
                    Text(language.name)
                }
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color(hex: language.colorHex).opacity(0.15), in: Capsule())
            }
        }
    }
}

private struct ProjectStatsRow: View {
    var project: GitHubPortfolioProject

    var body: some View {
        HStack(spacing: 12) {
            Label("\(project.stars)", systemImage: "star.fill")
            Label("\(project.forks)", systemImage: "tuningfork")
            Label("\(project.latestCommits.count)", systemImage: "clock.arrow.circlepath")
            Spacer(minLength: 0)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }
}

private struct ActivityIndicator: View {
    var project: GitHubPortfolioProject

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(index < project.commitActivityScore ? .green : .secondary.opacity(0.18))
                    .frame(width: 10, height: CGFloat(8 + min(index, 6)))
            }
            Spacer()
            Text("activity")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StatLine: View {
    var label: String
    var value: String
    var image: String

    var body: some View {
        HStack {
            Label(label, systemImage: image)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
        }
    }
}

