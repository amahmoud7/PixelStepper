import SwiftUI

@MainActor
final class ShareCardRenderer {

    // MARK: - Static Image Rendering

    func renderImage(
        cardType: ShareCardType,
        data: ShareCardData,
        format: ShareCardFormat,
        background: ShareCardBackground,
        spriteFrame: Int = 1
    ) -> UIImage? {
        let view = cardView(type: cardType, data: data, format: format, background: background, spriteFrame: spriteFrame)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        renderer.isOpaque = !background.isTransparent
        return renderer.uiImage
    }

    // MARK: - Animated GIF

    func renderGIFData(
        cardType: ShareCardType,
        data: ShareCardData,
        format: ShareCardFormat,
        background: ShareCardBackground
    ) -> Data? {
        guard let frame1 = renderImage(cardType: cardType, data: data, format: format, background: background, spriteFrame: 1),
              let frame2 = renderImage(cardType: cardType, data: data, format: format, background: background, spriteFrame: 2) else { return nil }
        return AnimatedImageEncoder.encodeGIF(frames: [frame1, frame2])
    }

    // MARK: - Animated PNG (APNG)

    func renderAPNGData(
        cardType: ShareCardType,
        data: ShareCardData,
        format: ShareCardFormat,
        background: ShareCardBackground
    ) -> Data? {
        guard let frame1 = renderImage(cardType: cardType, data: data, format: format, background: background, spriteFrame: 1),
              let frame2 = renderImage(cardType: cardType, data: data, format: format, background: background, spriteFrame: 2) else { return nil }
        return AnimatedImageEncoder.encodeAPNG(frames: [frame1, frame2])
    }

    // MARK: - Card View Factory

    @ViewBuilder
    func cardView(
        type: ShareCardType,
        data: ShareCardData,
        format: ShareCardFormat,
        background: ShareCardBackground,
        spriteFrame: Int = 1
    ) -> some View {
        switch type {
        case .dailyProgress:
            DailyProgressCard(data: data, format: format, background: background, spriteFrame: spriteFrame)
        case .evolutionMilestone:
            EvolutionMilestoneCard(data: data, format: format, background: background, spriteFrame: spriteFrame)
        case .weeklySummary:
            WeeklySummaryCard(data: data, format: format, background: background, spriteFrame: spriteFrame)
        case .streak:
            StreakShareCard(data: data, format: format, background: background, spriteFrame: spriteFrame)
        }
    }
}
