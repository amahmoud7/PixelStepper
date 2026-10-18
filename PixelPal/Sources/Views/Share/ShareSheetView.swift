import SwiftUI

struct ShareSheetView: View {
    let data: ShareCardData

    @State private var cardType: ShareCardType = .dailyProgress
    @State private var format: ShareCardFormat = .story
    @State private var background: ShareCardBackground = .darkGlow
    @State private var toastMessage: String?
    @State private var showPaywall: Bool = false
    @State private var toastTask: Task<Void, Never>?

    // Held in @State so they survive view rebuilds instead of being re-created each time.
    @State private var renderer = ShareCardRenderer()
    @State private var destinationManager = ShareDestinationManager()

    /// Live store, so buying Premium from the paywall sheet unlocks backgrounds immediately.
    @ObservedObject private var store = StoreManager.shared

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPremium: Bool { data.isPremium || store.isPremium }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                Text("Share your progress")
                    .font(.ppStat)
                    .foregroundColor(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Space.l)
                    .padding(.bottom, Space.m)

                // Card type tabs
                HStack(spacing: Space.s) {
                    ForEach(ShareCardType.allCases, id: \.self) { type in
                        pill(title: type.title, horizontalPadding: 14, isSelected: cardType == type) {
                            cardType = type
                        }
                    }
                }

                // Format toggle
                HStack(spacing: Space.s) {
                    ForEach(ShareCardFormat.allCases, id: \.self) { fmt in
                        pill(title: fmt.title, horizontalPadding: 18, isSelected: format == fmt) {
                            format = fmt
                        }
                    }
                }
                .padding(.bottom, Space.xs)

                // Background label
                Text("Background")
                    .font(.ppCaption.weight(.semibold))
                    .foregroundColor(Theme.textTertiary)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 6)

                // Background picker
                HStack(spacing: Space.m) {
                    ForEach(ShareCardBackground.allCases, id: \.self) { bg in
                        let isLocked = bg.requiresPremium && !isPremium
                        Button {
                            if isLocked {
                                Haptics.soft()
                                showPaywall = true
                            } else {
                                Haptics.select()
                                withMotion(Motion.snappy, reduceMotion: reduceMotion) { background = bg }
                            }
                        } label: {
                            backgroundThumbnail(bg)
                        }
                        .buttonStyle(PPPressableStyle())
                        .accessibilityLabel(isLocked ? "\(bg.title) background, Premium" : "\(bg.title) background")
                        .accessibilityAddTraits(background == bg ? .isSelected : [])
                    }
                }
                .padding(.bottom, Space.m)

                // Card preview (centered, fills remaining space). Owns its own sprite loop
                // so the frame toggle doesn't rebuild the whole sheet.
                CardPreview(
                    renderer: renderer,
                    cardType: cardType,
                    data: data,
                    format: format,
                    background: background
                )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Space.screen)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Card preview")

                Spacer(minLength: Space.m)

                // Action buttons — 4 squares side by side
                actionButtons
                    .padding(.horizontal, Space.screen)
                    .padding(.bottom, 28)
            }
            // The live card preview needs most of the screen; keep controls compact.
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)

            // Toast overlay
            if let message = toastMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.ppBody.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal, Space.screen)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(.bottom, 100)
                }
                .transition(.motionSlide(.bottom, reduceMotion: reduceMotion))
                .zIndex(1)
                .accessibilityHidden(true)
            }
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) {
            PaywallView(storeManager: store, gender: data.gender, currentPhase: data.currentPhase)
        }
    }

    // MARK: - Pills

    private func pill(title: String, horizontalPadding: CGFloat, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            withMotion(Motion.snappy, reduceMotion: reduceMotion) { action() }
        } label: {
            Text(title)
                .font(.ppRowTitle)
                .lineLimit(1)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 7)
                .background(isSelected ? Theme.surfaceStrong : Theme.surface)
                .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
                )
                .minTapTarget()
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Space.m) {
            // Instagram Story
            actionButton(
                icon: "camera.fill",
                label: "Instagram",
                gradient: [
                    Color(red: 0.93, green: 0.27, blue: 0.47),
                    Color(red: 0.6, green: 0.2, blue: 0.8)
                ]
            ) {
                shareToInstagramStory()
            }

            // Save GIF to Photos
            actionButton(
                icon: "arrow.down.to.line",
                label: "Save GIF",
                gradient: nil
            ) {
                saveToPhotos()
            }

            // Copy to Clipboard
            actionButton(
                icon: "doc.on.doc",
                label: "Copy",
                gradient: nil
            ) {
                copyToClipboard()
            }

            // Share
            actionButton(
                icon: "square.and.arrow.up",
                label: "Share",
                gradient: nil
            ) {
                shareGeneral()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func actionButton(
        icon: String,
        label: String,
        gradient: [Color]?,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.ppSection.weight(.semibold))
                    .accessibilityHidden(true)
                Text(label)
                    .font(.ppMicro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(.white)
            .padding(.vertical, Space.s)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(
                Group {
                    if let colors = gradient {
                        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        Color.white.opacity(0.08)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .stroke(gradient == nil ? Color.white.opacity(0.1) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PPPressableStyle())
    }

    // MARK: - Background Thumbnail

    @ViewBuilder
    private func backgroundThumbnail(_ bg: ShareCardBackground) -> some View {
        let isSelected = background == bg
        let isLocked = bg.requiresPremium && !isPremium

        VStack(spacing: 3) {
            ZStack {
                if bg == .transparent {
                    Checkerboard()
                } else {
                    ShareCardBackgroundView(background: bg, format: .square)
                }

                if isLocked {
                    Color.black.opacity(0.5)
                    Image(systemName: "lock.fill")
                        .font(.ppCaption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color.white : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )

            Text(bg.title)
                .font(.ppMicro)
                .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
        }
    }

    // MARK: - Actions

    private func renderCurrentCard() -> UIImage? {
        renderer.renderImage(
            cardType: cardType,
            data: data,
            format: format,
            background: background,
            spriteFrame: 1
        )
    }

    private func renderGIF() -> Data? {
        renderer.renderGIFData(
            cardType: cardType,
            data: data,
            format: format,
            background: background
        )
    }

    private func shareToInstagramStory() {
        guard destinationManager.isInstagramAvailable else {
            showFailure("Instagram not installed")
            return
        }

        if background == .transparent {
            guard let apngData = renderer.renderAPNGData(
                cardType: cardType,
                data: data,
                format: format,
                background: background
            ) else {
                showFailure("Couldn't create image")
                return
            }
            destinationManager.shareAPNGStickerToInstagramStory(apngData: apngData)
        } else {
            guard let image = renderCurrentCard() else {
                showFailure("Couldn't create image")
                return
            }
            destinationManager.shareBackgroundToInstagramStory(backgroundImage: image)
        }
    }

    private func saveToPhotos() {
        guard let gifData = renderGIF() else {
            showFailure("Couldn't create image")
            return
        }
        destinationManager.saveGIFToPhotos(data: gifData) { success in
            if success {
                Haptics.success()
                showToast("Saved to Photos")
            } else {
                showFailure("Couldn't save to Photos")
            }
        }
    }

    private func copyToClipboard() {
        guard let image = renderCurrentCard() else {
            showFailure("Couldn't create image")
            return
        }
        destinationManager.copyToClipboard(image: image)
        Haptics.success()
        showToast("Copied to clipboard")
    }

    private func shareGeneral() {
        guard let image = renderCurrentCard() else {
            showFailure("Couldn't create image")
            return
        }
        destinationManager.presentShareSheet(image: image)
    }

    private func showFailure(_ message: String) {
        Haptics.warning()
        showToast(message)
    }

    private func showToast(_ message: String) {
        withMotion(Motion.snappy, reduceMotion: reduceMotion) {
            toastMessage = message
        }
        UIAccessibility.post(notification: .announcement, argument: message)

        // Cancel the previous dismissal so an older toast can't clear a newer one.
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            withMotion(Motion.exit, reduceMotion: reduceMotion) {
                toastMessage = nil
            }
        }
    }
}

// MARK: - Card Preview

/// Live, scaled card preview. Owns the sprite frame loop so only this view re-renders on each tick.
private struct CardPreview: View {
    let renderer: ShareCardRenderer
    let cardType: ShareCardType
    let data: ShareCardData
    let format: ShareCardFormat
    let background: ShareCardBackground

    @State private var spriteFrame: Int = 1

    var body: some View {
        GeometryReader { geo in
            let maxWidth = geo.size.width
            let maxHeight = geo.size.height
            let cardAspect = format.pointSize.width / format.pointSize.height
            let fitWidth = min(maxWidth, maxHeight * cardAspect)
            let fitHeight = fitWidth / cardAspect
            let scale = fitWidth / format.pointSize.width

            ZStack {
                // Checkerboard behind card when transparent
                if background == .transparent {
                    Checkerboard()
                        .frame(width: fitWidth, height: fitHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                renderer.cardView(
                    type: cardType,
                    data: data,
                    format: format,
                    background: background,
                    spriteFrame: spriteFrame
                )
                .scaleEffect(scale)
                .frame(width: fitWidth, height: fitHeight)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .task { @MainActor in
            let nanoseconds = UInt64(Motion.spriteFrameInterval * 1_000_000_000)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: nanoseconds)
                spriteFrame = spriteFrame == 1 ? 2 : 1
            }
        }
    }
}

// MARK: - Checkerboard

/// Transparency indicator drawn behind the "Clear" background.
private struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let cellSize: CGFloat = 6
            let rows = Int(size.height / cellSize) + 1
            let cols = Int(size.width / cellSize) + 1

            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * cellSize,
                        y: CGFloat(row) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isLight ? Color(white: 0.25) : Color(white: 0.15))
                    )
                }
            }
        }
    }
}
