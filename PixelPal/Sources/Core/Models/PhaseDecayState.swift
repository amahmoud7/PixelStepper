import Foundation

/// Tracks phase decay state for the Phase Decay System (v1.1).
/// 
/// Phase Decay Logic:
/// - Strong (met goal) → 1 miss → Neutral
/// - Neutral → 1 more miss (2 total) → Tired  
/// - Any goal hit → instant restore to Strong
struct PhaseDecayState: Codable, Equatable {
    /// The user's true earned phase based on cumulative steps (never decays).
    var baselinePhase: Int
    
    /// Current displayed phase (can be decayed).
    var currentPhase: Int
    
    /// Consecutive days goal was missed.
    var consecutiveMisses: Int
    
    /// Date of last goal achievement.
    var lastGoalMetDate: Date?
    
    /// Date when state was last updated.
    var lastUpdated: Date
    
    /// Creates initial decay state for a new user.
    static func createNew(baselinePhase: Int = 1) -> PhaseDecayState {
        PhaseDecayState(
            baselinePhase: baselinePhase,
            currentPhase: baselinePhase,
            consecutiveMisses: 0,
            lastGoalMetDate: nil,
            lastUpdated: Date()
        )
    }
    
    /// Current decay status for UI display.
    var decayStatus: PhaseDecayStatus {
        if currentPhase == baselinePhase {
            return .strong
        } else if consecutiveMisses == 1 {
            return .neutral
        } else {
            return .tired
        }
    }
    
    /// Whether the character is currently decayed.
    var isDecayed: Bool {
        currentPhase < baselinePhase
    }
    
    /// Visual indicator for decay state.
    var visualOpacity: Double {
        switch decayStatus {
        case .strong: return 1.0
        case .neutral: return 0.85
        case .tired: return 0.7
        }
    }
}

/// Phase decay visual status.
enum PhaseDecayStatus: String, Codable {
    case strong   // Goal met recently, full phase
    case neutral  // 1 miss
    case tired    // 2+ misses
    
    var description: String {
        switch self {
        case .strong: return "Energized"
        case .neutral: return "Winding Down"
        case .tired: return "Resting"
        }
    }
    
    var color: String {
        switch self {
        case .strong: return "green"
        case .neutral: return "yellow"
        case .tired: return "red"
        }
    }
}
