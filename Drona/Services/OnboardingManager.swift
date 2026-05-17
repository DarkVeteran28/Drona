import Combine
import Foundation

final class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: key)
        }
    }

    private let defaults: UserDefaults
    private let key = "hasCompletedOnboarding"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: key)
    }

    func complete() {
        hasCompletedOnboarding = true
    }

    func reset() {
        hasCompletedOnboarding = false
    }
}
