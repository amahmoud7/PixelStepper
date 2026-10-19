import SwiftUI

struct AvatarView: View {
    let state: AvatarState
    let gender: Gender
    let phase: Int
    var isWalking: Bool = false
    var size: CGFloat = 200
    var loadout: CosmeticLoadout? = nil
    /// Pop in from 0.5x on first appear. Off by default so tab switches don't replay it.
    var animatesEntrance: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var idleFrame: Int = 1
    @State private var walkingFrame: Int = 1
    @State private var bobOffset: CGFloat = 0
    @State private var appeared: Bool = false

    private var spriteName: String {
        if isWalking {
            return SpriteAssets.walkingSpriteName(gender: gender, frame: walkingFrame)
        }
        return SpriteAssets.spriteName(gender: gender, state: state, frame: idleFrame)
    }

    private var phaseColor: Color { Theme.phaseColor(phase) }

    var body: some View {
        ZStack {
            // Layer 1: Background (cosmetic or default phase glow)
            if let bgID = loadout?.background,
               let item = CosmeticCatalog.item(id: bgID) {
                Image(decorative: item.assetName)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: size * 1.2, height: size * 1.2)
            } else {
                // Default phase-colored radial glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [phaseColor.opacity(0.15), .clear],
                            center: .center,
                            startRadius: size * 0.15,
                            endRadius: size * 0.55
                        )
                    )
                    .frame(width: size * 1.2, height: size * 1.2)
            }

            // Layer 2: Character sprite (skin replaces entire character)
            if let skinID = loadout?.skin,
               let skinItem = CosmeticCatalog.item(id: skinID) {
                // Full skin replacement — no hat/accessory overlays
                Image(decorative: skinItem.assetName)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .offset(y: isWalking ? 0 : bobOffset)
            } else {
                // Default character sprite + overlays
                Image(decorative: spriteName)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .offset(y: isWalking ? 0 : bobOffset)

                // Layer 3: Hat overlay
                if let hatID = loadout?.hat,
                   let item = CosmeticCatalog.item(id: hatID) {
                    Image(decorative: item.assetName)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: size * 0.6, height: size * 0.6)
                        .offset(y: -size * 0.3)
                        .offset(y: isWalking ? 0 : bobOffset)
                }

                // Layer 4: Accessory overlay
                if let accID = loadout?.accessory,
                   let item = CosmeticCatalog.item(id: accID) {
                    Image(decorative: item.assetName)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: size * 0.5, height: size * 0.5)
                        .offset(x: size * 0.25)
                        .offset(y: isWalking ? 0 : bobOffset)
                }
            }
        }
        .scaleEffect(appeared || !animatesEntrance || reduceMotion ? 1.0 : 0.5)
        .opacity(appeared || !animatesEntrance ? 1.0 : 0)
        .onAppear {
            guard animatesEntrance, !appeared else { return }
            withMotion(Motion.bouncy, reduceMotion: reduceMotion) {
                appeared = true
            }
        }
        // One lightweight loop instead of always-on Timer publishers:
        // 24fps only while walking, a 2-frame idle toggle otherwise.
        // Restarts when walking or Reduce Motion changes, so the bob can settle/resume.
        .task(id: [isWalking, reduceMotion]) {
            if !isWalking { walkingFrame = 1 }
            let interval: UInt64 = isWalking
                ? 42_000_000
                : UInt64(Motion.spriteFrameInterval * 1_000_000_000)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: interval)
                if Task.isCancelled { break }
                if isWalking {
                    walkingFrame = (walkingFrame % SpriteAssets.walkingFrameCount) + 1
                } else {
                    idleFrame = idleFrame == 1 ? 2 : 1
                    // Pixel-style bob in step with the idle frame; none under Reduce Motion.
                    let target: CGFloat = reduceMotion ? 0 : (idleFrame == 1 ? 0 : -2)
                    if target != bobOffset {
                        withMotion(Motion.snappy, reduceMotion: reduceMotion) { bobOffset = target }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your character, \(Theme.phaseName(phase)) phase, \(state.description.lowercased())")
    }
}
