import Foundation

/// Tracks user's cumulative progress and evolution phase.
/// Evolution is permanent - phases never reset or reverse.
struct ProgressState: Codable, Equatable {
    /// Total steps accumulated since UserProfile.createdAt.
    /// This drives phase evolution and never resets.
    var totalStepsSinceStart: Int

    /// Last time HealthKit data was synced.
    var lastHealthKitSync: Date?

    /// Current evolution phase (1-4).
    /// Phase 1: Seedling (0-25,000 steps)
    /// Phase 2: Growing (25,001-75,000 steps)
    /// Phase 3: Thriving (75,001-200,000 steps) - Premium
    /// Phase 4: Legendary (200,001+ steps) - Premium
    var currentPhase: Int

    /// Whether the user has seen the paywall (shown after Phase 2 unlock).
    var hasSeenPaywall: Bool

    /// Last time the paywall was shown (for cooldown-based re-engagement).
    var lastPaywallDate: Date?

    /// Today's step count (for display, separate from cumulative).
    var todaySteps: Int

    /// Whether we've already requested an App Store review.
    var hasRequestedReview: Bool

    /// Current streak of consecutive days meeting the goal.
    var currentStreak: Int

    /// Longest streak ever achieved.
    var longestStreak: Int

    /// Best single-day step count.
    var bestDaySteps: Int

    /// Date of best single-day step count.
    var bestDayDate: Date?

    /// Total number of days with goal met.
    var totalActiveDays: Int

    /// Step coin balance for cosmetic shop.
    var stepCoinBalance: Int

    /// Date when streak freeze was last used (resets weekly).
    var streakFreezeUsedDate: Date?

    /// One-off rewards already paid (prevents double payouts on refresh).
    var rewardLedger = RewardLedger()

    /// Creates initial progress state for a new user.
    static func createNew() -> ProgressState {
        ProgressState(
            totalStepsSinceStart: 0,
            lastHealthKitSync: nil,
            currentPhase: 1,
            hasSeenPaywall: false,
            lastPaywallDate: nil,
            todaySteps: 0,
            hasRequestedReview: false,
            currentStreak: 0,
            longestStreak: 0,
            bestDaySteps: 0,
            bestDayDate: nil,
            totalActiveDays: 0,
            stepCoinBalance: 0
        )
    }

    init(
        totalStepsSinceStart: Int,
        lastHealthKitSync: Date?,
        currentPhase: Int,
        hasSeenPaywall: Bool,
        lastPaywallDate: Date? = nil,
        todaySteps: Int,
        hasRequestedReview: Bool = false,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        bestDaySteps: Int = 0,
        bestDayDate: Date? = nil,
        totalActiveDays: Int = 0,
        stepCoinBalance: Int = 0,
        streakFreezeUsedDate: Date? = nil
    ) {
        self.totalStepsSinceStart = totalStepsSinceStart
        self.lastHealthKitSync = lastHealthKitSync
        self.currentPhase = currentPhase
        self.hasSeenPaywall = hasSeenPaywall
        self.lastPaywallDate = lastPaywallDate
        self.todaySteps = todaySteps
        self.hasRequestedReview = hasRequestedReview
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.bestDaySteps = bestDaySteps
        self.bestDayDate = bestDayDate
        self.totalActiveDays = totalActiveDays
        self.stepCoinBalance = stepCoinBalance
        self.streakFreezeUsedDate = streakFreezeUsedDate
    }

    // Custom Codable to handle backward compatibility for new fields
    enum CodingKeys: String, CodingKey {
        case totalStepsSinceStart, lastHealthKitSync, currentPhase
        case hasSeenPaywall, lastPaywallDate, todaySteps
        case hasRequestedReview, currentStreak, longestStreak
        case bestDaySteps, bestDayDate, totalActiveDays, stepCoinBalance, streakFreezeUsedDate
        case rewardLedger
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalStepsSinceStart = try container.decode(Int.self, forKey: .totalStepsSinceStart)
        lastHealthKitSync = try container.decodeIfPresent(Date.self, forKey: .lastHealthKitSync)
        currentPhase = try container.decode(Int.self, forKey: .currentPhase)
        hasSeenPaywall = try container.decode(Bool.self, forKey: .hasSeenPaywall)
        lastPaywallDate = try container.decodeIfPresent(Date.self, forKey: .lastPaywallDate)
        todaySteps = try container.decode(Int.self, forKey: .todaySteps)
        hasRequestedReview = try container.decodeIfPresent(Bool.self, forKey: .hasRequestedReview) ?? false
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        bestDaySteps = try container.decodeIfPresent(Int.self, forKey: .bestDaySteps) ?? 0
        bestDayDate = try container.decodeIfPresent(Date.self, forKey: .bestDayDate)
        totalActiveDays = try container.decodeIfPresent(Int.self, forKey: .totalActiveDays) ?? 0
        stepCoinBalance = try container.decodeIfPresent(Int.self, forKey: .stepCoinBalance) ?? 0
        streakFreezeUsedDate = try container.decodeIfPresent(Date.self, forKey: .streakFreezeUsedDate)
        rewardLedger = (try? container.decodeIfPresent(RewardLedger.self, forKey: .rewardLedger)) ?? RewardLedger()
    }

    /// Updates the phase based on total steps and premium status.
    mutating func updatePhase(isPremium: Bool) {
        let newPhase = PhaseCalculator.currentPhase(
            totalSteps: totalStepsSinceStart,
            isPremium: isPremium
        )
        // Phase can only increase, never decrease
        if newPhase > currentPhase {
            currentPhase = newPhase
        }
    }
}
