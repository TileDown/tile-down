import Foundation
import TileKit

extension Command {
    func contentSummary(
        contentRootPath: String,
        configuration: TileKit.Site.Configuration,
    ) throws -> DoctorContentSummary {
        let root = URL(fileURLWithPath: contentRootPath, isDirectory: true)
        let markdownFiles = try indexMarkdownFiles(under: root)
        var summary = DoctorContentSummary()
        let parser = TileKit.Source.FrontMatterParser()

        for file in markdownFiles {
            summary.pageCount += 1
            let document = try parser.parse(
                String(contentsOf: file, encoding: .utf8),
            )
            update(
                &summary,
                file: file,
                root: root,
                frontMatter: document.frontMatter,
                postsDirectory: configuration.postsDirectory,
            )
        }
        return summary
    }

    private func update(
        _ summary: inout DoctorContentSummary,
        file: URL,
        root: URL,
        frontMatter: [String: String],
        postsDirectory: String,
    ) {
        let isDraft = frontMatter["draft"] == "true"
        let isPost = doctorIsPost(
            file: file,
            root: root,
            frontMatter: frontMatter,
            postsDirectory: postsDirectory,
        )
        if isDraft {
            summary.draftCount += 1
            if isPost {
                summary.draftPostCount += 1
            }
        } else if isPost {
            summary.publishedPostCount += 1
        }
    }

    private func indexMarkdownFiles(
        under root: URL,
    ) throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
        ) else {
            return []
        }

        var result: [URL] = []
        for case let url as URL in enumerator where url.lastPathComponent == "index.md" {
            result.append(url)
        }
        return result.sorted { $0.path < $1.path }
    }

    private func doctorIsPost(
        file: URL,
        root: URL,
        frontMatter: [String: String],
        postsDirectory: String,
    ) -> Bool {
        if frontMatter["type"] == "post" {
            return true
        }
        guard frontMatter["date"] != nil else {
            return false
        }
        let relativePath = file.path
            .replacingOccurrences(of: root.path + "/", with: "")
        return relativePath == "\(postsDirectory)/index.md"
            || relativePath.hasPrefix("\(postsDirectory)/")
    }
}
