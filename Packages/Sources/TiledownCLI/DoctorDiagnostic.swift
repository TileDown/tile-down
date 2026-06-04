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
