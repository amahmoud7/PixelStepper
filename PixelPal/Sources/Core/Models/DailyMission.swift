import Foundation

/// A single daily mission challenge.
struct DailyMission: Codable, Identifiable, Equatable {
    let id: String
    let type: MissionType
    let title: String
    let target: Int
    var progress: Int
    let coinReward: Int
    let dateString: String

    var isCompleted: Bool {
        progress >= target
    }

    var progressFraction: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target), 1.0)
    }

    static func == (lhs: DailyMission, rhs: DailyMission) -> Bool {
        lhs.id == rhs.id && lhs.progress == rhs.progress
    }
}

/// Types of daily missions.
enum MissionType: String, Codable, CaseIterable {
    case stepTarget
    case morningWalk
    case eveningPush
    case streakExtend
    case goalCrush
    case consistentDay

    var icon: String {
        switch self {
        case .stepTarget: return "figure.walk"
        case .morningWalk: return "sunrise.fill"
        case .eveningPush: return "sunset.fill"
        case .streakExtend: return "flame.fill"
        case .goalCrush: return "bolt.fill"
        case .consistentDay: return "clock.fill"
        }
    }

    var color: String {
        switch self {
        case .stepTarget: return "#34C759"
        case .morningWalk: return "#FF9500"
        case .eveningPush: return "#AF52DE"
        case .streakExtend: return "#FF9900"
        case .goalCrush: return "#FFD700"
        case .consistentDay: return "#007AFF"
        }
    }
}

/// Persisted daily missions state.
struct DailyMissionsState: Codable {
    var missions: [DailyMission]
    var dateString: String
}
