import Foundation
import TileKit

extension Command {
    func runDoctorBuild(
        options: DoctorOptions,
        configuration: TileKit.Site.ConfigurationFile,
        report: inout DoctorReport,
    ) {
        guard report.hasErrors == false else {
            report.addCheck("build", "skipped because errors were found")
            return
        }

        guard configuration.generators.isEmpty || options.runGenerators else {
            report.addCheck("build", "skipped because generators were not run")
            return
        }

        let tempRoot = doctorTempRoot()
        do {
            try FileManager.default.createDirectory(
                at: tempRoot,
                withIntermediateDirectories: true,
            )
            try runDoctorBuild(
                options: options,
                configuration: configuration,
                tempRoot: tempRoot,
                report: &report,
            )
        } catch {
            report.add(
                .error,
                code: "build.failed",
                message: String(describing: error),
                path: options.contentRootPath,
                recovery: "Run tiledown build-site with the same content directory for detailed build output.",
            )
        }

        cleanupDoctorTempRoot(tempRoot, options: options, report: &report)
    }

    private func runDoctorBuild(
        options: DoctorOptions,
        configuration: TileKit.Site.ConfigurationFile,
        tempRoot: URL,
        report: inout DoctorReport,
    ) throws {
        let contentRootPath = try doctorBuildContentPath(
            options: options,
            tempRoot: tempRoot,
        )
        let outputRoot = tempRoot.appendingPathComponent("dist", isDirectory: true)
        let result = try buildDoctorOutput(
            contentRootPath: contentRootPath,
            outputRootPath: outputRoot.path,
            includeDrafts: options.includeDrafts,
        )
        report.tempOutputPath = outputRoot.path
        report.addCheck("build", "\(result.outputPaths.count) output paths")
        addPublishOutputDiagnostics(
            to: &report,
            options: options,
            configuration: configuration,
            outputRootPath: outputRoot.path,
        )
    }

    private func doctorBuildContentPath(
        options: DoctorOptions,
        tempRoot: URL,
    ) throws -> String {
        guard options.runGenerators else {
            return options.contentRootPath
        }

        let copiedContent = tempRoot.appendingPathComponent(
            "content",
            isDirectory: true,
        )
        try FileManager.default.copyItem(
            at: URL(fileURLWithPath: options.contentRootPath),
            to: copiedContent,
        )
        return copiedContent.path
    }

    private func buildDoctorOutput(
        contentRootPath: String,
        outputRootPath: String,
        includeDrafts: Bool,
    ) throws -> TileKit.Site.ContentBuildResult {
        let configurationFile = try loadConfigurationFile(
            contentRootPath: contentRootPath,
        )
        let serviceBindings = try configuredServiceBindings(
            from: configurationFile.serviceBindings,
            contentRootPath: contentRootPath,
        )
        let generator = makeGenerator(
            serviceBindings: serviceBindings.bindings,
        )
        try runContentGenerators(
            configurationFile.generators,
            workingDirectory: contentRootPath,
        )
        return try generator.buildContent(
            .init(
                contentRootPath: contentRootPath,
                template: .layout(configurationFile.layout),
                outputRootPath: outputRootPath,
                configuration: configurationFile.configuration,
                privateSourcePaths: serviceBindings.privateSourcePaths,
                includeDrafts: includeDrafts,
            ),
        )
    }

    private func addPublishOutputDiagnostics(
        to report: inout DoctorReport,
        options: DoctorOptions,
        configuration: TileKit.Site.ConfigurationFile,
        outputRootPath: String,
    ) {
        guard options.publish else {
            return
        }

        if let feed = configuration.configuration.feed {
            addRequiredOutputFileDiagnostic(
                to: &report,
                outputRootPath: outputRootPath,
                relativePath: feed.path,
                code: "publish.rss",
                label: "RSS feed",
            )
        }
        addRequiredOutputFileDiagnostic(
            to: &report,
            outputRootPath: outputRootPath,
            relativePath: "sitemap.xml",
            code: "publish.sitemap",
            label: "sitemap",
        )
        addLocalReferenceDiagnostics(to: &report, outputRootPath: outputRootPath)
    }

    private func addLocalReferenceDiagnostics(
        to report: inout DoctorReport,
        outputRootPath: String,
    ) {
        let localReferences = localDevelopmentReferences(in: outputRootPath)
        guard !localReferences.isEmpty else {
            report.addCheck("publish local URLs", "none")
            return
        }
        report.add(
            .error,
            code: "publish.localURL",
            message: "Generated output contains localhost or 127.0.0.1 references.",
            path: localReferences.prefix(3).joined(separator: ", "),
            recovery: "Remove local development URLs before publishing.",
        )
    }

    private func addRequiredOutputFileDiagnostic(
        to report: inout DoctorReport,
        outputRootPath: String,
        relativePath: String,
        code: String,
        label: String,
    ) {
        let path = URL(fileURLWithPath: outputRootPath)
            .appendingPathComponent(relativePath)
            .path
        if FileManager.default.fileExists(atPath: path) {
            report.addCheck("publish \(label)", relativePath)
        } else {
            report.add(
                .error,
                code: code,
                message: "Expected \(label) output is missing.",
                path: relativePath,
                recovery: "Run tiledown build-site and inspect the output directory.",
            )
        }
    }

    private func localDevelopmentReferences(
        in outputRootPath: String,
    ) -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: outputRootPath),
            includingPropertiesForKeys: [.isRegularFileKey],
        ) else {
            return []
        }

        var result: [String] = []
        for case let url as URL in enumerator where doctorCanScan(url) {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                continue
            }
            if containsLocalDevelopmentReference(
                text,
                pathExtension: url.pathExtension,
            ) {
                result.append(url.path)
            }
        }
        return result.sorted()
    }

    private func containsLocalDevelopmentReference(
        _ text: String,
        pathExtension: String,
    ) -> Bool {
        switch pathExtension.lowercased() {
        case "html", "xml":
            [
                #"\b(?:href|src|action|content)\s*=\s*["'][^"']*(?:localhost|127\.0\.0\.1)"#,
                #"<(?:loc|link|guid)>\s*[^<]*(?:localhost|127\.0\.0\.1)"#,
                #"url\(\s*['"]?[^)'"]*(?:localhost|127\.0\.0\.1)"#,
            ].contains { matchesDoctorPattern($0, in: text) }
        case "css":
            matchesDoctorPattern(
                #"url\(\s*['"]?[^)'"]*(?:localhost|127\.0\.0\.1)"#,
                in: text,
            )
        default:
            text.contains("localhost") || text.contains("127.0.0.1")
        }
    }

    private func matchesDoctorPattern(
        _ pattern: String,
        in text: String,
    ) -> Bool {
        guard let expression = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive],
        ) else {
            return false
        }
        return expression.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text),
        ) != nil
    }

    private func doctorCanScan(
        _ url: URL,
    ) -> Bool {
        ["html", "xml", "txt", "css", "js", "json"].contains(url.pathExtension)
    }

    private func doctorTempRoot() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "tiledown-doctor-\(UUID().uuidString)",
                isDirectory: true,
            )
    }

    private func cleanupDoctorTempRoot(
        _ tempRoot: URL,
        options: DoctorOptions,
        report: inout DoctorReport,
    ) {
        if !options.keepTemp {
            try? FileManager.default.removeItem(at: tempRoot)
            report.tempOutputPath = nil
        } else {
            report.addCheck("temp", tempRoot.path)
        }
    }
}
