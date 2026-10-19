import UIKit

/// Single entry point for haptics so every moment of the same kind feels the same.
/// Callable from any context; work hops to the main actor. Generators are reused.
enum Haptics {
    /// Primary buttons / CTAs.
    static func tap() { run { $0.medium.impactOccurred() } }
    /// Small toggles and secondary taps.
    static func soft() { run { $0.light.impactOccurred() } }
    /// Picking between options: plans, characters, chips.
    static func select() { run { $0.selection.selectionChanged() } }
    /// Mission complete. Lighter than success so stacked rewards don't feel like alerts.
    static func reward() { run { $0.rigid.impactOccurred(intensity: 0.7) } }
    /// Daily goal, streak/record celebrations, purchase/restore success.
    static func success() { run { $0.notification.notificationOccurred(.success) } }
    /// Recoverable problems (nothing to restore).
    static func warning() { run { $0.notification.notificationOccurred(.warning) } }
    /// Purchase failed.
    static func error() { run { $0.notification.notificationOccurred(.error) } }
    /// Phase evolution: success, then a heavy thump.
    static func celebrate() {
        Task { @MainActor in
            let engine = HapticEngine.shared
            engine.notification.notificationOccurred(.success)
            try? await Task.sleep(nanoseconds: 150_000_000)
            engine.heavy.impactOccurred(intensity: 0.9)
        }
    }
    /// Warm the Taptic Engine shortly before a known moment.
    static func prepare() { run { $0.prepareAll() } }

    private static func run(_ work: @escaping @Sendable @MainActor (HapticEngine) -> Void) {
        Task { @MainActor in work(HapticEngine.shared) }
    }
}

@MainActor
private final class HapticEngine {
    static let shared = HapticEngine()
    let light = UIImpactFeedbackGenerator(style: .light)
    let medium = UIImpactFeedbackGenerator(style: .medium)
    let heavy = UIImpactFeedbackGenerator(style: .heavy)
    let rigid = UIImpactFeedbackGenerator(style: .rigid)
    let selection = UISelectionFeedbackGenerator()
    let notification = UINotificationFeedbackGenerator()

    func prepareAll() {
        [light, medium, heavy, rigid].forEach { $0.prepare() }
        selection.prepare()
        notification.prepare()
    }
}
