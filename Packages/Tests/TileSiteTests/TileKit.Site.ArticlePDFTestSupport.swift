import Foundation
import TileCore

#if canImport(CoreGraphics) && canImport(ImageIO)
    import CoreGraphics
    import ImageIO
#endif

final class RecordingPDFRenderer: TileKit.PDFRendering, @unchecked Sendable {
    private(set) var calls: [(markdown: String, assetsBaseURL: URL?)] = []

    func renderPDF(markdown: String) -> [UInt8]? {
        calls.append((markdown, nil))
        return Array("%PDF-1.4 stub".utf8)
    }

    func renderPDF(markdown: String, assetsBaseURL: URL?) -> [UInt8]? {
        calls.append((markdown, assetsBaseURL))
        return Array("%PDF-1.4 stub".utf8)
    }
}

struct StubPDFRenderer: TileKit.PDFRendering {
    func renderPDF(markdown _: String) -> [UInt8]? {
        Array("%PDF-1.4 stub".utf8)
    }
}

final class InspectingPDFRenderer: TileKit.PDFRendering, @unchecked Sendable {
    private let inspect: @Sendable (String, URL?) -> Void

    init(
        inspect: @escaping @Sendable (String, URL?) -> Void,
    ) {
        self.inspect = inspect
    }

    func renderPDF(markdown: String) -> [UInt8]? {
        inspect(markdown, nil)
        return Array("%PDF-1.4 stub".utf8)
    }

    func renderPDF(markdown: String, assetsBaseURL: URL?) -> [UInt8]? {
        inspect(markdown, assetsBaseURL)
        return Array("%PDF-1.4 stub".utf8)
    }
}

final class PDFAssetInspection: @unchecked Sendable {
    var didInspect = false
}

func containsPDFToken(
    _ token: String,
    in bytes: [UInt8],
) -> Bool {
    pdfTokenCount(token, in: bytes) > 0
}

func pdfTokenCount(
    _ token: String,
    in bytes: [UInt8],
) -> Int {
    let needle = Array(token.utf8)
    guard !needle.isEmpty, bytes.count >= needle.count else {
        return 0
    }
    return bytes.indices.dropLast(needle.count - 1).reduce(0) { count, index in
        Array(bytes[index ..< index + needle.count]) == needle ? count + 1 : count
    }
}

#if canImport(CoreGraphics) && canImport(ImageIO)
    func jpegExists(
        at url: URL,
    ) -> Bool {
        guard let data = try? Data(contentsOf: url) else {
            return false
        }
        return Array(data.prefix(2)) == [0xFF, 0xD8]
    }
#endif

struct LocalArticlePDFFixture {
    let root: URL
    let content: URL
    let output: URL
    let images: URL
    let article: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("TileSiteArticlePDFTests-\(UUID().uuidString)", isDirectory: true)
        content = root.appendingPathComponent("content", isDirectory: true)
        output = root.appendingPathComponent("dist", isDirectory: true)
        images = content.appendingPathComponent("images", isDirectory: true)
        article = content.appendingPathComponent("blog/cube", isDirectory: true)
        try FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: article, withIntermediateDirectories: true)
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }

    func writeContent(
        heroImage: String = "/images/hero.jpg",
        heroImageData: Data? = nil,
        bodyImage: String = "/images/body.jpg",
        bodyImageData: Data? = nil,
        writeBodyImage: Bool = true,
    ) throws {
        try homeMarkdown.write(
            to: content.appendingPathComponent("index.md"),
            atomically: true,
            encoding: .utf8,
        )
        try articleMarkdown(
            heroImage: heroImage,
            bodyImage: bodyImage,
        ).write(
            to: article.appendingPathComponent("index.md"),
            atomically: true,
            encoding: .utf8,
        )
        try (heroImageData ?? minimalJPEG()).write(
            to: imageURL(for: heroImage),
        )
        if writeBodyImage {
            try (bodyImageData ?? minimalJPEG()).write(
                to: imageURL(for: bodyImage),
            )
        }
    }

    private var homeMarkdown: String {
        """
        ---
        title: Home
        ---
        # Home
        """
    }

    private func articleMarkdown(
        heroImage: String,
        bodyImage: String,
    ) -> String {
        """
        ---
        title: Cube Post
        date: 2026-06-01
        image: \(heroImage)
        ---
        # Article Body

        ![](\(bodyImage))
        """
    }

    private func imageURL(
        for source: String,
    ) -> URL {
        let fileName = source.split(separator: "/").last.map(String.init) ?? source
        return images.appendingPathComponent(fileName.removingPercentEncoding ?? fileName)
    }

    private func minimalJPEG() -> Data {
        Data([
            0xFF, 0xD8,
            0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
            0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01,
            0x00, 0x00,
            0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01, 0x00,
            0x01, 0x03, 0x01, 0x11, 0x00, 0x02, 0x11, 0x00,
            0x03, 0x11, 0x00,
            0xFF, 0xDA, 0x00, 0x0C, 0x03, 0x01, 0x00, 0x02,
            0x11, 0x03, 0x11, 0x00, 0x3F, 0x00,
            0x00,
            0xFF, 0xD9,
        ])
    }
}

#if canImport(CoreGraphics) && canImport(ImageIO)
    func rgbaPNGForPDFTest() throws -> Data {
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
            throw PDFImageFixtureError.invalidImage
        }

        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 1, alpha: 0.5))
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
            throw PDFImageFixtureError.invalidImage
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw PDFImageFixtureError.invalidImage
        }
        return data as Data
    }

    func minimalGIFForPDFTest() -> Data {
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

    private enum PDFImageFixtureError: Error {
        case invalidImage
    }
#endif
