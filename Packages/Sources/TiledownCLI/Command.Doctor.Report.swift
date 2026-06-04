import Foundation

struct DoctorOptions {
    var publish = false
    var strict = false
    var includeDrafts = false
    var runGenerators = false
    var json = false
    var keepTemp = false
    var help = false
    var contentRootPath = "."
}

struct DoctorReport {
    var commandVersion: String
    var contentRootPath: String
    var publish: Bool
    var checks: [DoctorCheck] = []
    var diagnostics: [DoctorDiagnostic] = []
    var summary = DoctorContentSummary()
    var tempOutputPath: String?

    var hasErrors: Bool {
        errorCount > 0
    }

    var hasWarnings: Bool {
        warningCount > 0
    }

    var errorCount: Int {
        diagnostics.count(where: { $0.severity == .error })
    }

    var warningCount: Int {
        diagnostics.count(where: { $0.severity == .warning })
    }

    var status: String {
        if hasErrors {
            return "error"
        }
        if hasWarnings {
            return "warning"
        }
        return "ok"
    }

    var json: DoctorJSONReport {
        .init(
            status: status,
            commandVersion: commandVersion,
            contentRootPath: contentRootPath,
            publish: publish,
            summary: .init(
                errors: errorCount,
                warnings: warningCount,
                pages: summary.pageCount,
                publishedPosts: summary.publishedPostCount,
                draftPosts: summary.draftPostCount,
            ),
            checks: checks,
            diagnostics: diagnostics,
            tempOutputPath: tempOutputPath,
        )
    }

    mutating func addCheck(
        _ name: String,
        _ detail: String,
    ) {
        checks.append(.init(name: name, detail: detail))
    }

    mutating func add(
        _ severity: DoctorSeverity,
        code: String,
        message: String,
        path: String? = nil,
        recovery: String? = nil,
    ) {
        diagnostics.append(.init(
            severity: severity,
            code: code,
            message: message,
            path: path,
            recovery: recovery,
        ))
    }
}

struct DoctorContentSummary {
    var pageCount = 0
    var draftCount = 0
    var publishedPostCount = 0
    var draftPostCount = 0
}

struct DoctorCheck: Codable, Equatable {
    var name: String
    var detail: String
}

enum DoctorSeverity: String, Codable {
    case warning
    case error
}

struct DoctorDiagnostic: Codable, Equatable {
    var severity: DoctorSeverity
    var code: String
    var message: String
    var path: String?
    var recovery: String?

    var humanLine: String {
        let prefix = severity == .error ? "ERROR" : "WARN "
        let pathSuffix = path.map { " [\($0)]" } ?? ""
        return "\(prefix) \(code): \(message)\(pathSuffix)"
    }
}

struct DoctorJSONReport: Codable, Equatable {
    var status: String
    var commandVersion: String
    var contentRootPath: String
    var publish: Bool
    var summary: DoctorJSONSummary
    var checks: [DoctorCheck]
    var diagnostics: [DoctorDiagnostic]
    var tempOutputPath: String?
}

struct DoctorJSONSummary: Codable, Equatable {
    var errors: Int
    var warnings: Int
    var pages: Int
    var publishedPosts: Int
    var draftPosts: Int
}

extension Command {
    func printDoctorReport(
        _ report: DoctorReport,
    ) {
        print("TileDown Doctor")
        print("")
        for check in report.checks {
            print("OK   \(check.name): \(check.detail)")
        }
        for diagnostic in report.diagnostics {
            print(diagnostic.humanLine)
            if let recovery = diagnostic.recovery {
                print("      recovery: \(recovery)")
            }
        }
        print("")
        print("Summary: \(report.errorCount) errors, \(report.warningCount) warnings")
    }

    func printDoctorJSON(
        _ report: DoctorReport,
    ) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(report.json)
        print(String(data: data, encoding: .utf8) ?? "{}")
    }
}
