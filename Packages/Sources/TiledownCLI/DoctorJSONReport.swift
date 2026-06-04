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
