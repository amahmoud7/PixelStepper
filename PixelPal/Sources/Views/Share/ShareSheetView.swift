import SwiftUI

struct ShareSheetView: View {
    let data: ShareCardData

    @State private var cardType: ShareCardType = .dailyProgress
    @State private var format: ShareCardFormat = .story
    @State private var background: ShareCardBackground = .darkGlow
    @State private var toastMessage: String?
    @State private var showPaywall: Bool = false
    @State private var toastTask: Task<Void, Never>?

    /// Still image of the current card config, rendered when the config changes so ShareLink always has an item.
    @State private var renderedImage: UIImage?
    @State private var renderFailed = false

    // Held in @State so they survive view rebuilds instead of being re-created each time.
    @State private var renderer = ShareCardRenderer()
    @State private var destinationManager = ShareDestinationManager()

    /// Live store, so buying Premium from the paywall sheet unlocks backgrounds immediately.
    @ObservedObject private var store = StoreManager.shared

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPremium: Bool { data.isPremium || store.isPremium }

    private var renderConfig: RenderConfig {
        RenderConfig(cardType: cardType, format: format, background: background)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.12)
                    .ignoresSafeArea()

                VStack(spacing: Space.m) {
                    // Card type and format
                    Picker("Card", selection: $cardType) {
                        ForEach(ShareCardType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Format", selection: $format) {
                        ForEach(ShareCardFormat.allCases, id: \.self) { fmt in
                            Text(fmt.title).tag(fmt)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Background picker
                    VStack(spacing: 6) {
                        Text("Background")
                            .font(.ppCaption.weight(.semibold))
                            .foregroundColor(Theme.textTertiary)
                            .accessibilityAddTraits(.isHeader)

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
                    }

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
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Card preview")

                    actionButtons
                }
                .padding(.horizontal, Space.screen)
                .padding(.top, Space.s)
                .padding(.bottom, Space.l)
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
                            .padding(.bottom, 140)
                    }
                    .transition(.motionSlide(.bottom, reduceMotion: reduceMotion))
                    .zIndex(1)
                    .accessibilityHidden(true)
                }
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Theme.purpleText)
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) {
            PaywallView(storeManager: store, gender: data.gender, currentPhase: data.currentPhase)
        }
        .onChange(of: cardType) { _ in Haptics.select() }
        .onChange(of: format) { _ in Haptics.select() }
        .task(id: renderConfig) { @MainActor in
            renderCurrentImage()
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Space.s) {
            // Primary: system share sheet (covers Messages, copy, save image, etc.)
            if let image = renderedImage {
                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview("My progress", image: Image(uiImage: image))
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PPPrimaryButtonStyle(colors: [Theme.purple, Theme.purpleDeep]))
                .simultaneousGesture(TapGesture().onEnded { Haptics.tap() })
            } else {
                Button {
                    if renderFailed { showFailure("Couldn't create image") }
                } label: {
                    if renderFailed {
                        Label("Share", systemImage: "square.and.arrow.up")
                    } else {
                        ProgressView().tint(.white)
                    }
                }
                .buttonStyle(PPPrimaryButtonStyle(colors: [Theme.purple, Theme.purpleDeep]))
                .accessibilityLabel("Share")
            }

            // Secondary
            HStack(spacing: Space.m) {
                secondaryButton(icon: "camera.fill", label: "Instagram Stories") {
                    shareToInstagramStory()
                }
                secondaryButton(icon: "arrow.down.to.line", label: "Save GIF") {
                    saveToPhotos()
                }
            }
        }
    }

    private func secondaryButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Label(label, systemImage: icon)
                .font(.ppBody.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                        .fill(Theme.surfaceStrong)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
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

    private func renderCurrentImage() {
        let image = renderCurrentCard()
        renderedImage = image
        renderFailed = image == nil
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
            guard let image = renderedImage ?? renderCurrentCard() else {
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

/// The inputs that change the exported image; re-rendered whenever this changes.
private struct RenderConfig: Equatable {
    let cardType: ShareCardType
    let format: ShareCardFormat
    let background: ShareCardBackground
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
