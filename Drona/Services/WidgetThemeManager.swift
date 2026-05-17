import AppKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

let widgetStyleAppGroupIdentifier = "group.com.likhiththejas.drona"
let widgetStyleStorageKey = "widget_style_configuration"

enum WidgetStyleKind: String, Codable, CaseIterable, Identifiable {
    case productivity
    case status
    case streak
    case goal
    case contribution
    case rest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .productivity: return "Productivity"
        case .status: return "Status"
        case .streak: return "Streak"
        case .goal: return "Goal"
        case .contribution: return "Contributions"
        case .rest: return "Rest"
        }
    }

    var systemImage: String {
        switch self {
        case .productivity: return "gauge.with.dots.needle.67percent"
        case .status: return "sparkle.magnifyingglass"
        case .streak: return "flame.fill"
        case .goal: return "target"
        case .contribution: return "square.grid.3x3.fill"
        case .rest: return "moon.stars.fill"
        }
    }
}

enum WidgetBackgroundStyle: String, Codable, CaseIterable, Identifiable {
    case flat
    case gradient
    case glass
    case minimalDark
    case glow
    case neon
    case elegant

    var id: String { rawValue }
    var title: String {
        switch self {
        case .flat: return "Flat"
        case .gradient: return "Gradient"
        case .glass: return "Glass"
        case .minimalDark: return "Minimal Dark"
        case .glow: return "Glow"
        case .neon: return "Neon"
        case .elegant: return "Elegant"
        }
    }
}

enum WidgetTypographyDesign: String, Codable, CaseIterable, Identifiable {
    case system
    case rounded
    case monospaced

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "SF Pro"
        case .rounded: return "Rounded"
        case .monospaced: return "Code"
        }
    }
}

enum WidgetFontWeightOption: String, Codable, CaseIterable, Identifiable {
    case regular
    case medium
    case semibold
    case bold

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct RGBAColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    static let white = RGBAColor(red: 1, green: 1, blue: 1, alpha: 1)
    static let softWhite = RGBAColor(red: 0.92, green: 0.96, blue: 1, alpha: 1)
    static let dark = RGBAColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 1)

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? .white
        red = Double(nsColor.redComponent)
        green = Double(nsColor.greenComponent)
        blue = Double(nsColor.blueComponent)
        alpha = Double(nsColor.alphaComponent)
    }
}

struct SharedWidgetStyleModel: Codable, Equatable, Identifiable {
    var widgetKind: WidgetStyleKind
    var backgroundStyle: WidgetBackgroundStyle
    var gradientStart: RGBAColor
    var gradientMiddle: RGBAColor
    var gradientEnd: RGBAColor
    var gradientAngle: Double
    var primaryText: RGBAColor
    var secondaryText: RGBAColor
    var accent: RGBAColor
    var borderColor: RGBAColor
    var cornerRadius: Double
    var borderThickness: Double
    var shadowIntensity: Double
    var glowIntensity: Double
    var padding: Double
    var fontScale: Double
    var fontWeight: WidgetFontWeightOption
    var typography: WidgetTypographyDesign
    var heatmapLow: RGBAColor
    var heatmapMedium: RGBAColor
    var heatmapHigh: RGBAColor
    var restDayColor: RGBAColor
    var gridSpacing: Double
    var cellRadius: Double
    var animationsEnabled: Bool
    var hoverGlowEnabled: Bool
    var pulseEffectsEnabled: Bool

    var id: String { widgetKind.rawValue }
}

struct SharedWidgetStyleConfiguration: Codable, Equatable {
    var styles: [SharedWidgetStyleModel]
    var updatedAt: Date

    func style(for kind: WidgetStyleKind) -> SharedWidgetStyleModel {
        styles.first { $0.widgetKind == kind } ?? WidgetThemePreset.defaultStyle(for: kind)
    }
}

struct WidgetThemePreset: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var description: String
    var styles: [SharedWidgetStyleModel]

    static let presets: [WidgetThemePreset] = [
        makePreset(name: "Midnight Purple", description: "Deep violet gradients with bright glass-like contrast.", start: .init(red: 0.34, green: 0.18, blue: 0.86), middle: .init(red: 0.18, green: 0.20, blue: 0.58), end: .init(red: 0.06, green: 0.07, blue: 0.16), accent: .init(red: 0.76, green: 0.58, blue: 1.0)),
        makePreset(name: "Neon Focus", description: "Cyan and purple energy with sharp developer-dashboard contrast.", start: .init(red: 0.00, green: 0.78, blue: 0.92), middle: .init(red: 0.32, green: 0.22, blue: 0.96), end: .init(red: 0.04, green: 0.06, blue: 0.12), accent: .init(red: 0.56, green: 1.0, blue: 0.84)),
        makePreset(name: "Cyber Blue", description: "Blue system glow with clean productivity hierarchy.", start: .init(red: 0.05, green: 0.34, blue: 0.94), middle: .init(red: 0.00, green: 0.56, blue: 0.86), end: .init(red: 0.05, green: 0.08, blue: 0.17), accent: .init(red: 0.40, green: 0.88, blue: 1.0)),
        makePreset(name: "Minimal Dark", description: "Quiet graphite cards with restrained color accents.", start: .init(red: 0.12, green: 0.13, blue: 0.16), middle: .init(red: 0.08, green: 0.09, blue: 0.12), end: .init(red: 0.04, green: 0.05, blue: 0.08), accent: .init(red: 0.56, green: 0.72, blue: 0.92)),
        makePreset(name: "Sunset Gradient", description: "Warm orange-red momentum for end-of-day visibility.", start: .init(red: 0.96, green: 0.44, blue: 0.12), middle: .init(red: 0.82, green: 0.18, blue: 0.28), end: .init(red: 0.10, green: 0.08, blue: 0.16), accent: .init(red: 1.0, green: 0.74, blue: 0.36)),
        makePreset(name: "Productivity Green", description: "Focused green/cyan palette for deep-work tracking.", start: .init(red: 0.00, green: 0.58, blue: 0.38), middle: .init(red: 0.00, green: 0.44, blue: 0.72), end: .init(red: 0.05, green: 0.08, blue: 0.14), accent: .init(red: 0.58, green: 1.0, blue: 0.72)),
        makePreset(name: "Elegant Glass", description: "Premium slate-blue color with WidgetKit-safe contrast.", start: .init(red: 0.22, green: 0.28, blue: 0.42), middle: .init(red: 0.17, green: 0.22, blue: 0.34), end: .init(red: 0.06, green: 0.08, blue: 0.14), accent: .init(red: 0.70, green: 0.82, blue: 1.0)),
        makePreset(name: "Apple Style", description: "Simple blue-green system palette with clean typography.", start: .init(red: 0.00, green: 0.48, blue: 0.98), middle: .init(red: 0.16, green: 0.70, blue: 0.52), end: .init(red: 0.06, green: 0.10, blue: 0.18), accent: .init(red: 0.86, green: 1.0, blue: 0.92))
    ]

    static func defaultConfiguration() -> SharedWidgetStyleConfiguration {
        WidgetThemePreset.presets[5].configuration()
    }

    static func defaultStyle(for kind: WidgetStyleKind) -> SharedWidgetStyleModel {
        makeStyle(kind: kind, start: .init(red: 0, green: 0.58, blue: 0.38), middle: .init(red: 0, green: 0.44, blue: 0.72), end: .init(red: 0.05, green: 0.08, blue: 0.14), accent: .init(red: 0.58, green: 1, blue: 0.72))
    }

    func configuration() -> SharedWidgetStyleConfiguration {
        SharedWidgetStyleConfiguration(styles: styles, updatedAt: Date())
    }

    private static func makePreset(name: String, description: String, start: RGBAColor, middle: RGBAColor, end: RGBAColor, accent: RGBAColor) -> WidgetThemePreset {
        WidgetThemePreset(
            name: name,
            description: description,
            styles: WidgetStyleKind.allCases.map { makeStyle(kind: $0, start: start, middle: middle, end: end, accent: accent) }
        )
    }

    private static func makeStyle(kind: WidgetStyleKind, start: RGBAColor, middle: RGBAColor, end: RGBAColor, accent: RGBAColor) -> SharedWidgetStyleModel {
        SharedWidgetStyleModel(
            widgetKind: kind,
            backgroundStyle: .gradient,
            gradientStart: start,
            gradientMiddle: middle,
            gradientEnd: end,
            gradientAngle: 135,
            primaryText: .white,
            secondaryText: .softWhite,
            accent: accent,
            borderColor: .init(red: 1, green: 1, blue: 1, alpha: 0.72),
            cornerRadius: 22,
            borderThickness: 0,
            shadowIntensity: 0.35,
            glowIntensity: 0.25,
            padding: 16,
            fontScale: 1,
            fontWeight: .bold,
            typography: .rounded,
            heatmapLow: .init(red: 0.22, green: 0.38, blue: 0.34),
            heatmapMedium: .init(red: 0.24, green: 0.78, blue: 0.56),
            heatmapHigh: .init(red: 0.80, green: 1, blue: 0.88),
            restDayColor: .init(red: 0.48, green: 0.68, blue: 1),
            gridSpacing: 5,
            cellRadius: 3,
            animationsEnabled: true,
            hoverGlowEnabled: true,
            pulseEffectsEnabled: false
        )
    }
}

final class WidgetThemeManager: ObservableObject {
    static let shared = WidgetThemeManager()

    @Published private(set) var configuration: SharedWidgetStyleConfiguration
    @Published private(set) var lastStatus: String?

    private let defaults = UserDefaults(suiteName: widgetStyleAppGroupIdentifier)

    private init() {
        if let data = defaults?.data(forKey: widgetStyleStorageKey),
           let decoded = try? JSONDecoder().decode(SharedWidgetStyleConfiguration.self, from: data) {
            configuration = decoded
        } else {
            configuration = WidgetThemePreset.defaultConfiguration()
        }
        persist(refreshWidgets: false)
    }

    func style(for kind: WidgetStyleKind) -> SharedWidgetStyleModel {
        configuration.style(for: kind)
    }

    func updateStyle(for kind: WidgetStyleKind, transform: (inout SharedWidgetStyleModel) -> Void) {
        var styles = configuration.styles
        let index = styles.firstIndex { $0.widgetKind == kind }
        var style = index.map { styles[$0] } ?? WidgetThemePreset.defaultStyle(for: kind)
        transform(&style)

        if let index {
            styles[index] = style
        } else {
            styles.append(style)
        }

        configuration = SharedWidgetStyleConfiguration(styles: styles, updatedAt: Date())
        persist(refreshWidgets: true)
    }

    func applyPreset(_ preset: WidgetThemePreset, to kind: WidgetStyleKind?) {
        if let kind {
            guard let presetStyle = preset.styles.first(where: { $0.widgetKind == kind }) else { return }
            updateStyle(for: kind) { style in
                let currentKind = style.widgetKind
                style = presetStyle
                style.widgetKind = currentKind
            }
        } else {
            configuration = preset.configuration()
            persist(refreshWidgets: true)
        }
    }

    func exportTheme() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Drona Widget Theme.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(configuration)
            try data.write(to: url, options: [.atomic])
            lastStatus = "Exported theme to \(url.lastPathComponent)."
        } catch {
            lastStatus = "Export failed: \(error.localizedDescription)"
        }
    }

    func importTheme() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            configuration = try JSONDecoder().decode(SharedWidgetStyleConfiguration.self, from: data)
            persist(refreshWidgets: true)
            lastStatus = "Imported \(url.lastPathComponent)."
        } catch {
            lastStatus = "Import failed: \(error.localizedDescription)"
        }
    }

    private func persist(refreshWidgets: Bool) {
        do {
            let data = try JSONEncoder().encode(configuration)
            defaults?.set(data, forKey: widgetStyleStorageKey)
            if refreshWidgets {
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            lastStatus = "Save failed: \(error.localizedDescription)"
        }
    }
}
