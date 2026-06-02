import Foundation

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

extension TiledownCLITests {
    func terminateServeProcess(
        _ process: Process,
    ) {
        guard process.isRunning else {
            process.waitUntilExit()
            return
        }

        process.terminate()
        let deadline = Date().addingTimeInterval(2)
        while process.isRunning, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        if process.isRunning {
            killProcess(process.processIdentifier)
        }
        process.waitUntilExit()
    }
}

private func killProcess(
    _ identifier: Int32,
) {
    #if canImport(Darwin)
        _ = Darwin.kill(identifier, SIGKILL)
    #elseif canImport(Glibc)
        _ = Glibc.kill(identifier, SIGKILL)
    #endif
}
