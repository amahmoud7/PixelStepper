import Foundation

/// Records which one-off coin rewards have been paid so repeated step refreshes can't pay twice.
/// Each `claim` returns whether (or how much) to pay and marks the reward as paid.
struct RewardLedger: Codable, Equatable {
    var lastGoalRewardDay: String?
    var lastStreakRewardDay: String?
    var lastRecordRewardDay: String?
    var highestMilestoneRewarded: Int = 0

    init() {}

    /// Decodes field-by-field so adding fields later never fails (and resets) the whole progress file.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastGoalRewardDay = try? container.decodeIfPresent(String.self, forKey: .lastGoalRewardDay)
        lastStreakRewardDay = try? container.decodeIfPresent(String.self, forKey: .lastStreakRewardDay)
        lastRecordRewardDay = try? container.decodeIfPresent(String.self, forKey: .lastRecordRewardDay)
        highestMilestoneRewarded = (try? container.decodeIfPresent(Int.self, forKey: .highestMilestoneRewarded)) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case lastGoalRewardDay, lastStreakRewardDay, lastRecordRewardDay, highestMilestoneRewarded
    }

    static let streakMilestones: Set<Int> = [7, 14, 30, 60, 100, 365]
    static let minimumRecordSteps = 1000

    mutating func claimDailyGoal(todaySteps: Int, goal: Int, day: String) -> Bool {
        guard todaySteps >= goal, lastGoalRewardDay != day else { return false }
        lastGoalRewardDay = day
        return true
    }

    /// Returns the coin reward when today's goal completes a milestone streak.
    mutating func claimStreakMilestone(streak: Int, todaySteps: Int, goal: Int, day: String) -> Int? {
        guard todaySteps >= goal,
              Self.streakMilestones.contains(streak),
              lastStreakRewardDay != day else { return nil }
        lastStreakRewardDay = day
        return streak >= 100 ? 500 : streak >= 30 ? 300 : 100
    }

    mutating func claimPersonalRecord(todaySteps: Int, previousBest: Int, day: String) -> Bool {
        guard todaySteps > previousBest,
              todaySteps > Self.minimumRecordSteps,
              lastRecordRewardDay != day else { return false }
        lastRecordRewardDay = day
        return true
    }

    mutating func claimStepMilestone(_ milestone: Int) -> Bool {
        guard milestone > highestMilestoneRewarded else { return false }
        highestMilestoneRewarded = milestone
        return true
    }

    /// Adds coins without trapping on overflow.
    static func adding(_ amount: Int, to balance: Int) -> Int {
        let (sum, overflow) = balance.addingReportingOverflow(amount)
        return overflow ? Int.max : sum
    }

    // MARK: - Day keys

    /// Same key scheme as history, so "today" means the same thing everywhere.
    static func dayKey(for date: Date = Date()) -> String {
        DailyGoalState.dayKey(for: date)
    }
}
