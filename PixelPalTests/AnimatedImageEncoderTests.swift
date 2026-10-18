import XCTest
import UIKit
@testable import PixelPal

final class AnimatedImageEncoderTests: XCTestCase {

    private func solidImage(_ color: UIColor, size: CGSize = CGSize(width: 33, height: 17)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    func test_encodeAPNG_twoFrames_producesAnimatedPNG() throws {
        // Odd dimensions put chunk lengths at unaligned offsets (the old code trapped here).
        let data = try XCTUnwrap(AnimatedImageEncoder.encodeAPNG(frames: [solidImage(.red), solidImage(.blue)]))
        XCTAssertEqual(Array(data.prefix(8)), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        XCTAssertNotNil(data.range(of: Data("acTL".utf8)), "missing animation control chunk")
    }

    func test_encodeAPNG_singleFrame_returnsNil() {
        XCTAssertNil(AnimatedImageEncoder.encodeAPNG(frames: [solidImage(.red)]))
    }

    func test_encodeGIF_twoFrames_producesGIF() throws {
        let data = try XCTUnwrap(AnimatedImageEncoder.encodeGIF(frames: [solidImage(.red), solidImage(.blue)]))
        XCTAssertEqual(String(data: data.prefix(3), encoding: .ascii), "GIF")
    }
}
