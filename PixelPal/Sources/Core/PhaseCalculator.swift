import Foundation

/// Calculates evolution phase based on weekly rolling step totals.
/// Phase graduation is permanent — once you hit the weekly target, you advance.
/// Each week the progress gauge resets, showing progress toward the NEXT phase.
struct PhaseCalculator {
    /// Weekly step thresholds to graduate to next phase.
    static let phase1Max = 25_000    // ~3,571/day to reach Phase 2
    static let phase2Max = 50_000    // ~7,143/day to reach Phase 3
    static let phase3Max = 75_000    // ~10,714/day to reach Phase 4

    /// Returns the step threshold for the next phase.
    static func nextThreshold(for phase: Int) -> Int {
        switch phase {
        case 1: return phase1Max
        case 2: return phase2Max
        case 3: return phase3Max
        default: return phase3Max
        }
    }

    /// Calculates the phase a user would earn based on weekly steps.
    /// - Parameters:
    ///   - totalSteps: Weekly rolling step total (last 7 days).
    ///   - isPremium: Whether the user has premium subscription.
    /// - Returns: Phase number (1-4). Non-premium users are capped at Phase 2.
    static func currentPhase(totalSteps: Int, isPremium: Bool) -> Int {
        switch totalSteps {
        case 0..<phase1Max:
            return 1
        case phase1Max..<phase2Max:
            return 2
        case phase2Max..<phase3Max:
            return isPremium ? 3 : 2
        default:
            return isPremium ? 4 : 2
        }
    }

    /// Returns weekly progress toward the next phase threshold.
    /// - Parameters:
    ///   - weeklySteps: Rolling 7-day step total.
    ///   - currentPhase: User's current permanent phase.
    /// - Returns: Progress percentage (0.0 to 1.0).
    static func weeklyProgress(weeklySteps: Int, currentPhase: Int) -> Double {
        let threshold = nextThreshold(for: currentPhase)
        guard threshold > 0 else { return 1.0 }
        return min(1.0, Double(weeklySteps) / Double(threshold))
    }

    /// Returns steps needed this week to reach next phase.
    /// - Parameters:
    ///   - weeklySteps: Rolling 7-day step total.
    ///   - currentPhase: User's current permanent phase.
    /// - Returns: Steps remaining, or nil if at Phase 4.
    static func stepsToNextPhase(weeklySteps: Int, currentPhase: Int) -> Int? {
        guard currentPhase < 4 else { return nil }
        let threshold = nextThreshold(for: currentPhase)
        return max(0, threshold - weeklySteps)
    }
}

/// Milestone thresholds for celebration display.
struct MilestoneCalculator {
    /// Common milestone values.
    static let milestones = [1_000, 2_500, 5_000, 7_500, 10_000, 15_000, 20_000, 25_000,
                             50_000, 75_000, 100_000, 150_000, 200_000, 250_000, 500_000, 1_000_000]

    /// Checks if a milestone was just reached.
    /// - Parameters:
    ///   - previousSteps: Previous cumulative step count.
    ///   - currentSteps: Current cumulative step count.
    /// - Returns: The milestone value if one was just crossed, nil otherwise.
    /// When several are crossed at once, returns the highest (lower ones are superseded).
    static func checkMilestone(previousSteps: Int, currentSteps: Int) -> Int? {
        milestones.last { previousSteps < $0 && currentSteps >= $0 }
    }

    /// Formats a milestone for display (e.g., "5k!", "100k!").
    static func formatMilestone(_ milestone: Int) -> String {
        shortMilestone(milestone) + "!"
    }

    /// Compact milestone without punctuation ("5k", "2.5k", "1M").
    static func shortMilestone(_ milestone: Int) -> String {
        let oneDecimal = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...1))
        if milestone >= 1_000_000 {
            return "\((Double(milestone) / 1_000_000).formatted(oneDecimal))M"
        } else if milestone >= 1_000 {
            return "\((Double(milestone) / 1_000).formatted(oneDecimal))k"
        } else {
            return "\(milestone)"
        }
    }
}
