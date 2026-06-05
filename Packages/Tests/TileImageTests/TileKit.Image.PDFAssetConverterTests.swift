import Foundation
import Testing
import TileCore
import TileImage

#if canImport(CoreGraphics) && canImport(ImageIO)
    import CoreGraphics
    import ImageIO
#endif

@Suite("PDF asset image converter")
struct PDFAssetImageConverterTests {
    #if canImport(CoreGraphics) && canImport(ImageIO)
        @Test("converts an RGBA PNG to JPEG with system image APIs")
        func convertsRGBAPNGToJPEG() throws {
            let fixture = try ImageConversionFixture()
            defer { fixture.remove() }
            try rgbaPNG().write(to: fixture.source)

            let converted = TileKit.Image.PDFAssetConverter().convertToJPEG(
                sourcePath: fixture.source.path,
                destinationPath: fixture.destination.path,
            )

            #expect(converted)
            let output = try Data(contentsOf: fixture.destination)
            #expect(output.starts(with: [0xFF, 0xD8]))
            #expect(output.suffix(2) == Data([0xFF, 0xD9]))
        }

        @Test("converts a GIF to JPEG with system image APIs")
        func convertsGIFToJPEG() throws {
            let fixture = try ImageConversionFixture(sourceExtension: "gif")
            defer { fixture.remove() }
            try minimalGIF().write(to: fixture.source)

            let converted = TileKit.Image.PDFAssetConverter().convertToJPEG(
                sourcePath: fixture.source.path,
                destinationPath: fixture.destination.path,
            )

            #expect(converted)
            let output = try Data(contentsOf: fixture.destination)
            #expect(output.starts(with: [0xFF, 0xD8]))
        }
    #else
        @Test("converter is unavailable without platform image APIs")
        func converterIsUnavailableWithoutPlatformImageAPIs() {
            let converted = TileKit.Image.PDFAssetConverter().convertToJPEG(
                sourcePath: "missing.png",
                destinationPath: "missing.jpg",
            )

            #expect(!converted)
        }
    #endif
}

private struct ImageConversionFixture {
    let root: URL
    let source: URL
    let destination: URL

    init(
        sourceExtension: String = "png",
    ) throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("TileImageTests-\(UUID().uuidString)", isDirectory: true)
        source = root.appendingPathComponent("source.\(sourceExtension)")
        destination = root.appendingPathComponent("converted.jpg")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }
}

#if canImport(CoreGraphics) && canImport(ImageIO)
    private func rgbaPNG() throws -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bytesPerRow: 8,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue,
        ) else {
            throw FixtureError.invalidImage
        }

        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 0.5))
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))

        guard let image = context.makeImage(),
              let data = NSMutableData() as CFMutableData?,
              let destination = CGImageDestinationCreateWithData(
                  data,
                  "public.png" as CFString,
                  1,
                  nil,
              )
        else {
            throw FixtureError.invalidImage
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw FixtureError.invalidImage
        }
        return data as Data
    }

    private func minimalGIF() -> Data {
        Data([
            0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
            0x01, 0x00, 0x01, 0x00,
            0x80, 0x00, 0x00,
            0xFF, 0xFF, 0xFF,
            0x00, 0x00, 0x00,
            0x21, 0xF9, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00,
            0x2C,
            0x00, 0x00, 0x00, 0x00,
            0x01, 0x00, 0x01, 0x00,
            0x00,
            0x02, 0x02, 0x44, 0x01, 0x00,
            0x3B,
        ])
    }

    private enum FixtureError: Error {
        case invalidImage
    }
#endif
