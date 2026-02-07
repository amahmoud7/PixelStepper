import ActivityKit
import Foundation

/// Manages the Pixel Pal Live Activity lifecycle.
@MainActor
class LiveActivityManager: ObservableObject {
    /// Whether a Live Activity is currently running.
    @Published var isActive: Bool = false

    /// The current Live Activity instance.
    private var currentActivity: Activity<PixelPalAttributes>?

    /// Previous step count to detect walking.
    private var previousSteps: Int = 0

    /// Previous cumulative steps for milestone detection.
    private var previousCumulativeSteps: Int = 0

    /// Timer for clearing milestone celebration.
    private var milestoneTimer: Timer?

    /// Whether currently in walking state.
    private var isWalking: Bool = false

    /// Current gender for updates.
    private var currentGender: Gender = .male

    /// Current avatar state for updates.
    private var currentState: AvatarState = .low

    /// Current evolution phase (1-4).
    private var currentPhase: Int = 1

    /// Current milestone text being displayed (nil when not celebrating).
    private var currentMilestone: String?

    init() {
        // Defer activity check to avoid blocking app launch
        Task { @MainActor [weak self] in
            self?.checkForExistingActivity()
        }
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
    ///   - steps: Current step count (today).
    ///   - state: Current avatar state.
    ///   - gender: Selected gender.
    ///   - phase: Current evolution phase (1-4).
    func startActivity(steps: Int, state: AvatarState, gender: Gender, phase: Int = 1) {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        // End any existing activity first
        if currentActivity != nil {
            endActivity()
        }

        // Store current phase
        currentPhase = phase

        let attributes = PixelPalAttributes()
        let contentState = PixelPalAttributes.ContentState(
            steps: steps,
            state: state,
            gender: gender,
            isWalking: false,
            walkingFrame: 1,
            currentPhase: phase,
            milestoneText: nil,
            showStepCount: false
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
    ///   - steps: Current step count (today).
    ///   - state: Current avatar state.
    ///   - gender: Selected gender.
    ///   - phase: Current evolution phase (1-4).
    ///   - cumulativeSteps: Total cumulative steps (for milestone detection).
    func updateActivity(steps: Int, state: AvatarState, gender: Gender, phase: Int = 1, cumulativeSteps: Int = 0) {
        guard let activity = currentActivity else {
            // No active activity, start one instead
            startActivity(steps: steps, state: state, gender: gender, phase: phase)
            return
        }

        // Store current values for timer updates
        currentGender = gender
        currentState = state
        currentPhase = phase

        // Check for milestone (using cumulative steps)
        if cumulativeSteps > previousCumulativeSteps {
            if let milestone = MilestoneCalculator.checkMilestone(
                previousSteps: previousCumulativeSteps,
                currentSteps: cumulativeSteps
            ) {
                triggerMilestone(milestone, steps: steps)
            }
        }
        previousCumulativeSteps = cumulativeSteps

        // Detect if user is walking (steps increased)
        let stepsIncreased = steps > previousSteps
        previousSteps = steps

        if stepsIncreased && !isWalking {
            // Start walking animation
            startWalkingAnimation(steps: steps)
        } else if !stepsIncreased && isWalking {
            // Stop walking animation after a delay
            stopWalkingAnimation(steps: steps)
        } else if !isWalking {
            // Normal update (not walking) - idle state, no step count per UI rules
            let contentState = PixelPalAttributes.ContentState(
                steps: steps,
                state: state,
                gender: gender,
                isWalking: false,
                walkingFrame: 1,
                currentPhase: phase,
                milestoneText: currentMilestone,
                showStepCount: currentMilestone != nil  // Show during milestone celebration
            )

            Task {
                await activity.update(
                    ActivityContent(state: contentState, staleDate: nil)
                )
            }
        }
    }

    // MARK: - Milestone Celebration

    /// Triggers a milestone celebration display.
    private func triggerMilestone(_ milestone: Int, steps: Int) {
        let milestoneText = MilestoneCalculator.formatMilestone(milestone)
        currentMilestone = milestoneText

        // Update immediately with milestone
        updateMilestoneDisplay(steps: steps, milestoneText: milestoneText)

        // Clear milestone after 3-5 seconds per UI rules
        milestoneTimer?.invalidate()
        milestoneTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.clearMilestone(steps: steps)
            }
        }

        print("Milestone reached: \(milestoneText)")
    }

    /// Updates display with milestone text.
    private func updateMilestoneDisplay(steps: Int, milestoneText: String) {
        guard let activity = currentActivity else { return }

        let contentState = PixelPalAttributes.ContentState(
            steps: steps,
            state: currentState,
            gender: currentGender,
            isWalking: isWalking,
            walkingFrame: 1,
            currentPhase: currentPhase,
            milestoneText: milestoneText,
            showStepCount: true
        )

        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }

    /// Clears the milestone celebration.
    private func clearMilestone(steps: Int) {
        currentMilestone = nil
        milestoneTimer?.invalidate()
        milestoneTimer = nil

        guard let activity = currentActivity else { return }

        let contentState = PixelPalAttributes.ContentState(
            steps: steps,
            state: currentState,
            gender: currentGender,
            isWalking: isWalking,
            walkingFrame: 1,
            currentPhase: currentPhase,
            milestoneText: nil,
            showStepCount: isWalking
        )

        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }

    /// Starts walking state — sends ONE update, animation handled locally by TimelineView in widget.
    private func startWalkingAnimation(steps: Int) {
        isWalking = true

        guard let activity = currentActivity else { return }

        let contentState = PixelPalAttributes.ContentState(
            steps: steps,
            state: currentState,
            gender: currentGender,
            isWalking: true,
            walkingFrame: 1,
            currentPhase: currentPhase,
            milestoneText: currentMilestone,
            showStepCount: true
        )

        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }

    /// Stops walking state — sends ONE update to return to idle.
    private func stopWalkingAnimation(steps: Int) {
        isWalking = false

        guard let activity = currentActivity else { return }

        let contentState = PixelPalAttributes.ContentState(
            steps: steps,
            state: currentState,
            gender: currentGender,
            isWalking: false,
            walkingFrame: 1,
            currentPhase: currentPhase,
            milestoneText: currentMilestone,
            showStepCount: currentMilestone != nil
        )

        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }

    /// Ends the current Live Activity.
    func endActivity() {
        isWalking = false

        // Stop milestone timer
        milestoneTimer?.invalidate()
        milestoneTimer = nil
        currentMilestone = nil

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
