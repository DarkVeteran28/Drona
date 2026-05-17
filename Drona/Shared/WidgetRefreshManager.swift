import Foundation
import WidgetKit

final class WidgetRefreshManager {
    private static var lastRefresh: Date?

    static var lastRefreshDate: Date? {
        lastRefresh
    }

    static func refreshAllWidgets(force: Bool = false) {
        let configuredInterval = UserDefaults.standard.double(forKey: "widgetRefreshFrequencySeconds")
        let interval = configuredInterval > 0 ? configuredInterval : 300

        if !force, let lastRefresh, Date().timeIntervalSince(lastRefresh) < interval {
            return
        }

        WidgetCenter.shared.reloadAllTimelines()
        lastRefresh = Date()
        LoggingManager.shared.log(.debug, subsystem: "Widgets", message: "Widget timelines refreshed.")
    }
}
