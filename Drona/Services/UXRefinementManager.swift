import SwiftUI

struct UXRefinementManager {
    static let shared = UXRefinementManager()

    let panelCornerRadius: CGFloat = 18
    let pagePadding: CGFloat = 28
    let sectionSpacing: CGFloat = 22

    func animation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.86)
    }
}

struct DronaPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: UXRefinementManager.shared.panelCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: UXRefinementManager.shared.panelCornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

struct DronaPageBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.12),
                            Color.cyan.opacity(0.08),
                            Color.indigo.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
            }
    }
}

struct DronaHeroCard<Content: View>: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var score: Double?
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: systemImage)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .labelStyle(.titleAndIcon)
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
                content
            }

            Spacer(minLength: 12)

            if let score {
                DronaScoreBadge(score: score)
            }
        }
        .foregroundStyle(.white)
        .padding(26)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.95), Color.cyan.opacity(0.82), Color.indigo.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 220, height: 220)
                        .blur(radius: 26)
                        .offset(x: 72, y: -108)
                }
        }
        .shadow(color: .green.opacity(0.22), radius: 24, x: 0, y: 14)
    }
}

struct DronaScoreBadge: View {
    var score: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.20), lineWidth: 14)
            Circle()
                .trim(from: 0, to: min(max(score / 100, 0), 1))
                .stroke(.white, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(String(format: "%.0f%%", score))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("Score")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .frame(width: 142, height: 142)
    }
}

extension View {
    func dronaPanel() -> some View {
        modifier(DronaPanelModifier())
    }

    func dronaPageBackground() -> some View {
        modifier(DronaPageBackground())
    }
}
