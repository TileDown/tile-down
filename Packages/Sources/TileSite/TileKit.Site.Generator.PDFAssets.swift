import Foundation
import TileCore
import TileImage

extension TileKit.Site.Generator {
    func preparedArticlePDFMarkdown(
        for page: TileKit.Site.Page,
        configuration: TileKit.Site.Configuration,
        contentRootPath: String,
        assetRoot: URL?,
    ) -> String {
        let markdown = articlePDFMarkdown(for: page)
        guard let assetRoot else {
            return markdown
        }
        let context = PDFAssetRewriteContext(
            page: page,
            configuration: configuration,
            contentRootPath: contentRootPath,
            assetRoot: assetRoot,
        )
        return rewriteLocalPDFImageSources(
            in: markdown,
            context: context,
        )
    }

    func temporaryPDFAssetRoot() -> URL? {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("tiledown-pdf-assets-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: root,
                withIntermediateDirectories: true,
            )
            return root
        } catch {
            return nil
        }
    }

    func removeTemporaryPDFAssetRoot(
        _ root: URL?,
    ) {
        guard let root else {
            return
        }
        try? FileManager.default.removeItem(at: root)
    }

    private func rewriteLocalPDFImageSources(
        in markdown: String,
        context: PDFAssetRewriteContext,
    ) -> String {
        var output: [String] = []
        var fence: String?

        for line in markdown.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let currentFence = fence {
                output.append(line)
                if trimmed.hasPrefix(currentFence) {
                    fence = nil
                }
                continue
            }

            if let marker = fenceMarker(trimmed) {
                fence = marker
                output.append(line)
                continue
            }

            output.append(rewriteLocalPDFImageSources(
                inLine: line,
                context: context,
            ))
        }

        return output.joined(separator: "\n")
    }

    private func rewriteLocalPDFImageSources(
        inLine line: String,
        context: PDFAssetRewriteContext,
    ) -> String {
        var output = ""
        var index = line.startIndex
        while let reference = nextImageReference(in: line, from: index) {
            output += line[index ..< reference.sourceRange.lowerBound]
            if let assetPath = pdfAssetPath(
                for: reference.source,
                isAngleWrapped: reference.isAngleWrapped,
                context: context,
            ) {
                output += assetPath
            } else {
                output += reference.source
            }
            index = reference.sourceRange.upperBound
        }
        output += line[index...]
        return output
    }

    private func pdfAssetPath(
        for source: String,
        isAngleWrapped: Bool,
        context: PDFAssetRewriteContext,
    ) -> String? {
        guard let path = localPDFImagePath(source) else {
            return nil
        }
        let mapping = pdfAssetMapping(
            for: path,
            context: context,
        )
        guard let mapping, isImage(mapping.sourcePath) else {
            return nil
        }
        let assetPath = copyPDFAsset(
            mapping,
            context: context,
        )
        return markdownPDFImageDestination(
            assetPath,
            isAngleWrapped: isAngleWrapped,
        )
    }

    private func copyPDFAsset(
        _ mapping: PDFAssetMapping,
        context: PDFAssetRewriteContext,
    ) -> String {
        if let convertedPath = convertedPDFAssetPath(
            mapping,
            context: context,
        ) {
            aliasDecodedPDFAssetIfNeeded(convertedPath, assetRoot: context.assetRoot)
            return convertedPath
        }
        try? fileSystem.copyFile(
            from: join(context.contentRootPath, mapping.sourcePath),
            to: context.assetRoot.appendingPathComponent(mapping.pdfPath).path,
        )
        aliasDecodedPDFAssetIfNeeded(mapping.pdfPath, assetRoot: context.assetRoot)
        return mapping.pdfPath
    }

    private func aliasDecodedPDFAssetIfNeeded(
        _ pdfPath: String,
        assetRoot: URL,
    ) {
        let decodedPath = decodedLocalPDFPath(pdfPath)
        guard decodedPath != pdfPath,
              let aliasPath = normalizedRelativePath(decodedPath)
        else {
            return
        }

        try? fileSystem.copyFile(
            from: assetRoot.appendingPathComponent(pdfPath).path,
            to: assetRoot.appendingPathComponent(aliasPath).path,
        )
    }

    private func convertedPDFAssetPath(
        _ mapping: PDFAssetMapping,
        context: PDFAssetRewriteContext,
    ) -> String? {
        guard shouldConvertPDFAsset(mapping.sourcePath) else {
            return nil
        }

        let convertedPath = mapping.pdfPath + ".jpg"
        let converter = TileKit.Image.PDFAssetConverter()
        guard converter.convertToJPEG(
            sourcePath: join(context.contentRootPath, mapping.sourcePath),
            destinationPath: context.assetRoot.appendingPathComponent(convertedPath).path,
        ) else {
            return nil
        }
        return convertedPath
    }

    private func shouldConvertPDFAsset(
        _ sourcePath: String,
    ) -> Bool {
        let supportedExtensions = Set(["jpg", "jpeg"])
        let fileExtension = URL(fileURLWithPath: sourcePath)
            .pathExtension
            .lowercased()
        return !supportedExtensions.contains(fileExtension)
    }

    private func pdfAssetMapping(
        for path: String,
        context: PDFAssetRewriteContext,
    ) -> PDFAssetMapping? {
        if path.hasPrefix("/") {
            let publicPath = String(path.dropFirst())
            let sourcePublicPath = decodedLocalPDFPath(publicPath)
            guard let publicPDFPath = normalizedRelativePath(sourcePublicPath) else {
                return nil
            }
            let sourcePath = staticSourcePath(
                forPublicPath: sourcePublicPath,
                configuration: context.configuration,
            ) ?? publicPDFPath
            return .init(sourcePath: sourcePath, pdfPath: safePDFAssetPath(publicPDFPath))
        }

        let sourceDirectory = sourceRelativeDirectory(
            sourcePath: context.page.sourcePath,
            contentRootPath: context.contentRootPath,
        )
        let decodedPath = decodedLocalPDFPath(path)
        guard let sourcePath = normalizedRelativePath(join(sourceDirectory ?? "", decodedPath))
        else {
            return nil
        }
        return .init(sourcePath: sourcePath, pdfPath: safePDFAssetPath(sourcePath))
    }

    private func staticSourcePath(
        forPublicPath publicPath: String,
        configuration: TileKit.Site.Configuration,
    ) -> String? {
        for passthrough in configuration.staticPassthroughs.sorted(by: longestOutputPathFirst) {
            if publicPath == passthrough.outputPath {
                return passthrough.sourcePath
            }
            let prefix = passthrough.outputPath + "/"
            if publicPath.hasPrefix(prefix) {
                let suffix = String(publicPath.dropFirst(prefix.count))
                return normalizedRelativePath(join(passthrough.sourcePath, suffix))
            }
        }
        return nil
    }

    private func sourceRelativeDirectory(
        sourcePath: String,
        contentRootPath: String,
    ) -> String? {
        let prefix = contentRootPath.hasSuffix("/") ? contentRootPath : contentRootPath + "/"
        guard sourcePath.hasPrefix(prefix) else {
            return nil
        }
        let relativePath = String(sourcePath.dropFirst(prefix.count))
        guard let lastSeparator = relativePath.lastIndex(of: "/") else {
            return ""
        }
        return String(relativePath[..<lastSeparator])
    }

    private func localPDFImagePath(
        _ source: String,
    ) -> String? {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.hasPrefix("//"),
              !trimmed.hasPrefix("#"),
              !trimmed.hasPrefix("?"),
              URLComponents(string: trimmed)?.scheme == nil
        else {
            return nil
        }

        let end = trimmed.firstIndex { character in
            character == "#" || character == "?"
        } ?? trimmed.endIndex
        let path = String(trimmed[..<end])
        return path.isEmpty ? nil : path
    }
}

private struct PDFAssetRewriteContext {
    var page: TileKit.Site.Page
    var configuration: TileKit.Site.Configuration
    var contentRootPath: String
    var assetRoot: URL
}
