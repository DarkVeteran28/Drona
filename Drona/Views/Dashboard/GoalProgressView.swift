import SwiftUI

struct GoalProgressView: View {
    var progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Goal Completion", systemImage: "target")
                    .font(.headline)
                Spacer()
                Text(progress.formatted(.percent.precision(.fractionLength(0))))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.green)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.secondary.opacity(0.14))
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * min(max(progress, 0), 1))
                }
            }
            .frame(height: 12)

            Text("Keep the day steady, not frantic.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .dronaPanel()
    }
}
