import SwiftUI

struct SystemHealthView: View {
    @ObservedObject var healthManager: SystemHealthManager
    @ObservedObject var startupManager: StartupManager
    @ObservedObject var loggingManager: LoggingManager
    var tracker: ActivityTracker

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                controlsPanel
                healthGrid
                performancePanel
                logsPanel
            }
            .padding(24)
        }
        .navigationTitle("System Health")
        .onAppear {
            startupManager.refreshStatus()
            healthManager.refresh(tracker: tracker)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System Health")
                .font(.largeTitle.weight(.semibold))

            Text("Runtime reliability, persistence, permissions, resource usage, and recovery state.")
                .foregroundStyle(.secondary)
        }
    }

    private var controlsPanel: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Launch at Login")
                    .font(.headline)

                Text(startupManager.statusDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("Enabled", isOn: Binding(
                get: { startupManager.isLaunchAtLoginEnabled },
                set: { startupManager.setLaunchAtLogin($0) }
            ))
            .toggleStyle(.switch)

            Button {
                healthManager.refresh(tracker: tracker)
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var healthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
            HealthCard(item: healthManager.snapshot.tracking)
            HealthCard(item: healthManager.snapshot.enforcement)
            HealthCard(item: healthManager.snapshot.database)
            HealthCard(item: healthManager.snapshot.permissions)
            HealthCard(item: healthManager.snapshot.widgets)
            HealthCard(item: healthManager.snapshot.persistence)
        }
    }

    private var performancePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Performance")
                .font(.headline)

            HStack(spacing: 14) {
                MetricCard(
                    title: "Memory",
                    value: String(format: "%.0f MB", healthManager.snapshot.performance.memoryMegabytes),
                    detail: "Resident memory estimate",
                    systemImage: "memorychip",
                    tint: .blue
                )

                MetricCard(
                    title: "Tracking Interval",
                    value: String(format: "%.0fs", healthManager.snapshot.performance.trackingInterval),
                    detail: healthManager.snapshot.performance.batterySavingMode ? "Battery saving adjusted" : "Current tracking cadence",
                    systemImage: "timer",
                    tint: .green
                )

                MetricCard(
                    title: "Low Power",
                    value: healthManager.snapshot.performance.lowPowerMode ? "On" : "Off",
                    detail: "System low power mode",
                    systemImage: "battery.75percent",
                    tint: .orange
                )
            }
        }
    }

    private var logsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent System Logs")
                .font(.headline)

            if loggingManager.entries.isEmpty {
                EmptyAnalysisState(title: "No logs yet", message: "System events, recovery actions, and persistence failures appear here.")
            } else {
                ForEach(loggingManager.entries.prefix(8)) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Text(entry.level.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(color(for: entry.level))
                            .frame(width: 64, alignment: .leading)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(entry.subsystem): \(entry.message)")
                                .font(.subheadline)
                                .lineLimit(2)

                            Text(entry.timestamp.formatted(.dateTime.month(.abbreviated).day().hour().minute().second()))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func color(for level: LogLevel) -> Color {
        switch level {
        case .debug: return .secondary
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

private struct HealthCard: View {
    var item: HealthItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(color)

                Spacer()

                Text(item.state.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(color)
            }

            Text(item.title)
                .font(.headline)

            Text(item.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer()

            Text(item.checkedAt.formatted(.dateTime.hour().minute().second()))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var iconName: String {
        switch item.state {
        case .healthy: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .failed: return "xmark.octagon"
        case .unknown: return "questionmark.circle"
        }
    }

    private var color: Color {
        switch item.state {
        case .healthy: return .green
        case .warning: return .orange
        case .failed: return .red
        case .unknown: return .secondary
        }
    }
}
