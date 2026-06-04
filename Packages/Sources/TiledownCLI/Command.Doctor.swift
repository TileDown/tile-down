import Foundation

extension Command {
    func doctor() throws {
        let options = try parseDoctorOptions()
        if options.help {
            print(CommandError.usage)
            return
        }

        let report = runDoctor(options)
        if options.json {
            try printDoctorJSON(report)
        } else {
            printDoctorReport(report)
        }

        if report.hasErrors || options.strict && report.hasWarnings {
            exit(1)
        }
    }

    private func parseDoctorOptions() throws -> DoctorOptions {
        var options = DoctorOptions()
        var positional: [String] = []

        for value in arguments.dropFirst() {
            if applyDoctorOption(value, to: &options) {
                continue
            }
            if value.hasPrefix("--") {
                throw CommandError.invalidArguments
            }
            positional.append(value)
        }

        guard positional.count <= 1 else {
            throw CommandError.invalidArguments
        }
        options.contentRootPath = positional.first ?? "."
        return options
    }

    private func applyDoctorOption(
        _ value: String,
        to options: inout DoctorOptions,
    ) -> Bool {
        switch value {
        case "help", "--help", "-h":
            options.help = true
        case "--publish":
            options.publish = true
        case "--strict":
            options.strict = true
        case "--drafts":
            options.includeDrafts = true
        case "--run-generators":
            options.runGenerators = true
        case "--json":
            options.json = true
        case "--keep-temp":
            options.keepTemp = true
        default:
            return false
        }
        return true
    }
}
