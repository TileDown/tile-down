import Testing

extension TiledownCLITests {
    @Test("help prints usage without crashing")
    func helpPrintsUsageWithoutCrashing() throws {
        for argument in ["help", "--help", "-h"] {
            let result = try runTiledown(arguments: [argument])

            #expect(result.status == 0)
            #expect(result.stdout.contains("usage:"))
            #expect(result.stdout.contains("tiledown doctor"))
            #expect(result.stdout.contains("tiledown build-site"))
            #expect(result.stdout.contains("tiledown help"))
            #expect(result.stderr.isEmpty)
        }
    }

    @Test("missing command prints usage without crashing")
    func missingCommandPrintsUsageWithoutCrashing() throws {
        let result = try runTiledown(arguments: [])

        #expect(result.status == 0)
        #expect(result.stdout.contains("usage:"))
        #expect(result.stdout.contains("tiledown doctor"))
        #expect(result.stdout.contains("tiledown help"))
        #expect(result.stderr.isEmpty)
    }

    @Test("invalid command prints usage without Swift fatal crash")
    func invalidCommandPrintsUsageWithoutSwiftFatalCrash() throws {
        let result = try runTiledown(arguments: ["nope"])

        #expect(result.status != 0)
        #expect(result.stdout.isEmpty)
        #expect(result.stderr.contains("usage:"))
        #expect(result.stderr.contains("tiledown doctor"))
        #expect(result.stderr.contains("tiledown help"))
        #expect(!result.stderr.contains("Fatal error"))
        #expect(!result.stderr.contains("Error raised at top level"))
    }
}
