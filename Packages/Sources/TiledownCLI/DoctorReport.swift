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
