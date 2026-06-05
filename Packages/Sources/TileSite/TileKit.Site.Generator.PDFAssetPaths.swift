import Foundation
import TileCore

extension TileKit.Site.Generator {
    func decodedLocalPDFPath(
        _ path: String,
    ) -> String {
        path.removingPercentEncoding ?? path
    }

    func markdownPDFImageDestination(
        _ path: String,
        isAngleWrapped: Bool,
    ) -> String {
        if isAngleWrapped || !needsAngleWrappedMarkdownDestination(path) {
            return path
        }
        return "<\(path)>"
    }

    func safePDFAssetPath(
        _ path: String,
    ) -> String {
        let hash = stablePDFAssetHash(path)
        let components = path
            .split(separator: "/", omittingEmptySubsequences: false)
            .map(String.init)
        return components.enumerated()
            .map { offset, component in
                safePDFAssetComponent(
                    component,
                    isFileName: offset == components.count - 1,
                    hash: hash,
                )
            }
            .joined(separator: "/")
    }

    func normalizedRelativePath(
        _ path: String,
    ) -> String? {
        var components: [String] = []
        for component in path.split(separator: "/", omittingEmptySubsequences: false) {
            if component.isEmpty || component == "." {
                continue
            }
            if component == ".." {
                guard !components.isEmpty else {
                    return nil
                }
                components.removeLast()
                continue
            }
            components.append(String(component))
        }
        let normalized = components.joined(separator: "/")
        return normalized.isEmpty ? nil : normalized
    }

    func longestOutputPathFirst(
        _ lhs: TileKit.Site.StaticPassthrough,
        _ rhs: TileKit.Site.StaticPassthrough,
    ) -> Bool {
        lhs.outputPath.count > rhs.outputPath.count
    }
}

struct PDFAssetMapping {
    var sourcePath: String
    var pdfPath: String
}

private func needsAngleWrappedMarkdownDestination(
    _ path: String,
) -> Bool {
    path.contains { character in
        character.isWhitespace || character == "(" || character == ")"
    }
}

private func safePDFAssetComponent(
    _ component: String,
    isFileName: Bool,
    hash: String,
) -> String {
    let sanitized = component.unicodeScalars.map { scalar in
        safePDFAssetScalar(scalar) ? String(scalar) : "_"
    }
    .joined()

    let safe = sanitized.isEmpty ? "asset" : sanitized
    guard isFileName, safe != component else {
        return safe
    }

    let fileExtension = URL(fileURLWithPath: safe).pathExtension
    if fileExtension.isEmpty {
        return "\(safe)-\(hash)"
    }

    let stem = String(safe.dropLast(fileExtension.count + 1))
    return "\(stem)-\(hash).\(fileExtension)"
}

private func safePDFAssetScalar(
    _ scalar: Unicode.Scalar,
) -> Bool {
    switch scalar.value {
    case 0x30 ... 0x39, 0x41 ... 0x5A, 0x61 ... 0x7A:
        true
    case 0x2D, 0x2E, 0x5F:
        true
    default:
        false
    }
}

private func stablePDFAssetHash(
    _ path: String,
) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in path.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1_099_511_628_211
    }
    return String(hash, radix: 16)
}
