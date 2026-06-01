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

    /// Copies every content asset verbatim into the output, preserving its
    /// relative path. Markdown is always source (an `index.md` becomes a page and
    /// any other `.md` is ignored), build inputs such as `tiledown.yml` and OS
    /// metadata are skipped, and a file whose destination collides with an
    /// already-generated output (a page, the stylesheet, the feed) is skipped so
    /// content cannot clobber generated output. One rule covers both a page-local
    /// image beside its `index.md` and a site-level `assets/` tree, so a Markdown
    /// image resolves once its file lands in the output.
    func copyAssets(
        request: TileKit.Site.ContentBuildRequest,
        generated: Set<String>,
        outputPaths: inout [String],
    ) throws {
        let relativePaths = try fileSystem.listFilesRecursively(
            at: request.contentRootPath,
        )
        let staticPassthroughs = try normalizedStaticPassthroughs(
            request.configuration.staticPassthroughs,
        )
        for relativePath in relativePaths where isAsset(relativePath) {
            guard !isStaticPassthroughSource(
                relativePath,
                passthroughs: staticPassthroughs,
            ) else {
                continue
            }
            let destination = join(request.outputRootPath, relativePath)
            // Never let a content file overwrite a generated page/stylesheet/feed.
            guard !generated.contains(destination) else {
                continue
            }
            try fileSystem.copyFile(
                from: join(request.contentRootPath, relativePath),
                to: destination,
            )
            outputPaths.append(destination)
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
        let relativePaths = try fileSystem.listFilesRecursively(
            at: request.contentRootPath,
            includingHidden: true,
        )
        for passthrough in try normalizedStaticPassthroughs(request.configuration.staticPassthroughs) {
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
        let lowercased = path.lowercased()
        if lowercased.hasSuffix(".md") || lowercased.hasSuffix(".markdown") {
            return false
        }
        let fileName = path.split(separator: "/").last.map(String.init) ?? path
        return !Self.nonAssetFileNames.contains(fileName)
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
        let nested = relativePaths
            .filter { $0.hasPrefix(directoryPrefix) }
            .map { sourcePath in
                let suffix = String(sourcePath.dropFirst(directoryPrefix.count))
                return StaticCopy(
                    sourcePath: sourcePath,
                    outputPath: join(passthrough.outputPath, suffix),
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
        request: TileKit.Site.ContentBuildRequest,
    ) throws {
        let relativePaths = try fileSystem.listFilesRecursively(
            at: request.contentRootPath,
        )
        try imageChecker.check(
            imagePaths: relativePaths.filter(isImage),
        )
    }

    func isImage(
        _ path: String,
    ) -> Bool {
        let imageExtensions = [".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".avif"]
        let lowercased = path.lowercased()
        return imageExtensions.contains { lowercased.hasSuffix($0) }
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
