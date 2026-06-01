import TileCore

extension TileKit.Site.Generator {
    /// Build inputs that live in the content root but are not site assets and
    /// must never be published: the site config the CLI reads, and OS metadata.
    static var nonAssetFileNames: Set<String> {
        [
            "tiledown.yml",
            "tiledown.yaml",
            ".DS_Store",
        ]
    }

    static var markdownExtensions: Set<String> {
        [".md", ".markdown"]
    }

    static var imageExtensions: Set<String> {
        [".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".avif"]
    }

    /// Copies every content asset verbatim into the output, preserving its
    /// relative path unless a custom 404 page needs local assets remapped beside
    /// `404.html`. Markdown is always source, build inputs are skipped, configured
    /// static passthrough sources are skipped here because they are copied by their
    /// explicit public paths, and generated output paths are never overwritten.
    func copyAssets(
        request: TileKit.Site.ContentBuildRequest,
        relativePaths: [String],
        generated: Set<String>,
        notFoundAssetDirectory: String? = nil,
        outputPaths: inout [String],
    ) throws {
        let staticPassthroughs = try normalizedStaticPassthroughs(
            request.configuration.staticPassthroughs,
        )
        var copiedDestinations = Set(outputPaths)
        for relativePath in relativePaths where isAsset(relativePath) {
            guard !isStaticPassthroughSource(
                relativePath,
                passthroughs: staticPassthroughs,
            ) else {
                continue
            }
            let outputRelativePath = outputAssetPath(
                for: relativePath,
                notFoundAssetDirectory: notFoundAssetDirectory,
            )
            let destination = join(request.outputRootPath, outputRelativePath)
            guard !generated.contains(destination),
                  !copiedDestinations.contains(destination)
            else {
                continue
            }
            try fileSystem.copyFile(
                from: join(request.contentRootPath, relativePath),
                to: destination,
            )
            outputPaths.append(destination)
            copiedDestinations.insert(destination)
        }
    }

    /// Copies explicitly configured static files and directories to the public
    /// paths named in site configuration. These run before ordinary asset mirroring
    /// so a migration can keep a private source layout while preserving public
    /// URLs such as `/CNAME`, `/robots.txt`, or `/images/...`.
    func copyStaticPassthroughs(
        request: TileKit.Site.ContentBuildRequest,
        generated: inout Set<String>,
        outputPaths: inout [String],
    ) throws {
        let staticPassthroughs = try normalizedStaticPassthroughs(
            request.configuration.staticPassthroughs,
        )
        guard !staticPassthroughs.isEmpty else {
            return
        }

        let relativePaths = try fileSystem.listFilesRecursively(
            at: request.contentRootPath,
            includingHidden: true,
        )
        for passthrough in staticPassthroughs {
            let copies = try staticCopies(
                for: passthrough,
                relativePaths: relativePaths,
            )
            for copy in copies {
                let destination = join(request.outputRootPath, copy.outputPath)
                guard generated.insert(destination).inserted else {
                    throw TileKit.Site.ConfigurationFileError.duplicateOutputPath(copy.outputPath)
                }
                try fileSystem.copyFile(
                    from: join(request.contentRootPath, copy.sourcePath),
                    to: destination,
                )
                outputPaths.append(destination)
            }
        }
    }

    func isAsset(
        _ path: String,
    ) -> Bool {
        if hasExtension(path, in: Self.markdownExtensions) {
            return false
        }
        let fileName = path.split(separator: "/").last.map(String.init) ?? path
        return !Self.nonAssetFileNames.contains(fileName)
    }

    func outputAssetPath(
        for relativePath: String,
        notFoundAssetDirectory: String?,
    ) -> String {
        guard let notFoundAssetDirectory,
              !notFoundAssetDirectory.isEmpty
        else {
            return relativePath
        }

        let prefix = notFoundAssetDirectory + "/"
        guard relativePath.hasPrefix(prefix) else {
            return relativePath
        }
        return String(relativePath.dropFirst(prefix.count))
    }

    private func isStaticPassthroughSource(
        _ relativePath: String,
        passthroughs: [TileKit.Site.StaticPassthrough],
    ) -> Bool {
        passthroughs.contains { passthrough in
            relativePath == passthrough.sourcePath
                || relativePath.hasPrefix(passthrough.sourcePath + "/")
        }
    }

    private func normalizedStaticPassthroughs(
        _ passthroughs: [TileKit.Site.StaticPassthrough],
    ) throws -> [TileKit.Site.StaticPassthrough] {
        try passthroughs.map { passthrough in
            try .init(
                validatingSourcePath: passthrough.sourcePath,
                outputPath: passthrough.outputPath,
            )
        }
    }

    private func staticCopies(
        for passthrough: TileKit.Site.StaticPassthrough,
        relativePaths: [String],
    ) throws -> [StaticCopy] {
        if relativePaths.contains(passthrough.sourcePath) {
            return [
                .init(
                    sourcePath: passthrough.sourcePath,
                    outputPath: passthrough.outputPath,
                ),
            ]
        }

        let directoryPrefix = passthrough.sourcePath + "/"
        let nested = try relativePaths
            .filter { $0.hasPrefix(directoryPrefix) }
            .map { sourcePath in
                let suffix = String(sourcePath.dropFirst(directoryPrefix.count))
                let outputPath = try TileKit.Site.StaticPassthrough.normalizedOutputPath(
                    join(passthrough.outputPath, suffix),
                )
                return StaticCopy(
                    sourcePath: sourcePath,
                    outputPath: outputPath,
                )
            }
        guard !nested.isEmpty else {
            throw TileKit.Site.ConfigurationFileError.missingStaticPath(passthrough.sourcePath)
        }
        return nested
    }

    /// Runs the injected image-checking pass over the content's image assets.
    /// The default checker does nothing; a real one can reject a build here.
    func runImageCheck(
        relativePaths: [String],
    ) throws {
        try imageChecker.check(
            imagePaths: relativePaths.filter(isImage),
        )
    }

    func isImage(
        _ path: String,
    ) -> Bool {
        hasExtension(path, in: Self.imageExtensions)
    }

    func hasExtension(
        _ path: String,
        in extensions: Set<String>,
    ) -> Bool {
        let lowercased = path.lowercased()
        return extensions.contains { lowercased.hasSuffix($0) }
    }

    /// Joins a parent path and child with a single separator. Internal so the
    /// asset/image methods here and the build pipeline in the main file share one
    /// definition.
    func join(
        _ parent: String,
        _ child: String,
    ) -> String {
        guard !parent.isEmpty else {
            return child
        }

        if parent.hasSuffix("/") {
            return parent + child
        }

        return parent + "/" + child
    }
}

private struct StaticCopy: Equatable {
    var sourcePath: String
    var outputPath: String
}
