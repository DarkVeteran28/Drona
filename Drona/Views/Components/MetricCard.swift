import SwiftUI

struct MetricCard: View {
    var title: String
    var value: String
    var detail: String
    var systemImage: String
    var tint: Color

    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(tint.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .monospacedDigit()

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(tint.opacity(0.22))
                .frame(width: 64, height: 64)
                .blur(radius: 18)
                .offset(x: 22, y: -22)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tint.opacity(isHovering ? 0.42 : 0.16), lineWidth: 1)
        }
        .shadow(color: tint.opacity(isHovering ? 0.18 : 0.08), radius: isHovering ? 20 : 12, x: 0, y: isHovering ? 12 : 8)
        .scaleEffect(isHovering ? 1.015 : 1)
        .animation(UXRefinementManager.shared.animation(reduceMotion: reduceMotion), value: isHovering)
        .onHover { isHovering = $0 }
    }
}
