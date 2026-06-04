import Foundation

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
