import Testing
import TileCore
import TileMarkdown
import TileOutput
@testable import TileSite
import TileSource
import TileTemplate
import TileTile

extension SiteGeneratorTests {
    @Test("exposes top-level sections ordered by weight under site.sections")
    func siteSections() throws {
        let template = #"{{#site.sections}}<a href="{{ url }}">{{ title }}</a>{{/site.sections}}"#
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
                "content/blog/index.md": "---\ntitle: Blog\nweight: 2\n---\n# Blog",
                "content/about/index.md": "---\ntitle: About\nweight: 1\n---\n# About",
                "content/blog/deep/index.md": "---\ntitle: Deep\n---\n# Deep",
                "templates/page.html": template,
            ],
        )
        let generator = makeGenerator(fileSystem: fileSystem)

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
            ),
        )

        // About (weight 1) before Blog (weight 2); Home (root) and Deep (depth 2)
        // are not sections.
        #expect(
            fileSystem.files["dist/index.html"]
                == #"<a href="/about/">About</a><a href="/blog/">Blog</a>"#,
        )
    }

    @Test("sections without a weight fall back to alphabetical order by title")
    func sectionsDefaultAlphabetical() throws {
        let template = #"{{#site.sections}}{{ title }};{{/site.sections}}"#
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "# Home",
                "content/zebra/index.md": "---\ntitle: Zebra\n---\n# Z",
                "content/apple/index.md": "---\ntitle: Apple\n---\n# A",
                "templates/page.html": template,
            ],
        )
        let generator = makeGenerator(fileSystem: fileSystem)

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
            ),
        )

        #expect(fileSystem.files["dist/index.html"] == "Apple;Zebra;")
    }
}

extension SiteGeneratorTests {
    @Test("a section without a title sorts by its slug")
    func sectionsSortBySlugWhenTitleMissing() throws {
        let template = #"{{#site.sections}}{{ url }};{{/site.sections}}"#
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "# Home",
                "content/yak/index.md": "# Yak",
                "content/ant/index.md": "# Ant",
                "templates/page.html": template,
            ],
        )
        let generator = makeGenerator(fileSystem: fileSystem)

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
            ),
        )

        // No titles, so the tiebreak is the slug: ant before yak.
        #expect(fileSystem.files["dist/index.html"] == "/ant/;/yak/;")
    }

    @Test("a site with only a root page has no sections")
    func rootOnlySiteHasNoSections() throws {
        let template = #"[{{#site.sections}}{{ url }}{{/site.sections}}]"#
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "# Home",
                "templates/page.html": template,
            ],
        )
        let generator = makeGenerator(fileSystem: fileSystem)

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .file(path: "templates/page.html"),
                outputRootPath: "dist",
            ),
        )

        #expect(fileSystem.files["dist/index.html"] == "[]")
    }
}

extension SiteGeneratorTests {
    @Test("the built-in top-nav layout renders header, section nav, content, and footer")
    func topNavLayout() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Welcome",
                "content/about/index.md": "---\ntitle: About\nweight: 1\n---\n# About us",
            ],
        )
        let generator = makeGenerator(fileSystem: fileSystem)

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(title: "My Site"),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains("<title>Home</title>"))
        #expect(home.contains(#"<a class="td-brand" href="/">My Site</a>"#))
        #expect(home.contains(#"<nav class="td-nav"><a class="td-nav-link" href="/about/">About</a></nav>"#))
        #expect(home.contains(#"<main class="td-main"><h1>Welcome</h1>"#))
        #expect(home.contains(#"<footer class="td-footer">"#))
        // A dark/light theme toggle and the no-flash script that wires it.
        #expect(home.contains(#"data-td-theme-toggle"#))
        #expect(home.contains("localStorage.getItem('td-theme')"))
        #expect(home.contains("root.removeAttribute('data-theme')"))
        #expect(home.contains("window.addEventListener('pageshow', applyStoredTheme)"))
        #expect(home.contains("window.addEventListener('storage', function (event)"))
    }

    @Test("built-in layouts apply baseURL to home and section links")
    func builtInLayoutBaseURLLinks() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Welcome",
                "content/about/index.md": "---\ntitle: About\nweight: 1\n---\n# About us",
            ],
        )
        let generator = makeGenerator(fileSystem: fileSystem)

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(
                    title: "My Site",
                    baseURL: "https://example.com/docs",
                ),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<a class="td-brand" href="https://example.com/docs/">My Site</a>"#))
        #expect(
            home.contains(
                #"<nav class="td-nav"><a class="td-nav-link" href="https://example.com/docs/about/">About</a></nav>"#,
            ),
        )
    }
}

extension SiteGeneratorTests {
    @Test("the built-in left-sidebar layout puts nav in an aside beside the content")
    func leftSidebarLayout() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Welcome",
                "content/about/index.md": "---\ntitle: About\nweight: 1\n---\n# About us",
            ],
        )
        let generator = makeGenerator(fileSystem: fileSystem)

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.leftSidebar),
                outputRootPath: "dist",
                configuration: .init(title: "My Site"),
            ),
        )

        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<body class="td-layout-sidebar">"#))
        #expect(home.contains(#"<aside class="td-sidebar">"#))
        #expect(home.contains(#"<nav class="td-sidebar-nav"><a class="td-nav-link" href="/about/">About</a></nav>"#))
        #expect(home.contains(#"<div class="td-content">"#))
        #expect(home.contains(#"<main class="td-main"><h1>Welcome</h1>"#))
        #expect(home.contains(#"data-td-theme-toggle"#))
        #expect(home.contains("root.removeAttribute('data-theme')"))
        #expect(home.contains("window.addEventListener('pageshow', applyStoredTheme)"))
        #expect(home.contains("window.addEventListener('storage', function (event)"))
    }
}

extension SiteGeneratorTests {
    @Test("the default theme is composed into the shared stylesheet, written even without tiles")
    func themedStylesheet() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
            ],
        )
        let generator = makeGenerator(fileSystem: fileSystem)

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(title: "My Site"),
            ),
        )

        let css = try #require(fileSystem.files["dist/styles.css"])
        #expect(css.contains("--td-bg:"))
        #expect(css.contains(#"[data-theme="dark"]"#))
        #expect(css.contains("@layer reset, theme, tile-override;"))
        #expect(css.contains("@layer theme {"))
        #expect(css.contains(".td-header {"))
        // The theme always produces a stylesheet, so the page links it even with no tiles.
        let home = try #require(fileSystem.files["dist/index.html"])
        #expect(home.contains(#"<link rel="stylesheet" href="/styles.css">"#))
    }

    @Test("the system theme is composed into the shared stylesheet")
    func systemThemeStylesheet() throws {
        let fileSystem = MemoryFileSystem(
            files: [
                "content/index.md": "---\ntitle: Home\n---\n# Home",
            ],
        )
        let generator = makeGenerator(fileSystem: fileSystem)

        _ = try generator.buildContent(
            .init(
                contentRootPath: "content",
                template: .layout(.topNav),
                outputRootPath: "dist",
                configuration: .init(
                    title: "My Site",
                    theme: .system,
                ),
            ),
        )

        let css = try #require(fileSystem.files["dist/styles.css"])
        #expect(css.contains("--td-bg: #f5f5f7;"))
        #expect(css.contains("--td-accent: #0066cc;"))
        #expect(css.contains(#"[data-theme="dark"]"#))
        #expect(css.contains(".td-footer-inner {"))
    }
}
