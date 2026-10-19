import SwiftUI

/// The iPhone app's Theme colors, mirrored for watchOS (the watch can't compile the UIKit-based tokens).
enum WatchPalette {
    static let purple = Color(red: 0.49, green: 0.36, blue: 0.99)
    static let mint = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let amber = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let blue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let belowGoal = Color(red: 1.0, green: 0.7, blue: 0.3).opacity(0.6)
    static let track = Color.white.opacity(0.12)
    static let noData = Color.white.opacity(0.1)

    static func phaseColor(_ phase: Int) -> Color {
        switch phase {
        case 2: return blue
        case 3: return purple
        case 4: return amber
        default: return Color(white: 0.6)
        }
    }

    static func phaseName(_ phase: Int) -> String {
        switch phase {
        case 2: return "Growing"
        case 3: return "Thriving"
        case 4: return "Legendary"
        default: return "Seedling"
        }
    }
}
