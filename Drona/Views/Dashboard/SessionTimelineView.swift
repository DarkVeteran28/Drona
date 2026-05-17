import SwiftUI

struct SessionTimelineView: View {
    var blocks: [SessionTimelineBlock]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                timelinePanel
            }
            .padding(24)
        }
        .navigationTitle("Session Timeline")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Timeline")
                .font(.largeTitle.weight(.semibold))

            Text("Current-day activity blocks prepared for future detailed session storage.")
                .foregroundStyle(.secondary)
        }
    }

    private var timelinePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.headline)

            if blocks.isEmpty {
                EmptyAnalysisState(title: "No sessions today", message: "The timeline fills as classified activity is tracked during the day.")
            } else {
                ForEach(blocks) { block in
                    HStack(spacing: 16) {
                        Text("\(block.startHour):00-\(block.endHour):00")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 96, alignment: .leading)

                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(block.category.analysisColor)
                            .frame(width: max(80, block.durationHours * 70), height: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.label)
                                .font(.subheadline.weight(.medium))

                            Text(String(format: "%.1fh tracked", block.durationHours))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
