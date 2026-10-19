import Foundation

/// Generates and tracks daily missions. 3 free, 5 for premium.
@MainActor
class MissionManager: ObservableObject {
    @Published var missions: [DailyMission] = []
    @Published var weeklyChallenge: WeeklyChallenge?

    private let persistence = PersistenceManager.shared
    private let dailyGoal = 7500
    /// Last average used for generation, reused when missions roll over at midnight.
    private var lastWeeklyAverage = 3000

    private var todayString: String {
        DailyGoalState.dayKey(for: Date())
    }

    private var weekString: String {
        let calendar = Calendar.current
        let year = calendar.component(.yearForWeekOfYear, from: Date())
        let week = calendar.component(.weekOfYear, from: Date())
        return "\(year)-W\(String(format: "%02d", week))"
    }

    // MARK: - Public API

    /// Loads existing missions for today or generates new ones. Also loads weekly challenge for premium.
    func loadOrGenerateMissions(weeklyAverage: Int) {
        lastWeeklyAverage = weeklyAverage
        loadOrGenerateWeeklyChallenge(weeklyAverage: weeklyAverage)
        let isPremium = PersistenceManager.shared.entitlements.isPremium
        let expectedCount = isPremium ? 5 : 3

        if let saved = loadMissions(), saved.dateString == todayString {
            if saved.missions.count == expectedCount {
                missions = saved.missions
            } else {
                // Premium status changed mid-day — regenerate with correct count, keeping
                // progress on missions that carry over (otherwise their coins pay out twice).
                let previous = Dictionary(saved.missions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                missions = generateMissions(weeklyAverage: max(weeklyAverage, 3000), isPremium: isPremium).map { fresh in
                    guard let old = previous[fresh.id], old.type == fresh.type, old.target == fresh.target else { return fresh }
                    var kept = fresh
                    kept.progress = old.progress
                    return kept
                }
                saveMissions()
            }
        } else {
            missions = generateMissions(weeklyAverage: max(weeklyAverage, 3000), isPremium: isPremium)
            saveMissions()
        }
    }

    /// Updates mission progress based on current state.
    func updateProgress(todaySteps: Int, currentStreak: Int, currentHour: Int,
                        stepsBeforeNoon: Int? = nil, stepsSinceFivePM: Int? = nil) {
        // App stayed in memory past midnight (or the week rolled over): start fresh missions first,
        // instead of applying today's steps to yesterday's list.
        if let first = missions.first, first.dateString != todayString {
            loadOrGenerateMissions(weeklyAverage: lastWeeklyAverage)
        }
        let input = MissionProgress.Input(
            todaySteps: todaySteps,
            stepsBeforeNoon: stepsBeforeNoon,
            stepsSinceFivePM: stepsSinceFivePM,
            currentHour: currentHour,
            dailyGoal: dailyGoal
        )
        var changed = false
        for i in missions.indices where !missions[i].isCompleted {
            let newProgress = MissionProgress.evaluate(missions[i], input)
            if newProgress != missions[i].progress {
                missions[i].progress = newProgress
                changed = true
            }
        }
        if changed {
            saveMissions()
        }
    }

    /// Updates weekly challenge progress.
    func updateWeeklyProgress(weeklySteps: Int, activeDaysThisWeek: Int, bestDayThisWeek: Int) {
        guard var challenge = weeklyChallenge, !challenge.isCompleted else { return }

        let newProgress: Int
        switch challenge.type {
        case .totalSteps:
            newProgress = weeklySteps
        case .activeDays:
            newProgress = activeDaysThisWeek
        case .streakWeek:
            newProgress = activeDaysThisWeek
        case .bigDay:
            newProgress = bestDayThisWeek >= 10_000 ? 1 : 0
        case .consistentWeek:
            newProgress = activeDaysThisWeek
        }

        if newProgress != challenge.progress {
            challenge.progress = newProgress
            weeklyChallenge = challenge
            saveWeeklyChallenge()
        }
    }

    /// Returns completed missions count.
    var completedCount: Int {
        missions.filter(\.isCompleted).count
    }

    // MARK: - Generation

    private func generateMissions(weeklyAverage: Int, isPremium: Bool) -> [DailyMission] {
        // Use date-based seed for deterministic generation
        // String.hashValue is randomized per launch; use a stable hash so missions don't reshuffle.
        var rng = SeededRandomNumberGenerator(string: todayString)

        let types = MissionType.allCases.shuffled(using: &rng)
        let missionCount = isPremium ? 5 : 3

        var result: [DailyMission] = []
        for i in 0..<missionCount {
            let type = types[i % types.count]
            result.append(createMission(type: type, weeklyAverage: weeklyAverage, index: i, rng: &rng))
        }

        return result
    }

    private func createMission(type: MissionType, weeklyAverage: Int, index: Int, rng: inout SeededRandomNumberGenerator) -> DailyMission {
        let dailyAvg = max(3000, weeklyAverage)

        let (title, target, coinReward): (String, Int, Int)

        switch type {
        case .stepTarget:
            let scaled = Int(Double(dailyAvg) * Double.random(in: 0.7...1.2, using: &rng))
            let rounded = (scaled / 500) * 500
            title = "Walk \(rounded.formatted()) steps today"
            target = rounded
            coinReward = rounded >= dailyGoal ? 40 : 20
        case .morningWalk:
            title = "Hit 1,000 steps before noon"
            target = 1000
            coinReward = 25
        case .eveningPush:
            title = "Walk 2,000 steps after 5pm"
            target = 2000
            coinReward = 30
        case .streakExtend:
            title = "Keep your streak alive"
            target = 1
            coinReward = 20
        case .goalCrush:
            let crushTarget = Int(Double(dailyGoal) * 1.5)
            title = "Crush your goal — hit \(crushTarget.formatted()) steps"
            target = crushTarget
            coinReward = 50
        case .consistentDay:
            title = "Stay active for 4+ hours (500+ steps/hr)"
            target = 4
            coinReward = 35
        }

        return DailyMission(
            id: "\(todayString)_\(type.rawValue)_\(index)",
            type: type,
            title: title,
            target: target,
            progress: 0,
            coinReward: coinReward,
            dateString: todayString
        )
    }

    // MARK: - Weekly Challenge

    private func loadOrGenerateWeeklyChallenge(weeklyAverage: Int) {
        guard PersistenceManager.shared.entitlements.isPremium else {
            weeklyChallenge = nil
            return
        }

        if let saved = loadWeeklyChallenge(), saved.weekString == weekString {
            weeklyChallenge = saved.challenge
        } else {
            weeklyChallenge = generateWeeklyChallenge(weeklyAverage: weeklyAverage)
            saveWeeklyChallenge()
        }
    }

    private func generateWeeklyChallenge(weeklyAverage: Int) -> WeeklyChallenge {
        var rng = SeededRandomNumberGenerator(string: weekString)
        let types = WeeklyChallengeType.allCases
        let type = types[Int.random(in: 0..<types.count, using: &rng)]

        let (title, description, target, coinReward): (String, String, Int, Int)

        switch type {
        case .totalSteps:
            let baseTarget = max(35_000, (weeklyAverage / 1000) * 1000)
            let scaled = baseTarget + Int.random(in: 0...10_000, using: &rng)
            let rounded = (scaled / 5000) * 5000
            title = "Marathon Week"
            description = "Walk \(rounded.formatted()) total steps this week"
            target = rounded
            coinReward = 500
        case .activeDays:
            title = "Goal Crusher"
            description = "Meet your daily goal 5 days this week"
            target = 5
            coinReward = 400
        case .streakWeek:
            title = "Perfect Week"
            description = "Meet your daily goal every day this week"
            target = 7
            coinReward = 750
        case .bigDay:
            title = "Big Day"
            description = "Hit 10,000+ steps in a single day"
            target = 1
            coinReward = 300
        case .consistentWeek:
            title = "Steady Pace"
            description = "Walk 5,000+ steps every day this week"
            target = 7
            coinReward = 600
        }

        return WeeklyChallenge(
            id: "weekly_\(weekString)_\(type.rawValue)",
            title: title,
            description: description,
            target: target,
            progress: 0,
            coinReward: coinReward,
            weekString: weekString,
            type: type
        )
    }

    private func saveWeeklyChallenge() {
        guard let challenge = weeklyChallenge else { return }
        let state = WeeklyChallengeState(challenge: challenge, weekString: weekString)
        let url = weeklyFileURL
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
        } catch {
            print("MissionManager: Failed to save weekly: \(error)")
        }
    }

    private func loadWeeklyChallenge() -> WeeklyChallengeState? {
        let url = weeklyFileURL
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WeeklyChallengeState.self, from: data)
    }

    private var weeklyFileURL: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = (urls.first ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent("PixelPal", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("WeeklyChallenge.json")
    }

    // MARK: - Persistence

    private func saveMissions() {
        let state = DailyMissionsState(missions: missions, dateString: todayString)
        let url = missionsFileURL
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
        } catch {
            print("MissionManager: Failed to save: \(error)")
        }
    }

    private func loadMissions() -> DailyMissionsState? {
        let url = missionsFileURL
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DailyMissionsState.self, from: data)
    }

    private var missionsFileURL: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = (urls.first ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent("PixelPal", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("DailyMissions.json")
    }
}

// MARK: - Seeded RNG

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    /// Deterministic across launches (FNV-1a), unlike `String.hashValue`.
    init(string: String) {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        self.init(seed: hash)
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
