import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settingsManager: SettingsManager
    var onComplete: () -> Void

    @State private var goalHours: Double
    @State private var strictness: EnforcementStrictness
    @State private var selectedStep = 0

    init(settingsManager: SettingsManager, onComplete: @escaping () -> Void) {
        self.settingsManager = settingsManager
        self.onComplete = onComplete
        _goalHours = State(initialValue: settingsManager.settings.productiveGoalHours)
        _strictness = State(initialValue: settingsManager.settings.enforcementStrictness)
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedStep) {
                onboardingPage(
                    systemImage: "hand.raised",
                    title: "Private by default",
                    message: "Drona tracks local app activity and focus history on this Mac. Your productivity data stays in your local storage unless you export it."
                )
                .tag(0)

                goalsPage
                    .tag(1)

                permissionsPage
                    .tag(2)
            }
            .tabViewStyle(.automatic)

            Divider()

            HStack {
                Button("Skip") {
                    complete()
                }
                .buttonStyle(.borderless)

                Spacer()

                Text("\(selectedStep + 1) of 3")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(selectedStep == 2 ? "Start Using Drona" : "Continue") {
                    if selectedStep == 2 {
                        complete()
                    } else {
                        selectedStep += 1
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
        }
        .frame(minWidth: 680, minHeight: 500)
    }

    private var goalsPage: some View {
        VStack(alignment: .leading, spacing: 22) {
            onboardingHeader(
                systemImage: "target",
                title: "Set a sustainable baseline",
                message: "Choose goals and enforcement that you can live with every day. You can tune everything later in Settings."
            )

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Daily productive goal")
                    Spacer()
                    Text(String(format: "%.1fh", goalHours))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $goalHours, in: 1...12, step: 0.5)

                Picker("Enforcement", selection: $strictness) {
                    ForEach(EnforcementStrictness.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            .dronaPanel()
        }
        .padding(36)
    }

    private var permissionsPage: some View {
        VStack(alignment: .leading, spacing: 22) {
            onboardingHeader(
                systemImage: "switch.2",
                title: "Enable only what helps",
                message: "For best results, allow accessibility or automation permissions when macOS asks. Widgets can be added from Notification Center."
            )

            VStack(alignment: .leading, spacing: 14) {
                permissionRow("Activity awareness", detail: "Used to identify the frontmost app for time tracking.")
                Divider()
                permissionRow("Focus enforcement", detail: "Used only to record and react to blocked apps you configure.")
                Divider()
                permissionRow("Widgets", detail: "Use shared local summaries for glanceable progress.")
            }
            .dronaPanel()
        }
        .padding(36)
    }

    private func onboardingPage(systemImage: String, title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            onboardingHeader(systemImage: systemImage, title: title, message: message)

            VStack(alignment: .leading, spacing: 14) {
                Label("No cloud account is required", systemImage: "icloud.slash")
                Label("Exports are controlled by you", systemImage: "square.and.arrow.up")
                Label("Settings can reduce tracking and enforcement friction", systemImage: "slider.horizontal.3")
            }
            .font(.body)
            .dronaPanel()
        }
        .padding(36)
    }

    private func onboardingHeader(systemImage: String, title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.green)

            Text(title)
                .font(.largeTitle.weight(.semibold))

            Text(message)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func permissionRow(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(detail)
                .foregroundStyle(.secondary)
        }
    }

    private func complete() {
        settingsManager.update { settings in
            settings.productiveGoalHours = goalHours
            settings.enforcementStrictness = strictness
        }
        onComplete()
    }
}
