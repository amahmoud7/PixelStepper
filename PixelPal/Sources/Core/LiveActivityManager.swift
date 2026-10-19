import ActivityKit
import Foundation

/// Manages the Pixel Stepper Live Activity lifecycle.
@MainActor
class LiveActivityManager: ObservableObject {
    /// Whether a Live Activity is currently running.
    @Published var isActive: Bool = false

    /// The current Live Activity instance.
    private var currentActivity: Activity<PixelStepperAttributes>?

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
        // Ignore activities that already ended (e.g. swiped away or expired after 8h).
        if let existing = Activity<PixelStepperAttributes>.activities.first(where: { $0.activityState == .active }) {
            self.currentActivity = existing
            self.isActive = true
            observeEnd(of: existing)
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

        let attributes = PixelStepperAttributes()
        let contentState = PixelStepperAttributes.ContentState(
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
            let activity = try Activity<PixelStepperAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil // No push updates for v1
            )
            self.currentActivity = activity
            self.isActive = true
            self.lastSentState = nil
            self.observeEnd(of: activity)
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
        // First update this session: adopt the current total instead of "crossing" every
        // milestone from 0 (which flashed a milestone on every cold start).
        if previousCumulativeSteps == 0 {
            previousCumulativeSteps = cumulativeSteps
        }
        if cumulativeSteps > previousCumulativeSteps {
            if let milestone = MilestoneCalculator.checkMilestone(
                previousSteps: previousCumulativeSteps,
                currentSteps: cumulativeSteps
            ) {
                triggerMilestone(milestone, steps: steps)
            }
        }
        previousCumulativeSteps = cumulativeSteps

        // "Walking" = steps rose since the last update this session (never on cold start),
        // so the activity can't get stuck walking and the step count keeps updating.
        let stepsIncreased = previousSteps > 0 && steps > previousSteps
        previousSteps = steps
        isWalking = stepsIncreased
        push(activity, steps: steps)
    }

    /// Returns the activity to idle when the app leaves the foreground (no more step updates arrive).
    /// Also clears a milestone banner, since its timer can't fire while the app is suspended.
    func markIdle() {
        guard let activity = currentActivity, isWalking || currentMilestone != nil else { return }
        isWalking = false
        currentMilestone = nil
        milestoneTimer?.invalidate()
        milestoneTimer = nil
        push(activity, steps: previousSteps)
    }

    /// Keeps `isActive` honest when the user dismisses the activity or the system ends it.
    private var endObservation: Task<Void, Never>?

    private func observeEnd(of activity: Activity<PixelStepperAttributes>) {
        endObservation?.cancel()
        endObservation = Task { [weak self] in
            for await state in activity.activityStateUpdates where state == .dismissed || state == .ended {
                guard let self, self.currentActivity?.id == activity.id else { return }
                self.currentActivity = nil
                self.isActive = false
                self.isWalking = false
                self.lastSentState = nil
                return
            }
        }
    }

    /// Last content sent, to skip identical updates (ActivityKit budgets updates).
    private var lastSentState: PixelStepperAttributes.ContentState?

    private func push(_ activity: Activity<PixelStepperAttributes>, steps: Int) {
        let contentState = PixelStepperAttributes.ContentState(
            steps: steps,
            state: currentState,
            gender: currentGender,
            isWalking: isWalking,
            walkingFrame: 1,
            currentPhase: currentPhase,
            milestoneText: currentMilestone,
            showStepCount: isWalking || currentMilestone != nil
        )
        guard contentState != lastSentState else { return }
        lastSentState = contentState

        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
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

        let contentState = PixelStepperAttributes.ContentState(
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
        // Latest known steps, deduped like every other update.
        push(activity, steps: max(steps, previousSteps))
    }

    /// Ends the current Live Activity.
    func endActivity() {
        isWalking = false

        // Stop milestone timer
        milestoneTimer?.invalidate()
        milestoneTimer = nil
        currentMilestone = nil

        guard let activity = currentActivity else { return }

        lastSentState = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            // A new activity may have started while this one was ending; don't orphan it.
            if self.currentActivity?.id == activity.id {
                self.currentActivity = nil
                self.isActive = false
            }
        }
    }

    /// Ends all Pixel Stepper Live Activities (cleanup utility).
    func endAllActivities() {
        Task {
            for activity in Activity<PixelStepperAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            self.currentActivity = nil
            self.isActive = false
        }
    }
}
