import Foundation
import TileCore

extension TileKit.Site {
    enum ContentType: Equatable {
        case page
        case post

        static func isPost(
            _ page: Page,
            postsDirectory: String,
        ) -> Bool {
            if let explicitType = explicitType(of: page) {
                return explicitType == .post
            }
            return legacyPost(page, postsDirectory: postsDirectory)
        }

        static func isCollectionPost(
            _ page: Page,
            postsDirectory: String,
        ) -> Bool {
            isPost(page, postsDirectory: postsDirectory)
                && PostSelection.parsedDate(page.document.frontMatter["date"]) != nil
        }

        static func articleKicker(
            for page: Page,
        ) -> String {
            switch normalizedTypeValue(of: page) {
            case "blog-post":
                "Blog Post"
            case "post":
                "Post"
            default:
                "Article"
            }
        }

        private static func explicitType(
            of page: Page,
        ) -> ContentType? {
            guard let value = normalizedTypeValue(of: page) else {
                return nil
            }
            switch value {
            case "blog-post", "post":
                return .post
            default:
                return .page
            }
        }

        private static func normalizedTypeValue(
            of page: Page,
        ) -> String? {
            guard let value = page.document.frontMatter["type"]?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty
            else {
                return nil
            }
            return value.lowercased()
        }

        private static func legacyPost(
            _ page: Page,
            postsDirectory: String,
        ) -> Bool {
            page.slug.hasPrefix(postsDirectory + "/")
                && PostSelection.parsedDate(page.document.frontMatter["date"]) != nil
        }
    }
}
