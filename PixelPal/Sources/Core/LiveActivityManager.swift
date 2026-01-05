import ActivityKit
import Foundation

/// Manages the Pixel Pal Live Activity lifecycle.
@MainActor
class LiveActivityManager: ObservableObject {
    /// Whether a Live Activity is currently running.
    @Published var isActive: Bool = false

    /// The current Live Activity instance.
    private var currentActivity: Activity<PixelPalAttributes>?

    init() {
        // Check for any existing activities on launch
        checkForExistingActivity()
    }

    /// Checks if there's an existing Live Activity and restores reference to it.
    private func checkForExistingActivity() {
        if let existing = Activity<PixelPalAttributes>.activities.first {
            self.currentActivity = existing
            self.isActive = true
        }
    }

    /// Starts a new Live Activity with the given state.
    /// - Parameters:
    ///   - steps: Current step count.
    ///   - state: Current avatar state.
    ///   - gender: Selected gender.
    func startActivity(steps: Int, state: AvatarState, gender: Gender) {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        // End any existing activity first
        if currentActivity != nil {
            endActivity()
        }

        let attributes = PixelPalAttributes()
        let contentState = PixelPalAttributes.ContentState(
            steps: steps,
            state: state,
            gender: gender
        )

        do {
            let activity = try Activity<PixelPalAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil // No push updates for v1
            )
            self.currentActivity = activity
            self.isActive = true
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Updates the Live Activity with new state.
    /// - Parameters:
    ///   - steps: Current step count.
    ///   - state: Current avatar state.
    ///   - gender: Selected gender.
    func updateActivity(steps: Int, state: AvatarState, gender: Gender) {
        guard let activity = currentActivity else {
            // No active activity, start one instead
            startActivity(steps: steps, state: state, gender: gender)
            return
        }

        let contentState = PixelPalAttributes.ContentState(
            steps: steps,
            state: state,
            gender: gender
        )

        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }

    /// Ends the current Live Activity.
    func endActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.currentActivity = nil
            self.isActive = false
            print("Ended Live Activity")
        }
    }

    /// Ends all Pixel Pal Live Activities (cleanup utility).
    func endAllActivities() {
        Task {
            for activity in Activity<PixelPalAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            self.currentActivity = nil
            self.isActive = false
        }
    }
}
