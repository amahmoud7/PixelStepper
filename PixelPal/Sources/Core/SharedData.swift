import Foundation
import WidgetKit

struct SharedData {
    static let appGroupId = "group.com.pixelpalfit.app"

    struct Keys {
        static let suiteName = appGroupId
        static let avatarState = "avatarState"
        static let lastUpdateDate = "lastUpdateDate"
        static let currentSteps = "currentSteps"
        static let gender = "gender"
        static let currentPhase = "currentPhase"
    }

    static var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupId)
    }

    // MARK: - State

    static func saveState(state: AvatarState, steps: Double, phase: Int = 1) {
        guard let defaults = userDefaults else { return }
        defaults.set(state.rawValue, forKey: Keys.avatarState)
        defaults.set(steps, forKey: Keys.currentSteps)
        defaults.set(phase, forKey: Keys.currentPhase)
        defaults.set(Date(), forKey: Keys.lastUpdateDate)

        // Reload widget
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func savePhase(_ phase: Int) {
        guard let defaults = userDefaults else { return }
        defaults.set(phase, forKey: Keys.currentPhase)

        // Reload widget
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func loadPhase() -> Int {
        guard let defaults = userDefaults else { return 1 }
        let phase = defaults.integer(forKey: Keys.currentPhase)
        return phase > 0 ? phase : 1  // Default to phase 1
    }

    static func loadState() -> AvatarState {
        guard let defaults = userDefaults,
              let rawValue = defaults.string(forKey: Keys.avatarState),
              let state = AvatarState(rawValue: rawValue) else {
            return .low // Default for new users
        }
        return state
    }

    static func loadSteps() -> Int {
        guard let defaults = userDefaults else { return 0 }
        return defaults.integer(forKey: Keys.currentSteps)
    }

    static func loadLastUpdateDate() -> Date? {
        guard let defaults = userDefaults else { return nil }
        return defaults.object(forKey: Keys.lastUpdateDate) as? Date
    }

    // MARK: - Cumulative Steps

    static func saveCumulativeSteps(_ steps: Int) {
        guard let defaults = userDefaults else { return }
        defaults.set(steps, forKey: "cumulativeSteps")
    }

    static func loadCumulativeSteps() -> Int {
        guard let defaults = userDefaults else { return 0 }
        return defaults.integer(forKey: "cumulativeSteps")
    }

    // MARK: - Week Data (last 7 days step counts)

    static func saveWeekData(_ data: [Int]) {
        guard let defaults = userDefaults else { return }
        defaults.set(data, forKey: "weekStepData")
    }

    static func loadWeekData() -> [Int] {
        guard let defaults = userDefaults else { return [] }
        return defaults.array(forKey: "weekStepData") as? [Int] ?? []
    }

    // MARK: - Gender

    static func saveGender(_ gender: Gender) {
        guard let defaults = userDefaults else { return }
        defaults.set(gender.rawValue, forKey: Keys.gender)
    }

    static func loadGender() -> Gender? {
        guard let defaults = userDefaults,
              let rawValue = defaults.string(forKey: Keys.gender),
              let gender = Gender(rawValue: rawValue) else {
            return nil // Not yet selected
        }
        return gender
    }

    static var hasSelectedGender: Bool {
        return loadGender() != nil
    }
}
