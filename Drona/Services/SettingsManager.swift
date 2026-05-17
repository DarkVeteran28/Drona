import Combine
import Foundation

struct AppSettings: Codable, Equatable {
    var productiveGoalHours: Double
    var minimumProductivityScore: Double
    var deepWorkThresholdHours: Double
    var trackingFrequencySeconds: Double
    var widgetRefreshFrequencySeconds: Double
    var autosaveFrequencySeconds: Double
    var batterySavingMode: Bool
    var enforcementEnabled: Bool
    var enforcementStrictness: EnforcementStrictness
    var trackingSensitivity: TrackingSensitivity
    var boostModeIntensity: BoostModeIntensity
    var restModeStartHour: Int
    var restModeEndHour: Int
    var showProductivityWidget: Bool
    var showContributionWidget: Bool
    var showStreakWidget: Bool
    var showStatusWidget: Bool
    var productiveAppsText: String
    var distractingAppsText: String
    var blockedAppsText: String
    var blockedWebsitesText: String

    static let defaults = AppSettings(
        productiveGoalHours: 6,
        minimumProductivityScore: 70,
        deepWorkThresholdHours: 4,
        trackingFrequencySeconds: 2,
        widgetRefreshFrequencySeconds: 300,
        autosaveFrequencySeconds: 60,
        batterySavingMode: false,
        enforcementEnabled: true,
        enforcementStrictness: .balanced,
        trackingSensitivity: .balanced,
        boostModeIntensity: .standard,
        restModeStartHour: 22,
        restModeEndHour: 7,
        showProductivityWidget: true,
        showContributionWidget: true,
        showStreakWidget: true,
        showStatusWidget: true,
        productiveAppsText: "Xcode\nVisual Studio Code\nTerminal\nCursor",
        distractingAppsText: "Steam\nDiscord\nInstagram",
        blockedAppsText: "Steam\nDiscord\nInstagram",
        blockedWebsitesText: "youtube.com\ntwitter.com\nreddit.com"
    )
}

enum EnforcementStrictness: String, Codable, CaseIterable, Identifiable {
    case gentle
    case balanced
    case strict

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle: return "Gentle"
        case .balanced: return "Balanced"
        case .strict: return "Strict"
        }
    }

    var violationCooldown: TimeInterval {
        switch self {
        case .gentle: return 180
        case .balanced: return 90
        case .strict: return 30
        }
    }
}

enum TrackingSensitivity: String, Codable, CaseIterable, Identifiable {
    case relaxed
    case balanced
    case precise

    var id: String { rawValue }

    var title: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .balanced: return "Balanced"
        case .precise: return "Precise"
        }
    }

    var minimumInterval: TimeInterval {
        switch self {
        case .relaxed: return 5
        case .balanced: return 2
        case .precise: return 1
        }
    }
}

enum BoostModeIntensity: String, Codable, CaseIterable, Identifiable {
    case light
    case standard
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: return "Light"
        case .standard: return "Standard"
        case .deep: return "Deep"
        }
    }
}

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var settings: AppSettings {
        didSet {
            persist(settings)
            applyToUserDefaults(settings)
        }
    }

    private let settingsKey = "drona.appSettings"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .defaults
        }
        applyToUserDefaults(settings)
    }

    func update(_ transform: (inout AppSettings) -> Void) {
        var copy = settings
        transform(&copy)
        settings = copy
    }

    func resetToDefaults() {
        settings = .defaults
    }

    func entries(from text: String) -> [String] {
        text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func persist(_ settings: AppSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: settingsKey)
        } catch {
            LoggingManager.shared.log(.error, subsystem: "Settings", message: "Failed saving settings: \(error.localizedDescription)")
        }
    }

    private func applyToUserDefaults(_ settings: AppSettings) {
        defaults.set(settings.productiveGoalHours, forKey: "productiveGoalHours")
        defaults.set(settings.minimumProductivityScore, forKey: "minimumProductivityScore")
        defaults.set(settings.deepWorkThresholdHours, forKey: "deepWorkThresholdHours")
        defaults.set(settings.trackingFrequencySeconds, forKey: "trackingFrequencySeconds")
        defaults.set(settings.widgetRefreshFrequencySeconds, forKey: "widgetRefreshFrequencySeconds")
        defaults.set(settings.autosaveFrequencySeconds, forKey: "autosaveFrequencySeconds")
        defaults.set(settings.batterySavingMode, forKey: "batterySavingMode")
        defaults.set(settings.enforcementEnabled, forKey: "enforcementEnabled")
        defaults.set(settings.enforcementStrictness.rawValue, forKey: "enforcementStrictness")
        defaults.set(settings.trackingSensitivity.rawValue, forKey: "trackingSensitivity")
        defaults.set(settings.boostModeIntensity.rawValue, forKey: "boostModeIntensity")
        defaults.set(settings.restModeStartHour, forKey: "restModeStartHour")
        defaults.set(settings.restModeEndHour, forKey: "restModeEndHour")
        defaults.set(settings.showProductivityWidget, forKey: "showProductivityWidget")
        defaults.set(settings.showContributionWidget, forKey: "showContributionWidget")
        defaults.set(settings.showStreakWidget, forKey: "showStreakWidget")
        defaults.set(settings.showStatusWidget, forKey: "showStatusWidget")
        defaults.set(settings.productiveAppsText, forKey: "productiveApps")
        defaults.set(settings.distractingAppsText, forKey: "distractingApps")
        defaults.set(settings.blockedAppsText, forKey: "blockedApps")
        defaults.set(settings.blockedWebsitesText, forKey: "blockedWebsites")
    }
}
