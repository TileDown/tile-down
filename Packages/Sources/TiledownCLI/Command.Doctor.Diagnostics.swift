import Foundation
import TileKit

extension Command {
    func runDoctor(
        _ options: DoctorOptions,
    ) -> DoctorReport {
        var report = DoctorReport(
            commandVersion: "\(TileKit.Product.name) \(TileKit.Product.version)",
            contentRootPath: options.contentRootPath,
            publish: options.publish,
        )
        report.addCheck("binary", report.commandVersion)

        guard contentRootExists(options.contentRootPath) else {
            report.add(
                .error,
                code: "content.missing",
                message: "Content directory does not exist.",
                path: options.contentRootPath,
                recovery: "Pass a directory that contains TileDown content.",
            )
            return report
        }
        report.addCheck("content root", options.contentRootPath)

        guard let configuration = doctorConfiguration(for: options, report: &report) else {
            return report
        }

        addContentSummary(to: &report, options: options, configuration: configuration)
        addGeneratorDiagnostics(to: &report, options: options, configuration: configuration)
        addPublishDiagnostics(to: &report, options: options, configuration: configuration)
        runDoctorBuild(options: options, configuration: configuration, report: &report)
        return report
    }

    private func contentRootExists(
        _ path: String,
    ) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(
            atPath: path,
            isDirectory: &isDirectory,
        ) && isDirectory.boolValue
    }

    private func doctorConfiguration(
        for options: DoctorOptions,
        report: inout DoctorReport,
    ) -> TileKit.Site.ConfigurationFile? {
        do {
            let configuration = try loadConfigurationFile(
                contentRootPath: options.contentRootPath,
            )
            report.addCheck("config", configurationDescription(options.contentRootPath))
            return configuration
        } catch {
            report.add(
                .error,
                code: "config.invalid",
                message: String(describing: error),
                path: configurationDescription(options.contentRootPath),
                recovery: "Fix the TileDown configuration file and run doctor again.",
            )
            return nil
        }
    }

    private func addContentSummary(
        to report: inout DoctorReport,
        options: DoctorOptions,
        configuration: TileKit.Site.ConfigurationFile,
    ) {
        do {
            let summary = try contentSummary(
                contentRootPath: options.contentRootPath,
                configuration: configuration.configuration,
            )
            report.summary = summary
            report.addCheck(
                "pages",
                "\(summary.pageCount) total, \(summary.draftCount) drafts",
            )
            report.addCheck(
                "posts",
                "\(summary.publishedPostCount) published, \(summary.draftPostCount) drafts",
            )
        } catch {
            report.add(
                .error,
                code: "content.invalid",
                message: String(describing: error),
                path: options.contentRootPath,
                recovery: "Fix the content source and run doctor again.",
            )
        }
    }

    private func addGeneratorDiagnostics(
        to report: inout DoctorReport,
        options: DoctorOptions,
        configuration: TileKit.Site.ConfigurationFile,
    ) {
        guard !configuration.generators.isEmpty else {
            report.addCheck("generators", "none")
            return
        }

        if options.runGenerators {
            report.addCheck(
                "generators",
                "\(configuration.generators.count) declared, enabled for temp build",
            )
        } else {
            report.add(
                .warning,
                code: "generator.skipped",
                message: "\(configuration.generators.count) content generator(s) declared but not run.",
                path: configurationDescription(options.contentRootPath),
                recovery: "Run tiledown doctor --run-generators \(options.contentRootPath) for a full build check.",
            )
        }
    }

    private func addPublishDiagnostics(
        to report: inout DoctorReport,
        options: DoctorOptions,
        configuration: TileKit.Site.ConfigurationFile,
    ) {
        guard options.publish else {
            return
        }

        let baseURL = configuration.configuration.baseURL
        guard isAbsoluteWebURL(baseURL) else {
            report.add(
                .error,
                code: "publish.baseURL",
                message: "Publish checks require an absolute http or https baseURL.",
                path: configurationDescription(options.contentRootPath),
                recovery: "Set baseURL in tiledown.yml before publishing.",
            )
            return
        }
        report.addCheck("publish baseURL", baseURL)
    }

    func configurationDescription(
        _ contentRootPath: String,
    ) -> String {
        for fileName in ["tiledown.yml", "tiledown.yaml"] {
            let path = URL(fileURLWithPath: contentRootPath)
                .appendingPathComponent(fileName)
                .path
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return "defaults"
    }

    private func isAbsoluteWebURL(
        _ value: String,
    ) -> Bool {
        guard let components = URLComponents(string: value),
              ["http", "https"].contains(components.scheme),
              components.host?.isEmpty == false
        else {
            return false
        }
        return true
    }
}
