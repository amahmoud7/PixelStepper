import Foundation

// MARK: - Gender

enum Gender: String, Codable, CaseIterable {
    case male
    case female

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }
}

// MARK: - Avatar State

enum AvatarState: String, Codable {
    case vital
    case neutral
    case low

    var description: String {
        switch self {
        case .vital: return "Vital"
        case .neutral: return "Neutral"
        case .low: return "Low Energy"
        }
    }
}

// MARK: - Avatar Logic

struct AvatarLogic {
    /// Determines the avatar state based on current steps using simple fixed thresholds.
    /// - Parameter steps: Steps taken today.
    /// - Returns: Calculated AvatarState.
    static func determineState(steps: Int) -> AvatarState {
        switch steps {
        case 0..<2500:
            return .low
        case 2500..<7500:
            return .neutral
        default:
            return .vital
        }
    }

    /// Convenience overload for Double step counts.
    static func determineState(steps: Double) -> AvatarState {
        return determineState(steps: Int(steps))
    }
}
