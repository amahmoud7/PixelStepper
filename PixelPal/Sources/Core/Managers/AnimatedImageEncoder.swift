import UIKit
import ImageIO

/// Encodes animated GIF and APNG images from an array of UIImage frames.
struct AnimatedImageEncoder {

    // MARK: - Animated GIF

    static func encodeGIF(frames: [UIImage], delayTime: Double = 0.6) -> Data? {
        let cgImages = frames.compactMap { $0.cgImage }
        guard cgImages.count == frames.count else { return nil }

        let gifData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            gifData,
            "com.compuserve.gif" as CFString,
            cgImages.count,
            nil
        ) else { return nil }

        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        let frameProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: delayTime
            ]
        ]

        for cgImage in cgImages {
            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else { return nil }
        return gifData as Data
    }

    // MARK: - Animated PNG (APNG)

    static func encodeAPNG(frames: [UIImage], delayMilliseconds: UInt16 = 600) -> Data? {
        let pngDataArray = frames.compactMap { $0.pngData() }
        guard pngDataArray.count == frames.count, pngDataArray.count >= 2 else { return nil }

        let allChunks = pngDataArray.map { parsePNGChunks($0) }

        guard let ihdr = allChunks[0].first(where: { $0.type == "IHDR" }) else { return nil }

        let allIDATChunks = allChunks.map { chunks in chunks.filter { $0.type == "IDAT" } }
        guard allIDATChunks.allSatisfy({ !$0.isEmpty }) else { return nil }

        guard ihdr.data.count >= 8 else { return nil }
        let width = ihdr.data.uint32BE(at: 0)
        let height = ihdr.data.uint32BE(at: 4)

        var result = Data()

        // PNG signature
        result.append(contentsOf: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

        // IHDR
        result.append(buildChunk(type: "IHDR", data: ihdr.data))

        // Ancillary chunks from first frame (sRGB, gAMA, pHYs, etc.)
        for chunk in allChunks[0] where chunk.type != "IHDR" && chunk.type != "IDAT" && chunk.type != "IEND" {
            result.append(buildChunk(type: chunk.type, data: chunk.data))
        }

        // acTL (animation control)
        var acTLData = Data()
        acTLData.appendUInt32BE(UInt32(frames.count))
        acTLData.appendUInt32BE(0) // num_plays: 0 = infinite loop
        result.append(buildChunk(type: "acTL", data: acTLData))

        var seq: UInt32 = 0

        // Frame 1: fcTL + IDAT (backwards-compatible with static PNG viewers)
        result.append(buildFcTL(seq: seq, width: width, height: height, delayNum: delayMilliseconds, delayDen: 1000))
        seq += 1

        for idat in allIDATChunks[0] {
            result.append(buildChunk(type: "IDAT", data: idat.data))
        }

        // Subsequent frames: fcTL + fdAT
        for frameIndex in 1..<frames.count {
            result.append(buildFcTL(seq: seq, width: width, height: height, delayNum: delayMilliseconds, delayDen: 1000))
            seq += 1

            for idat in allIDATChunks[frameIndex] {
                var fdATData = Data()
                fdATData.appendUInt32BE(seq)
                seq += 1
                fdATData.append(idat.data)
                result.append(buildChunk(type: "fdAT", data: fdATData))
            }
        }

        // IEND
        result.append(buildChunk(type: "IEND", data: Data()))

        return result
    }

    // MARK: - PNG Chunk Parsing

    private struct PNGChunk {
        let type: String
        let data: Data
    }

    private static func parsePNGChunks(_ pngData: Data) -> [PNGChunk] {
        var chunks: [PNGChunk] = []
        var offset = 8 // Skip 8-byte PNG signature

        while offset + 12 <= pngData.count {
            // Byte-wise read: chunk offsets aren't 4-byte aligned, and an aligned load traps.
            let length = pngData.uint32BE(at: offset)

            let typeEnd = offset + 8
            guard typeEnd <= pngData.count else { break }
            let typeData = pngData[(offset + 4)..<typeEnd]
            let type = String(data: typeData, encoding: .ascii) ?? ""

            let dataEnd = offset + 8 + Int(length)
            guard dataEnd <= pngData.count else { break }
            let chunkData = pngData[(offset + 8)..<dataEnd]

            chunks.append(PNGChunk(type: type, data: Data(chunkData)))

            offset = dataEnd + 4 // Skip 4-byte CRC
            if type == "IEND" { break }
        }

        return chunks
    }

    // MARK: - Chunk Construction

    private static func buildChunk(type: String, data: Data) -> Data {
        var chunk = Data()

        // 4-byte length (big-endian)
        var length = UInt32(data.count).bigEndian
        chunk.append(Data(bytes: &length, count: 4))

        // 4-byte type
        let typeData = Data(type.utf8)
        chunk.append(typeData)

        // Chunk data
        chunk.append(data)

        // 4-byte CRC over type + data
        var crcInput = Data()
        crcInput.append(typeData)
        crcInput.append(data)
        var crcValue = computeCRC32(crcInput).bigEndian
        chunk.append(Data(bytes: &crcValue, count: 4))

        return chunk
    }

    private static func buildFcTL(
        seq: UInt32,
        width: UInt32,
        height: UInt32,
        delayNum: UInt16,
        delayDen: UInt16
    ) -> Data {
        var data = Data()
        data.appendUInt32BE(seq)
        data.appendUInt32BE(width)
        data.appendUInt32BE(height)
        data.appendUInt32BE(0) // x_offset
        data.appendUInt32BE(0) // y_offset
        data.appendUInt16BE(delayNum)
        data.appendUInt16BE(delayDen)
        data.append(0) // dispose_op: APNG_DISPOSE_OP_NONE
        data.append(0) // blend_op: APNG_BLEND_OP_SOURCE
        return buildChunk(type: "fcTL", data: data)
    }

    // MARK: - CRC32

    private static let crc32Table: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1 != 0) ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()

    private static func computeCRC32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc = crc32Table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}

// MARK: - Data Helpers

private extension Data {
    /// Big-endian UInt32 at a byte offset relative to `startIndex` (alignment-safe, slice-safe).
    func uint32BE(at offset: Int) -> UInt32 {
        let i = startIndex + offset
        let b0 = UInt32(self[i]) << 24
        let b1 = UInt32(self[i + 1]) << 16
        let b2 = UInt32(self[i + 2]) << 8
        let b3 = UInt32(self[i + 3])
        return b0 | b1 | b2 | b3
    }

    mutating func appendUInt32BE(_ value: UInt32) {
        var bigEndian = value.bigEndian
        append(Data(bytes: &bigEndian, count: 4))
    }

    mutating func appendUInt16BE(_ value: UInt16) {
        var bigEndian = value.bigEndian
        append(Data(bytes: &bigEndian, count: 2))
    }
}
