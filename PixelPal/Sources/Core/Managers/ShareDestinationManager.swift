import UIKit
import Photos

@MainActor
final class ShareDestinationManager {

    private static let facebookAppID = "1437491044650461"

    var isInstagramAvailable: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: - Instagram Story Sticker

    func shareStickerToInstagramStory(
        stickerImage: UIImage,
        topColor: String = "#0A0A1F",
        bottomColor: String = "#1A0A2E"
    ) {
        guard let url = URL(string: "instagram-stories://share?source_application=\(Self.facebookAppID)"),
              UIApplication.shared.canOpenURL(url) else { return }

        guard let stickerData = stickerImage.pngData() else { return }

        let items: [[String: Any]] = [[
            "com.instagram.sharedSticker.stickerImage": stickerData,
            "com.instagram.sharedSticker.backgroundTopColor": topColor,
            "com.instagram.sharedSticker.backgroundBottomColor": bottomColor
        ]]

        UIPasteboard.general.setItems(items, options: [
            .expirationDate: Date().addingTimeInterval(300)
        ])

        UIApplication.shared.open(url)
    }

    func shareBackgroundToInstagramStory(backgroundImage: UIImage) {
        guard let url = URL(string: "instagram-stories://share?source_application=\(Self.facebookAppID)"),
              UIApplication.shared.canOpenURL(url) else { return }

        guard let imageData = backgroundImage.pngData() else { return }

        let items: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]]

        UIPasteboard.general.setItems(items, options: [
            .expirationDate: Date().addingTimeInterval(300)
        ])

        UIApplication.shared.open(url)
    }

    // MARK: - APNG Instagram Story Sticker (Experiment)

    func shareAPNGStickerToInstagramStory(
        apngData: Data,
        topColor: String = "#0A0A1F",
        bottomColor: String = "#1A0A2E"
    ) {
        guard let url = URL(string: "instagram-stories://share?source_application=\(Self.facebookAppID)"),
              UIApplication.shared.canOpenURL(url) else { return }

        let items: [[String: Any]] = [[
            "com.instagram.sharedSticker.stickerImage": apngData,
            "com.instagram.sharedSticker.backgroundTopColor": topColor,
            "com.instagram.sharedSticker.backgroundBottomColor": bottomColor
        ]]

        UIPasteboard.general.setItems(items, options: [
            .expirationDate: Date().addingTimeInterval(300)
        ])

        UIApplication.shared.open(url)
    }

    // MARK: - Instagram Story Video Background

    func shareVideoToInstagramStory(videoURL: URL) {
        guard let url = URL(string: "instagram-stories://share?source_application=\(Self.facebookAppID)"),
              UIApplication.shared.canOpenURL(url) else { return }

        guard let videoData = try? Data(contentsOf: videoURL) else { return }

        let items: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundVideo": videoData
        ]]

        UIPasteboard.general.setItems(items, options: [
            .expirationDate: Date().addingTimeInterval(300)
        ])

        UIApplication.shared.open(url)
    }

    // MARK: - Copy to Clipboard

    func copyToClipboard(image: UIImage) {
        UIPasteboard.general.image = image
    }

    // MARK: - Save to Photos

    func saveToPhotos(image: UIImage, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            DispatchQueue.main.async { completion(true) }
        }
    }

    func saveGIFToPhotos(data: Data, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.uniformTypeIdentifier = "com.compuserve.gif"
                request.addResource(with: .photo, data: data, options: options)
            } completionHandler: { success, _ in
                DispatchQueue.main.async { completion(success) }
            }
        }
    }

    // MARK: - Save GIF to Files

    func saveGIFToFiles(data: Data) {
        let fileName = "PixelStepper_\(Self.dateStamp()).gif"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: tempURL)
        } catch {
            return
        }

        let picker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: true)
        presentDocumentPicker(picker)
    }

    private static func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }

    private func presentDocumentPicker(_ picker: UIDocumentPickerViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        topVC.present(picker, animated: true)
    }

    // MARK: - General Share Sheet

    func presentShareSheet(image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        presentActivityViewController(activityVC)
    }

    func presentShareSheet(gifData: Data) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("pixelstepper_\(UUID().uuidString).gif")
        do {
            try gifData.write(to: tempURL)
        } catch {
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
        presentActivityViewController(activityVC)
    }

    // MARK: - Private

    private func presentActivityViewController(_ vc: UIActivityViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        if let popover = vc.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0,
                height: 0
            )
        }

        topVC.present(vc, animated: true)
    }
}
