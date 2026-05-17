import SwiftUI

struct WidgetCustomizationView: View {
    @StateObject private var themeManager = WidgetThemeManager.shared
    @State private var selectedWidget: WidgetStyleKind = .productivity
    @State private var applyPresetToAll = false

    var body: some View {
        HStack(spacing: 0) {
            widgetSidebar
                .frame(width: 220)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    presetSection
                    previewSection
                    editorSection
                }
                .padding(28)
            }
        }
        .dronaPageBackground()
        .navigationTitle("Widget Studio")
    }

    private var widgetSidebar: some View {
        List(WidgetStyleKind.allCases, selection: $selectedWidget) { kind in
            Label(kind.title, systemImage: kind.systemImage)
                .tag(kind)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button {
                    themeManager.exportTheme()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .frame(maxWidth: .infinity)

                Button {
                    themeManager.importTheme()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .frame(maxWidth: .infinity)

                if let status = themeManager.lastStatus {
                    Text(status)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .buttonStyle(.bordered)
            .padding(12)
        }
    }

    private var header: some View {
        DronaHeroCard(
            title: "Widget Studio",
            subtitle: "Design colorful macOS widgets, preview every size, and sync the style to WidgetKit instantly.",
            systemImage: "paintpalette.fill",
            score: nil
        ) {
            HStack(spacing: 10) {
                studioPill("Editing", selectedWidget.title)
                studioPill("Presets", "\(WidgetThemePreset.presets.count)")
                studioPill("Sync", "Live")
            }
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Preset Themes")
                    .font(.title2.weight(.bold))
                Spacer()
                Toggle("Apply to all widgets", isOn: $applyPresetToAll)
                    .toggleStyle(.switch)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 14)], spacing: 14) {
                ForEach(WidgetThemePreset.presets) { preset in
                    Button {
                        themeManager.applyPreset(preset, to: applyPresetToAll ? nil : selectedWidget)
                    } label: {
                        PresetThemeCard(preset: preset)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Live Preview")
                .font(.title2.weight(.bold))

            HStack(alignment: .top, spacing: 18) {
                WidgetPreviewRenderer(kind: selectedWidget, family: .small, style: style, summary: .demo)
                WidgetPreviewRenderer(kind: selectedWidget, family: .medium, style: style, summary: .demo)
                WidgetPreviewRenderer(kind: selectedWidget, family: .large, style: style, summary: .demo)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var editorSection: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 18) {
                backgroundPanel
                colorPanel
                contributionPanel
            }

            VStack(alignment: .leading, spacing: 18) {
                typographyPanel
                cardPanel
                animationPanel
            }
        }
    }

    private var backgroundPanel: some View {
        editorPanel(title: "Background", systemImage: "rectangle.fill.on.rectangle.fill") {
            Picker("Style", selection: binding(\.backgroundStyle)) {
                ForEach(WidgetBackgroundStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }

            colorPicker("Gradient start", keyPath: \.gradientStart)
            colorPicker("Gradient middle", keyPath: \.gradientMiddle)
            colorPicker("Gradient end", keyPath: \.gradientEnd)
            slider("Gradient angle", keyPath: \.gradientAngle, range: 0...360, suffix: "deg")
        }
    }

    private var colorPanel: some View {
        editorPanel(title: "Colors", systemImage: "eyedropper.halffull") {
            colorPicker("Primary text", keyPath: \.primaryText)
            colorPicker("Secondary text", keyPath: \.secondaryText)
            colorPicker("Accent", keyPath: \.accent)
            colorPicker("Border", keyPath: \.borderColor)
        }
    }

    private var typographyPanel: some View {
        editorPanel(title: "Typography", systemImage: "textformat") {
            Picker("Design", selection: binding(\.typography)) {
                ForEach(WidgetTypographyDesign.allCases) { design in
                    Text(design.title).tag(design)
                }
            }
            .pickerStyle(.segmented)

            Picker("Weight", selection: binding(\.fontWeight)) {
                ForEach(WidgetFontWeightOption.allCases) { weight in
                    Text(weight.title).tag(weight)
                }
            }

            slider("Font scale", keyPath: \.fontScale, range: 0.8...1.35, suffix: "x")
        }
    }

    private var cardPanel: some View {
        editorPanel(title: "Card Style", systemImage: "rectangle.roundedtop") {
            slider("Corner radius", keyPath: \.cornerRadius, range: 8...32, suffix: "px")
            slider("Border thickness", keyPath: \.borderThickness, range: 0...4, suffix: "px")
            slider("Shadow", keyPath: \.shadowIntensity, range: 0...1, suffix: "")
            slider("Glow", keyPath: \.glowIntensity, range: 0...1, suffix: "")
            slider("Padding", keyPath: \.padding, range: 10...24, suffix: "px")
        }
    }

    private var contributionPanel: some View {
        editorPanel(title: "Contribution Graph", systemImage: "square.grid.3x3.fill") {
            colorPicker("Low intensity", keyPath: \.heatmapLow)
            colorPicker("Medium intensity", keyPath: \.heatmapMedium)
            colorPicker("High intensity", keyPath: \.heatmapHigh)
            colorPicker("Rest day", keyPath: \.restDayColor)
            slider("Grid spacing", keyPath: \.gridSpacing, range: 2...8, suffix: "px")
            slider("Cell radius", keyPath: \.cellRadius, range: 0...6, suffix: "px")
        }
    }

    private var animationPanel: some View {
        editorPanel(title: "Motion", systemImage: "sparkles") {
            Toggle("Progress animations", isOn: binding(\.animationsEnabled))
            Toggle("Hover glow", isOn: binding(\.hoverGlowEnabled))
            Toggle("Pulse effects", isOn: binding(\.pulseEffectsEnabled))
        }
    }

    private var style: SharedWidgetStyleModel {
        themeManager.style(for: selectedWidget)
    }

    private func editorPanel<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dronaPanel()
    }

    private func colorPicker(_ title: String, keyPath: WritableKeyPath<SharedWidgetStyleModel, RGBAColor>) -> some View {
        ColorPicker(title, selection: Binding {
            style[keyPath: keyPath].color
        } set: { color in
            themeManager.updateStyle(for: selectedWidget) { style in
                style[keyPath: keyPath] = RGBAColor(color: color)
            }
        })
    }

    private func slider(_ title: String, keyPath: WritableKeyPath<SharedWidgetStyleModel, Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(valueLabel(style[keyPath: keyPath], suffix: suffix))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: Binding {
                style[keyPath: keyPath]
            } set: { value in
                themeManager.updateStyle(for: selectedWidget) { style in
                    style[keyPath: keyPath] = value
                }
            }, in: range)
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<SharedWidgetStyleModel, Value>) -> Binding<Value> {
        Binding {
            style[keyPath: keyPath]
        } set: { value in
            themeManager.updateStyle(for: selectedWidget) { style in
                style[keyPath: keyPath] = value
            }
        }
    }

    private func valueLabel(_ value: Double, suffix: String) -> String {
        suffix == "x" ? String(format: "%.2f%@", value, suffix) : String(format: "%.0f%@", value, suffix)
    }

    private func studioPill(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.caption.weight(.bold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct WidgetPreviewRenderer: View {
    enum PreviewFamily: String, CaseIterable, Identifiable {
        case small
        case medium
        case large

        var id: String { rawValue }
        var title: String { rawValue.capitalized }
        var size: CGSize {
            switch self {
            case .small: return CGSize(width: 160, height: 160)
            case .medium: return CGSize(width: 338, height: 160)
            case .large: return CGSize(width: 338, height: 354)
            }
        }
    }

    var kind: WidgetStyleKind
    var family: PreviewFamily
    var style: SharedWidgetStyleModel
    var summary: WidgetPreviewSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(family.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            previewContent
                .frame(width: family.size.width, height: family.size.height, alignment: .topLeading)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                        .stroke(style.borderColor.color, lineWidth: style.borderThickness)
                }
                .shadow(color: style.accent.color.opacity(style.shadowIntensity), radius: 18 * style.shadowIntensity, x: 0, y: 12 * style.shadowIntensity)
        }
    }

    private var previewContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: kind.systemImage)
                Text(kind.title.uppercased())
                    .tracking(0.8)
                Spacer()
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(style.secondaryText.color)

            switch kind {
            case .productivity:
                previewProductivity
            case .status:
                previewStatus
            case .streak:
                previewStreak
            case .goal:
                previewGoal
            case .contribution:
                previewContribution
            case .rest:
                previewRest
            }
        }
        .padding(style.padding)
        .foregroundStyle(style.primaryText.color)
        .font(.system(size: 13 * style.fontScale, weight: fontWeight, design: fontDesign))
    }

    private var previewProductivity: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("84%")
                .font(.system(size: (family == .small ? 38 : 46) * style.fontScale, weight: fontWeight, design: fontDesign))
                .monospacedDigit()
            Text("5.4h focused")
                .foregroundStyle(style.secondaryText.color)
            if family != .small {
                HStack {
                    previewPill("Deep", "5.4h")
                    previewPill("Drift", "42m")
                }
            }
        }
    }

    private var previewStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On Track")
                .font(.system(size: 30 * style.fontScale, weight: fontWeight, design: fontDesign))
            Text("Protect the current rhythm.")
                .foregroundStyle(style.secondaryText.color)
        }
    }

    private var previewStreak: some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text("12")
                .font(.system(size: 50 * style.fontScale, weight: fontWeight, design: fontDesign))
                .monospacedDigit()
            Text("days")
                .font(.headline.weight(.bold))
        }
    }

    private var previewGoal: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView(value: 0.72)
                .tint(style.primaryText.color)
            Text("72%")
                .font(.system(size: 40 * style.fontScale, weight: fontWeight, design: fontDesign))
                .monospacedDigit()
            Text("4.3h logged")
                .foregroundStyle(style.secondaryText.color)
        }
    }

    private var previewContribution: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(family == .large ? 13 : 11), spacing: style.gridSpacing), count: family == .large ? 14 : 10), spacing: style.gridSpacing) {
            ForEach(0..<(family == .large ? 98 : 50), id: \.self) { index in
                RoundedRectangle(cornerRadius: style.cellRadius, style: .continuous)
                    .fill(heatColor(index))
                    .frame(width: family == .large ? 13 : 11, height: family == .large ? 13 : 11)
            }
        }
    }

    private var previewRest: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Good day. Stop clean.")
                .font(.system(size: 26 * style.fontScale, weight: fontWeight, design: fontDesign))
                .lineLimit(2)
            Text("Recovery protects tomorrow.")
                .foregroundStyle(style.secondaryText.color)
        }
    }

    private func previewPill(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.bold))
            Text(value)
                .font(.caption.weight(.bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.accent.color.opacity(0.28), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func heatColor(_ index: Int) -> Color {
        let value = Double((index * 19) % 100) / 100
        if value > 0.78 { return style.heatmapHigh.color }
        if value > 0.45 { return style.heatmapMedium.color }
        if value > 0.18 { return style.heatmapLow.color }
        return style.gradientEnd.color
    }

    private var background: LinearGradient {
        LinearGradient(colors: backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var backgroundColors: [Color] {
        switch style.backgroundStyle {
        case .flat:
            return [style.gradientMiddle.color, style.gradientMiddle.color]
        case .minimalDark:
            return [Color(red: 0.08, green: 0.09, blue: 0.12), style.gradientEnd.color]
        case .glass, .elegant:
            return [style.gradientStart.color, style.gradientMiddle.color, style.gradientEnd.color]
        case .glow, .neon:
            return [style.accent.color, style.gradientStart.color, style.gradientEnd.color]
        case .gradient:
            return [style.gradientStart.color, style.gradientMiddle.color, style.gradientEnd.color]
        }
    }

    private var fontWeight: Font.Weight {
        switch style.fontWeight {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }

    private var fontDesign: Font.Design {
        switch style.typography {
        case .system: return .default
        case .rounded: return .rounded
        case .monospaced: return .monospaced
        }
    }
}

struct WidgetPreviewSummary {
    var score: Double
    var productiveHours: Double
    var distractingHours: Double
    var streak: Int
    var goalProgress: Double

    static let demo = WidgetPreviewSummary(score: 84, productiveHours: 5.4, distractingHours: 0.7, streak: 12, goalProgress: 0.72)
}

private struct PresetThemeCard: View {
    var preset: WidgetThemePreset

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: previewColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 72)
                .overlay(alignment: .bottomLeading) {
                    Text(preset.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(12)
                }

            Text(preset.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var previewColors: [Color] {
        let style = preset.styles.first ?? WidgetThemePreset.defaultStyle(for: .productivity)
        return [style.gradientStart.color, style.gradientMiddle.color, style.gradientEnd.color]
    }
}
