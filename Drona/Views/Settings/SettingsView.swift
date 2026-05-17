import SwiftUI

struct SettingsView: View {
    @ObservedObject var goalManager: GoalManager
    @ObservedObject var startupManager: StartupManager
    var tracker: ActivityTracker

    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var backupManager = BackupManager()
    @State private var selectedCategory = SettingsCategory.general

    var body: some View {
        HStack(spacing: 0) {
            List(SettingsCategory.allCases, selection: $selectedCategory) { category in
                Label(category.title, systemImage: category.systemImage)
                    .tag(category)
            }
            .frame(width: 210)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    categoryView
                }
                .padding(24)
                .frame(maxWidth: 860, alignment: .leading)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            goalManager.productiveGoalHours = settingsManager.settings.productiveGoalHours
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedCategory.title)
                .font(.largeTitle.weight(.semibold))
            Text(selectedCategory.subtitle)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var categoryView: some View {
        switch selectedCategory {
        case .general:
            generalPanel
        case .tracking:
            trackingPanel
        case .enforcement:
            enforcementPanel
        case .widgets:
            widgetsPanel
        case .goals:
            goalsPanel
        case .restMode:
            restModePanel
        case .boostMode:
            boostModePanel
        case .privacy:
            privacyPanel
        case .systemHealth:
            systemPanel
        }
    }

    private var generalPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Launch at login", isOn: Binding(
                get: { startupManager.isLaunchAtLoginEnabled },
                set: { startupManager.setLaunchAtLogin($0) }
            ))

            Toggle("Battery-saving mode", isOn: binding(\.batterySavingMode))
                .onChange(of: settingsManager.settings.batterySavingMode) { _, _ in tracker.applyRuntimeSettings() }

            Picker("Logging verbosity", selection: Binding(
                get: { UserDefaults.standard.string(forKey: "loggingVerbosity") ?? LogLevel.info.rawValue },
                set: { UserDefaults.standard.set($0, forKey: "loggingVerbosity") }
            )) {
                ForEach(LogLevel.allCases, id: \.rawValue) { level in
                    Text(level.rawValue).tag(level.rawValue)
                }
            }

            if let error = startupManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .dronaPanel()
    }

    private var trackingPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Tracking sensitivity", selection: binding(\.trackingSensitivity)) {
                ForEach(TrackingSensitivity.allCases) { sensitivity in
                    Text(sensitivity.title).tag(sensitivity)
                }
            }
            .pickerStyle(.segmented)

            settingSlider(title: "Tracking frequency", value: binding(\.trackingFrequencySeconds), range: 1...15, suffix: "s")
                .onChange(of: settingsManager.settings.trackingFrequencySeconds) { _, _ in tracker.applyRuntimeSettings() }

            settingSlider(title: "Autosave frequency", value: binding(\.autosaveFrequencySeconds), range: 15...300, suffix: "s")
                .onChange(of: settingsManager.settings.autosaveFrequencySeconds) { _, _ in tracker.applyRuntimeSettings() }

            editableListPanel(title: "Productive Apps", systemImage: "checkmark.circle", text: binding(\.productiveAppsText))
            editableListPanel(title: "Distracting Apps", systemImage: "minus.circle", text: binding(\.distractingAppsText))
        }
    }

    private var enforcementPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle("Enable focus enforcement", isOn: binding(\.enforcementEnabled))

            Picker("Strictness", selection: binding(\.enforcementStrictness)) {
                ForEach(EnforcementStrictness.allCases) { strictness in
                    Text(strictness.title).tag(strictness)
                }
            }
            .pickerStyle(.segmented)

            Text("Gentle reduces repeated warnings, Balanced limits impulsive loops, and Strict records attempts more aggressively.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 20) {
                editableListPanel(title: "Blocked Apps", systemImage: "app.badge", text: binding(\.blockedAppsText))
                editableListPanel(title: "Blocked Websites", systemImage: "network.badge.shield.half.filled", text: binding(\.blockedWebsitesText))
            }
        }
    }

    private var widgetsPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle("Productivity widget", isOn: binding(\.showProductivityWidget))
            Toggle("Contribution widget", isOn: binding(\.showContributionWidget))
            Toggle("Streak widget", isOn: binding(\.showStreakWidget))
            Toggle("Status widget", isOn: binding(\.showStatusWidget))
            settingSlider(title: "Widget refresh frequency", value: binding(\.widgetRefreshFrequencySeconds), range: 60...900, suffix: "s")

            Button {
                WidgetRefreshManager.refreshAllWidgets(force: true)
            } label: {
                Label("Refresh Widgets Now", systemImage: "arrow.clockwise")
            }
        }
        .dronaPanel()
    }

    private var goalsPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingSlider(title: "Daily productive goal", value: binding(\.productiveGoalHours), range: 1...12, suffix: "h")
                .onChange(of: settingsManager.settings.productiveGoalHours) { _, value in
                    goalManager.productiveGoalHours = value
                }

            settingSlider(title: "Minimum healthy score", value: binding(\.minimumProductivityScore), range: 40...95, suffix: "%")
            settingSlider(title: "Deep work threshold", value: binding(\.deepWorkThresholdHours), range: 1...8, suffix: "h")
        }
        .dronaPanel()
    }

    private var restModePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Stepper("Rest starts at \(settingsManager.settings.restModeStartHour):00", value: binding(\.restModeStartHour), in: 0...23)
            Stepper("Rest ends at \(settingsManager.settings.restModeEndHour):00", value: binding(\.restModeEndHour), in: 0...23)
            Text("Rest Mode should protect recovery without turning evenings into another optimization target.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .dronaPanel()
    }

    private var boostModePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Boost intensity", selection: binding(\.boostModeIntensity)) {
                ForEach(BoostModeIntensity.allCases) { intensity in
                    Text(intensity.title).tag(intensity)
                }
            }
            .pickerStyle(.segmented)

            Text("Use stronger boost settings for planned deep work blocks, not as a permanent daily mode.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .dronaPanel()
    }

    private var privacyPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Local-first data", systemImage: "lock.shield")
                .font(.headline)
            Text("Drona stores app usage, daily summaries, violations, logs, and settings on this Mac. Exports and backups are created only when you request them.")
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 12) {
                Button {
                    backupManager.exportJSON(
                        appUsages: tracker.trackedApps,
                        summaries: tracker.ruleEngine.historyManager.summaries,
                        violations: tracker.focusMonitor.logger.violations,
                        settings: settingsManager.settings
                    )
                } label: {
                    Label("Export JSON", systemImage: "doc.badge.gearshape")
                }

                Button {
                    backupManager.exportCSV(
                        appUsages: tracker.trackedApps,
                        summaries: tracker.ruleEngine.historyManager.summaries
                    )
                } label: {
                    Label("Export CSV", systemImage: "tablecells")
                }

                Button {
                    backupManager.createBackup()
                } label: {
                    Label("Create Backup", systemImage: "externaldrive")
                }

                Button {
                    backupManager.restoreBackup()
                } label: {
                    Label("Restore", systemImage: "arrow.counterclockwise")
                }
            }

            if let status = backupManager.lastStatus {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .dronaPanel()
    }

    private var systemPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button {
                OnboardingManager.shared.reset()
            } label: {
                Label("Show Onboarding Again", systemImage: "sparkles")
            }

            Button(role: .destructive) {
                settingsManager.resetToDefaults()
                goalManager.productiveGoalHours = settingsManager.settings.productiveGoalHours
                tracker.applyRuntimeSettings()
            } label: {
                Label("Reset Settings", systemImage: "arrow.uturn.backward")
            }
        }
        .dronaPanel()
    }

    private func editableListPanel(title: String, systemImage: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            TextEditor(text: text)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 150)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.background, in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text("One entry per line")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dronaPanel()
    }

    private func settingSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.0f%@", value.wrappedValue, suffix))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 1)
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding {
            settingsManager.settings[keyPath: keyPath]
        } set: { value in
            settingsManager.update { settings in
                settings[keyPath: keyPath] = value
            }
        }
    }
}

private enum SettingsCategory: String, CaseIterable, Identifiable {
    case general
    case tracking
    case enforcement
    case widgets
    case goals
    case restMode
    case boostMode
    case privacy
    case systemHealth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .tracking: return "Tracking"
        case .enforcement: return "Enforcement"
        case .widgets: return "Widgets"
        case .goals: return "Goals"
        case .restMode: return "Rest Mode"
        case .boostMode: return "Boost Mode"
        case .privacy: return "Privacy"
        case .systemHealth: return "System Health"
        }
    }

    var subtitle: String {
        switch self {
        case .general: return "Everyday app behavior and reliability preferences."
        case .tracking: return "How Drona observes activity and classifies focus."
        case .enforcement: return "Friction that blocks impulsive distraction without becoming hostile."
        case .widgets: return "Glanceable progress surfaces for macOS."
        case .goals: return "Sustainable targets and productivity thresholds."
        case .restMode: return "Recovery boundaries for long-term consistency."
        case .boostMode: return "Temporary deep-work intensity controls."
        case .privacy: return "Local data, exports, backups, and restore controls."
        case .systemHealth: return "Maintenance actions and setup reset controls."
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .tracking: return "scope"
        case .enforcement: return "shield"
        case .widgets: return "rectangle.grid.2x2"
        case .goals: return "target"
        case .restMode: return "moon"
        case .boostMode: return "bolt"
        case .privacy: return "lock.shield"
        case .systemHealth: return "heart.text.square"
        }
    }
}
