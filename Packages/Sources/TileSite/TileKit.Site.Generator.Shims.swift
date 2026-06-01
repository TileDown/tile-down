import Foundation
import TileCore

extension TileKit.Site.Generator {
    func isRedirect(
        _ page: TileKit.Site.Page,
    ) -> Bool {
        isRedirect(frontMatter: page.document.frontMatter)
    }

    func isRedirect(
        frontMatter: [String: String],
    ) -> Bool {
        frontMatter["type"]?.lowercased() == "redirect"
    }

    /// Writes a tiny redirect page for each content page marked
    /// `type: redirect`. Redirect content keeps the source slug as the old URL,
    /// but is excluded from normal page rendering, navigation, listings, and feeds.
    func contentRedirects(
        _ pages: [TileKit.Site.Page],
        outputRootPath: String,
        generated: Set<String>,
    ) throws -> [String] {
        var paths: [String] = []
        for page in pages.sorted() {
            let target = try redirectTarget(for: page)
            let outputPath = join(
                outputRootPath,
                page.slug.isEmpty ? "index.html" : page.slug + "/index.html",
            )
            guard !generated.contains(outputPath) else {
                throw TileKit.Site.ConfigurationFileError.duplicateOutputPath(outputPath)
            }
            try fileSystem.writeTextFile(
                redirectPage(to: target),
                at: outputPath,
            )
            paths.append(outputPath)
        }
        return paths
    }

    private func redirectTarget(
        for page: TileKit.Site.Page,
    ) throws -> String {
        let target = page.document.frontMatter["to"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let target, !target.isEmpty else {
            throw TileKit.Site.RedirectError.missingTarget(page.sourcePath)
        }
        return target
    }

    /// Writes a tiny redirect page at `out/<key>/index.html` for each configured
    /// outbound link, so a `link:` reference points at a stable local URL that
    /// forwards to the external target. Returns the written output paths.
    func outboundShims(
        request: TileKit.Site.ContentBuildRequest,
        generated: Set<String>,
    ) throws -> [String] {
        var paths: [String] = []
        let entries = request.configuration.outboundLinks
            .sorted { $0.key < $1.key }
        for (key, target) in entries {
            let outputPath = join(
                request.outputRootPath,
                "out/" + key + "/index.html",
            )
            guard !generated.contains(outputPath) else {
                throw TileKit.Site.ConfigurationFileError.duplicateOutputPath(outputPath)
            }
            try fileSystem.writeTextFile(
                redirectPage(to: target),
                at: outputPath,
            )
            paths.append(outputPath)
        }
        return paths
    }

    /// A minimal HTML redirect page: a canonical link, a meta refresh, and a
    /// visible fallback link, all pointing at the external target.
    private func redirectPage(
        to target: String,
    ) -> String {
        let escaped = target
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return [
            "<!doctype html>",
            "<html lang=\"en\">",
            "<head>",
            "<meta charset=\"utf-8\">",
            "<title>Redirecting</title>",
            "<link rel=\"canonical\" href=\"\(escaped)\">",
            "<meta http-equiv=\"refresh\" content=\"0; url=\(escaped)\">",
            "</head>",
            "<body>",
            "<p>Redirecting to <a href=\"\(escaped)\">\(escaped)</a>.</p>",
            "</body>",
            "</html>",
        ].joined(separator: "\n")
    }
}
