import Foundation
import Testing

extension TiledownCLITests {
    @Test("doctor reports a clean content directory")
    func doctorReportsCleanContentDirectory() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }

        let result = try runTiledown(arguments: ["doctor", fixture.content.path])

        #expect(result.status == 0, "stderr: \(result.stderr)")
        #expect(result.stdout.contains("TileDown Doctor"))
        #expect(result.stdout.contains("OK   build:"))
        #expect(result.stdout.contains("Summary: 0 errors, 0 warnings"))
        #expect(result.stderr.isEmpty)
    }

    @Test("doctor help prints usage")
    func doctorHelpPrintsUsage() throws {
        let result = try runTiledown(arguments: ["doctor", "help"])

        #expect(result.status == 0)
        #expect(result.stdout.contains("tiledown doctor"))
        #expect(result.stderr.isEmpty)
    }

    @Test("doctor reports a missing content directory without crashing")
    func doctorReportsMissingContentDirectoryWithoutCrashing() throws {
        let result = try runTiledown(arguments: ["doctor", "/tmp/no-such-tiledown-content"])

        #expect(result.status != 0)
        #expect(result.stdout.contains("ERROR content.missing"))
        #expect(!result.stdout.contains("Fatal error"))
        #expect(result.stderr.isEmpty)
    }

    @Test("doctor reports invalid configuration without crashing")
    func doctorReportsInvalidConfigurationWithoutCrashing() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }
        try "unknown: value\n".write(
            to: fixture.content.appendingPathComponent("tiledown.yml"),
            atomically: true,
            encoding: .utf8,
        )

        let result = try runTiledown(arguments: ["doctor", fixture.content.path])

        #expect(result.status != 0)
        #expect(result.stdout.contains("ERROR config.invalid"))
        #expect(!result.stdout.contains("Fatal error"))
        #expect(result.stderr.isEmpty)
    }

    @Test("doctor skips generators by default")
    func doctorSkipsGeneratorsByDefault() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }
        try writeDoctorGenerator(to: fixture.content)

        let result = try runTiledown(arguments: ["doctor", fixture.content.path])

        #expect(result.status == 0, "stderr: \(result.stderr)")
        #expect(result.stdout.contains("WARN  generator.skipped"))
        #expect(result.stdout.contains("OK   build: skipped because generators were not run"))
        #expect(
            !FileManager.default.fileExists(
                atPath: fixture.content
                    .appendingPathComponent("extra/index.md")
                    .path,
            ),
        )
    }

    @Test("doctor strict treats warnings as failures")
    func doctorStrictTreatsWarningsAsFailures() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }
        try writeDoctorGenerator(to: fixture.content)

        let result = try runTiledown(
            arguments: ["doctor", "--strict", fixture.content.path],
        )

        #expect(result.status != 0)
        #expect(result.stdout.contains("WARN  generator.skipped"))
        #expect(result.stderr.isEmpty)
    }

    @Test("doctor can run generators in a temporary copy")
    func doctorCanRunGeneratorsInTemporaryCopy() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }
        try writeDoctorGenerator(to: fixture.content)

        let result = try runTiledown(
            arguments: ["doctor", "--run-generators", fixture.content.path],
        )

        #expect(result.status == 0, "stderr: \(result.stderr)")
        #expect(result.stdout.contains("OK   generators: 1 declared, enabled for temp build"))
        #expect(result.stdout.contains("OK   build:"))
        #expect(
            !FileManager.default.fileExists(
                atPath: fixture.content
                    .appendingPathComponent("extra/index.md")
                    .path,
            ),
            "doctor must not run generators against the original content tree",
        )
    }

    @Test("doctor publish mode requires an absolute baseURL")
    func doctorPublishModeRequiresAbsoluteBaseURL() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }

        let result = try runTiledown(
            arguments: ["doctor", "--publish", fixture.content.path],
        )

        #expect(result.status != 0)
        #expect(result.stdout.contains("ERROR publish.baseURL"))
        #expect(result.stderr.isEmpty)
    }

    @Test("doctor publish allows local URLs in article prose")
    func doctorPublishAllowsLocalURLsInArticleProse() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }
        try writePublishConfiguration(to: fixture.content)
        try """
        ---
        title: Home
        ---
        # Home

        The server runs locally at `http://localhost:8080`.
        """.write(
            to: fixture.content.appendingPathComponent("index.md"),
            atomically: true,
            encoding: .utf8,
        )

        let result = try runTiledown(
            arguments: ["doctor", "--publish", fixture.content.path],
        )

        #expect(result.status == 0, "stderr: \(result.stderr)")
        #expect(result.stdout.contains("OK   publish local URLs: none"))
        #expect(result.stderr.isEmpty)
    }

    @Test("doctor publish reports local asset URLs")
    func doctorPublishReportsLocalAssetURLs() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }
        try writePublishConfiguration(to: fixture.content)
        try """
        ---
        title: Home
        ---
        # Home

        ![Local preview](http://localhost:3000/preview.png)
        """.write(
            to: fixture.content.appendingPathComponent("index.md"),
            atomically: true,
            encoding: .utf8,
        )

        let result = try runTiledown(
            arguments: ["doctor", "--publish", fixture.content.path],
        )

        #expect(result.status != 0)
        #expect(result.stdout.contains("ERROR publish.localURL"))
        #expect(result.stderr.isEmpty)
    }

    @Test("doctor emits JSON diagnostics")
    func doctorEmitsJSONDiagnostics() throws {
        let fixture = try makeContentFixture()
        defer {
            try? FileManager.default.removeItem(at: fixture.root)
        }
        try writeDoctorGenerator(to: fixture.content)

        let result = try runTiledown(
            arguments: ["doctor", "--json", fixture.content.path],
        )

        #expect(result.status == 0, "stderr: \(result.stderr)")
        let data = try #require(result.stdout.data(using: .utf8))
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any],
        )
        #expect(json["status"] as? String == "warning")
        let summary = try #require(json["summary"] as? [String: Any])
        #expect(summary["warnings"] as? Int == 1)
    }

    private func writePublishConfiguration(
        to content: URL,
    ) throws {
        try """
        title: Publish Demo
        baseURL: https://example.com
        """.write(
            to: content.appendingPathComponent("tiledown.yml"),
            atomically: true,
            encoding: .utf8,
        )
    }

    private func writeDoctorGenerator(
        to content: URL,
    ) throws {
        try """
        title: Generator Demo
        generate.extra: /bin/sh gen.sh
        """.write(
            to: content.appendingPathComponent("tiledown.yml"),
            atomically: true,
            encoding: .utf8,
        )
        try """
        mkdir -p extra
        printf -- "---\\ntitle: Extra\\n---\\n# Extra\\n" > extra/index.md
        """.write(
            to: content.appendingPathComponent("gen.sh"),
            atomically: true,
            encoding: .utf8,
        )
    }
}
