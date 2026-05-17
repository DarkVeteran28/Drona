import Foundation

class ProductivityClassifier {
    func classify(appName: String) -> ProductivityCategory {
        if productiveApps.contains(appName) {
            return .productive
        }

        if distractingApps.contains(appName) {
            return .distracting
        }

        return .neutral
    }

    private var productiveApps: Set<String> {
        entries(forKey: "productiveApps", fallback: AppSettings.defaults.productiveAppsText)
    }

    private var distractingApps: Set<String> {
        entries(forKey: "distractingApps", fallback: AppSettings.defaults.distractingAppsText)
    }

    private func entries(forKey key: String, fallback: String) -> Set<String> {
        let text = UserDefaults.standard.string(forKey: key) ?? fallback
        return Set(
            text
                .split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }
}
