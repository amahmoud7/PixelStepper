import Foundation
import Combine

/// Manages the Phase Decay System (v1.1).
/// 
/// Logic:
/// - Strong → Neutral (after 1 missed goal)
/// - Neutral → Tired (after 2 consecutive misses)  
/// - Any goal hit → instant restore to Strong
/// 
/// Handles edge cases:
/// - App killed for multiple days
/// - New user (no history)
/// - Time zone changes
@MainActor
class PhaseDecayManager: ObservableObject {
    /// Shared instance.
    static let shared = PhaseDecayManager()
    
    /// Current decay state.
    @Published var state: PhaseDecayState
    
    /// History manager reference for goal tracking.
    private let historyManager = HistoryManager.shared
    
    /// Persistence manager for saving state.
    private let persistence = PersistenceManager.shared
    
    /// Cancellable for history updates.
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load from persistence or create new
        self.state = persistence.phaseDecayState ?? PhaseDecayState.createNew()
        
        // Subscribe to history updates
        historyManager.$todayState
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.evaluateDecay()
            }
            .store(in: &cancellables)
        
        // Initial evaluation
        evaluateDecay()
    }
    
    // MARK: - Public API
    
    /// Call when today's steps are updated.
    func updateSteps(_ steps: Int) {
        historyManager.updateToday(steps: steps)
        
        // Check if goal was just met
        let goalMet = steps >= historyManager.dailyGoal
        if goalMet {
            restoreToStrong()
        } else {
            evaluateDecay()
        }
    }
    
    /// Manually trigger evaluation (e.g., on app launch or day change).
    func evaluateDecay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Update baseline phase first
        let baselinePhase = persistence.progressState.currentPhase
        state.baselinePhase = baselinePhase
        
        // Get consecutive misses
        let consecutiveMisses = historyManager.consecutiveMisses
        
        // Apply decay logic
        var newPhase = baselinePhase
        var newConsecutiveMisses = consecutiveMisses
        
        // Check if goal was met today
        let todayMet = historyManager.todayState?.isGoalMet ?? false
        
        if todayMet {
            // Goal met - restore to full strength
            newPhase = baselinePhase
            newConsecutiveMisses = 0
            state.lastGoalMetDate = today
        } else {
            // Goal not met - apply decay
            switch consecutiveMisses {
            case 0:
                // No misses yet, stay strong
                newPhase = baselinePhase
            case 1:
                // 1 miss → Neutral (show phase at -1, minimum 1)
                newPhase = max(1, baselinePhase - 1)
            case 2...:
                // 2+ misses → Tired (show minimum phase 1)
                newPhase = max(1, baselinePhase - 1)
            default:
                break
            }
        }
        
        // Update state if changed
        if state.currentPhase != newPhase || state.consecutiveMisses != newConsecutiveMisses {
            state.currentPhase = newPhase
            state.consecutiveMisses = newConsecutiveMisses
            state.lastUpdated = Date()
            
            // Persist changes
            persistence.savePhaseDecayState(state)
            
            // Update shared data for widgets
            updateSharedData()
        }
    }
    
    /// Force restore to strong (e.g., after purchase or manual action).
    func restoreToStrong() {
        state.currentPhase = state.baselinePhase
        state.consecutiveMisses = 0
        state.lastGoalMetDate = Date()
        state.lastUpdated = Date()
        
        persistence.savePhaseDecayState(state)
        updateSharedData()
    }
    
    /// Get visual opacity for current decay state.
    var visualOpacity: Double {
        switch state.decayStatus {
        case .strong: return 1.0
        case .neutral: return 0.85
        case .tired: return 0.7
        }
    }
    
    /// Get visual dimming amount for decay.
    var dimmingAmount: Double {
        switch state.decayStatus {
        case .strong: return 0.0
        case .neutral: return 0.15
        case .tired: return 0.3
        }
    }
    
    /// Get a tint color to apply to avatar for decay indication.
    var decayTint: DecayTint {
        switch state.decayStatus {
        case .strong:
            return DecayTint(color: .clear, intensity: 0)
        case .neutral:
            return DecayTint(color: .yellow, intensity: 0.2)
        case .tired:
            return DecayTint(color: .gray, intensity: 0.3)
        }
    }
    
    /// Reset state (for testing).
    func reset() {
        state = PhaseDecayState.createNew()
        persistence.savePhaseDecayState(state)
    }
    
    /// Handle midnight day boundary.
    func handleDayChange() {
        // Refresh history and re-evaluate
        historyManager.refreshHistory()
        evaluateDecay()
    }
    
    // MARK: - Private
    
    private func updateSharedData() {
        // Save decay state to shared container for widgets/Live Activities
        SharedData.saveDecayState(
            currentPhase: state.currentPhase,
            baselinePhase: state.baselinePhase,
            status: state.decayStatus
        )
    }
}

/// Decay tint configuration.
struct DecayTint: Equatable {
    let color: DecayColor
    let intensity: Double
}

enum DecayColor: Equatable {
    case clear
    case yellow
    case gray
    
    var swiftUIColor: String {
        switch self {
        case .clear: return "clear"
        case .yellow: return "yellow"
        case .gray: return "gray"
        }
    }
}

// MARK: - SharedData Extension

extension SharedData {
    private static let decayCurrentPhaseKey = "decayCurrentPhase"
    private static let decayBaselinePhaseKey = "decayBaselinePhase"
    private static let decayStatusKey = "decayStatus"
    
    static func saveDecayState(currentPhase: Int, baselinePhase: Int, status: PhaseDecayStatus) {
        guard let defaults = userDefaults else { return }
        defaults.set(currentPhase, forKey: decayCurrentPhaseKey)
        defaults.set(baselinePhase, forKey: decayBaselinePhaseKey)
        defaults.set(status.rawValue, forKey: decayStatusKey)
    }
    
    static func loadDecayState() -> (currentPhase: Int, baselinePhase: Int, status: PhaseDecayStatus)? {
        guard let defaults = userDefaults else { return nil }
        
        let currentPhase = defaults.integer(forKey: decayCurrentPhaseKey)
        let baselinePhase = defaults.integer(forKey: decayBaselinePhaseKey)
        
        guard let statusRaw = defaults.string(forKey: decayStatusKey),
              let status = PhaseDecayStatus(rawValue: statusRaw) else {
            return nil
        }
        
        return (currentPhase, baselinePhase, status)
    }
}
