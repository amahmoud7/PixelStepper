import SwiftUI
import UIKit

/// Motion tokens. iOS 16.0-safe: only spring(response:dampingFraction:), ease curves, repeatForever.
/// Never use Animation.smooth/.snappy/.bouncy, spring(duration:bounce:), withAnimation(completion:) — iOS 17.
enum Motion {
    static let press  = Animation.spring(response: 0.25, dampingFraction: 0.8)   // press states, toggles
    static let snappy = Animation.spring(response: 0.35, dampingFraction: 0.85)  // selection, toasts, mission check
    static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.9)    // entrances, overlays
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.65)   // celebration icon, character pick
    static let number = Animation.spring(response: 0.45, dampingFraction: 1.0)   // rolling digits, ring/bar fills
    static let fade   = Animation.easeInOut(duration: 0.2)                       // opacity-only; Reduce Motion substitute
    static let exit   = Animation.easeIn(duration: 0.25)                         // anything leaving
    static let reveal = Animation.easeOut(duration: 1.2)                         // spotlight / rings settling

    static let stagger: Double = 0.06
    static let ambientHalfCycle: Double = 2.0
    /// 2-frame sprite cadence. Keep equal to the literal in PixelPalLiveActivity.swift (widget can't see this file).
    static let spriteFrameInterval: TimeInterval = 0.8

    /// Base curve for ambientLoop (it adds repeatForever itself).
    static func ambient(_ halfCycle: Double = ambientHalfCycle) -> Animation { .easeInOut(duration: halfCycle) }
    static func staggered(_ index: Int, _ base: Animation = smooth) -> Animation { base.delay(Double(index) * stagger) }

    /// Views: pass @Environment(\.accessibilityReduceMotion).
    static func resolved(_ animation: Animation, reduceMotion: Bool) -> Animation { reduceMotion ? fade : animation }

    /// Non-view code (managers). Main actor only.
    @MainActor static var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }
    @MainActor static func resolved(_ animation: Animation) -> Animation { resolved(animation, reduceMotion: reduceMotion) }
}

/// Preferred in views: pass the environment value.
@MainActor @discardableResult
func withMotion<Result>(_ animation: Animation, reduceMotion: Bool, _ body: () throws -> Result) rethrows -> Result {
    try withAnimation(Motion.resolved(animation, reduceMotion: reduceMotion), body)
}

/// Main-actor convenience reading the system setting.
@MainActor @discardableResult
func withMotion<Result>(_ animation: Animation = Motion.snappy, _ body: () throws -> Result) rethrows -> Result {
    try withAnimation(Motion.resolved(animation), body)
}

extension AnyTransition {
    static func motionSlide(_ edge: Edge, reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: edge).combined(with: .opacity)
    }
}

private struct ReduceMotionAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? Motion.fade : animation, value: value)
    }
}

private struct NumericRoll<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: V

    func body(content: Content) -> some View {
        content
            .contentTransition(reduceMotion ? ContentTransition.identity : ContentTransition.numericText())
            .animation(reduceMotion ? nil : Motion.number, value: value)
    }
}

/// Looping flag, value-scoped so it can't leak into parent transitions and can be stopped.
/// Apply AFTER the effects that read the flag.
private struct AmbientLoop: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isAnimating: Bool
    let animation: Animation
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .animation(isAnimating ? animation.repeatForever(autoreverses: true) : Motion.fade, value: isAnimating)
            .onAppear { restart() }
            .onDisappear { isAnimating = false }
            .onChange(of: reduceMotion) { _ in restart() }
            .onChange(of: isActive) { _ in restart() }
    }

    private func restart() {
        isAnimating = false
        guard isActive, !reduceMotion else { return }
        DispatchQueue.main.async { isAnimating = true }
    }
}

extension View {
    /// `.animation(_:value:)` that swaps movement for a fade under Reduce Motion.
    func motion<V: Equatable>(_ animation: Animation = Motion.snappy, value: V) -> some View {
        modifier(ReduceMotionAnimation(animation: animation, value: value))
    }

    /// Rolling digits (iOS 16 numericText); instant under Reduce Motion.
    func numericRoll<V: Equatable>(value: V) -> some View {
        modifier(NumericRoll(value: value))
    }

    /// Drives a breathing/pulsing flag with repeat-forever, skipped under Reduce Motion.
    func ambientLoop(_ isAnimating: Binding<Bool>, animation: Animation, isActive: Bool = true) -> some View {
        modifier(AmbientLoop(isAnimating: isAnimating, animation: animation, isActive: isActive))
    }
}
