import SwiftUI

struct AppUsageRow: View {
    var item: AppBreakdownItem

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(item.category.analysisColor)
                .frame(width: 8, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.appName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(item.category.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(formatHours(item.hours))
                    .font(.subheadline.monospacedDigit())

                Text(item.share.formatted(.percent.precision(.fractionLength(0))))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }

        return String(format: "%.1fh", hours)
    }
}
