import SwiftUI

struct ProductivityScoreView: View {
    var score: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: scoreColor.opacity(0.18), radius: 18, x: 0, y: 10)

            Circle()
                .stroke(Color.secondary.opacity(0.16), lineWidth: 14)
                .padding(8)

            Circle()
                .trim(from: 0, to: min(score / 100, 1))
                .stroke(
                    LinearGradient(colors: [scoreColor, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(8)

            VStack(spacing: 4) {
                Text(String(format: "%.0f%%", score))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text("Score")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 150, height: 150)
    }

    private var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 50 { return .orange }
        return .red
    }
}
