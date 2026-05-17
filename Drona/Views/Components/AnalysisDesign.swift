import SwiftUI

extension ProductivityCategory {
    var label: String {
        switch self {
        case .productive:
            return "Productive"
        case .neutral:
            return "Neutral"
        case .distracting:
            return "Distracting"
        }
    }

    var analysisColor: Color {
        switch self {
        case .productive:
            return .green
        case .neutral:
            return .gray
        case .distracting:
            return .red
        }
    }
}

extension ContributionDay {
    var heatmapColor: Color {
        if isRestDay {
            return .blue
        }

        switch intensity {
        case 0:
            return Color.secondary.opacity(0.12)
        case 1:
            return .green.opacity(0.35)
        case 2:
            return .green.opacity(0.62)
        default:
            return .green.opacity(0.9)
        }
    }
}

extension Date {
    func formattedShortDay() -> String {
        formatted(.dateTime.month(.abbreviated).day())
    }
}

struct EmptyAnalysisState: View {
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }
}
