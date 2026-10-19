import SwiftUI

// MARK: - Colors (dark-only app; Info.plist sets UIUserInterfaceStyle = Dark)

enum Theme {
    // Brand
    static let purple     = Color(red: 0.49, green: 0.36, blue: 0.99)
    static let purpleDeep = Color(red: 0.36, green: 0.25, blue: 0.83)
    static let purpleText = Color(red: 0.66, green: 0.58, blue: 1.0)   // small purple text, ~7.8:1
    static let cyan       = Color(red: 0.0, green: 0.83, blue: 1.0)
    static let mint       = Color(red: 0.2, green: 0.78, blue: 0.35)   // success / goal met
    static let gold       = Color(red: 1.0, green: 0.84, blue: 0.0)    // coins, rewards
    static let amber      = Color(red: 1.0, green: 0.6, blue: 0.0)     // streaks, phase 4
    static let blue       = Color(red: 0.0, green: 0.48, blue: 1.0)

    // Backgrounds
    static let bgDeep = Color(red: 0.05, green: 0.02, blue: 0.15)
    static let bgMid  = Color(red: 0.08, green: 0.03, blue: 0.20)
    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [bgDeep, bgMid, bgDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Text on dark. Never go below textTertiary for meaningful text.
    static let textPrimary    = Color.white
    static let textSecondary  = Color.white.opacity(0.7)
    static let textTertiary   = Color.white.opacity(0.6)
    static let textDecorative = Color.white.opacity(0.35)   // disabled / ornament only

    // Surfaces
    static let surface       = Color.white.opacity(0.05)
    static let surfaceStrong = Color.white.opacity(0.12)
    static let stroke        = Color.white.opacity(0.08)

    // Status (no red for "below goal": no-shame rule)
    static let goalMet   = mint
    static let belowGoal = Color(red: 1.0, green: 0.7, blue: 0.3).opacity(0.6)
    static let noData    = Color.white.opacity(0.08)
    static let today     = blue

    // Phases (single source of truth)
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

    static func phaseIcon(_ phase: Int) -> String {
        switch phase {
        case 2: return "circle.fill"
        case 3: return "star.fill"
        case 4: return "sparkles"
        default: return "circle"
        }
    }
}

// MARK: - Spacing & Radii

enum Space {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let screen: CGFloat = 20   // horizontal gutter, all tabs
}

enum Radius {
    static let chip: CGFloat = 8
    static let row: CGFloat = 12
    static let button: CGFloat = 14
    static let card: CGFloat = 16
}

// MARK: - Type scale (text styles, so everything follows Dynamic Type)

extension Font {
    static let ppLargeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)  // 34
    static let ppTitle      = Font.system(.title, design: .rounded).weight(.bold)       // 28
    static let ppStat       = Font.system(.title2, design: .rounded).weight(.bold)      // 22
    static let ppSection    = Font.system(.headline, design: .rounded).weight(.bold)    // 17
    static let ppButton     = Font.system(.headline, design: .rounded).weight(.bold)    // 17
    static let ppBody       = Font.system(.subheadline).weight(.medium)                 // 15
    static let ppRowTitle   = Font.system(.footnote).weight(.semibold)                  // 13
    static let ppCaption    = Font.system(.caption).weight(.medium)                     // 12
    static let ppMicro      = Font.system(.caption2).weight(.medium)                    // 11 (floor)
    static let ppOverline   = Font.system(.caption2).weight(.semibold)                  // pair with .tracking(1)
}

// MARK: - Components

struct PPCard: ViewModifier {
    var padding: CGFloat = Space.l
    var radius: CGFloat = Radius.card
    var tint: Color? = nil

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(tint.map { $0.opacity(0.08) } ?? Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(tint.map { $0.opacity(0.2) } ?? Theme.stroke, lineWidth: 1)
                    )
            )
    }
}

struct PPPrimaryButtonStyle: ButtonStyle {
    var colors: [Color] = [Theme.purple, Theme.purpleDeep]
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ppButton)
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            .shadow(color: colors.first?.opacity(0.35) ?? .clear, radius: 14, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Motion.press, value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

/// Subtle press feedback for card-like buttons.
struct PPPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

extension View {
    func ppCard(padding: CGFloat = Space.l, radius: CGFloat = Radius.card, tint: Color? = nil) -> some View {
        modifier(PPCard(padding: padding, radius: radius, tint: tint))
    }

    /// Ensures a 44x44pt hit area without changing visuals.
    func minTapTarget() -> some View {
        frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
    }
}
