# Open decision: Point-Free Dependencies library

Open question: should Tiledown adopt the [Point-Free Dependencies](https://github.com/pointfreeco/swift-dependencies) library for injecting and overriding dependencies in tests?

**Status: undecided.** This is a pending choice, not a rule. Nothing in Tiledown currently requires the library, and the [dependency-injection.md](../rules/dependency-injection.md) rules (no singletons, inject every collaborator through `init`, named protocol seams) stand on their own without it. If we adopt Dependencies, this document graduates into a rule under `docs/rules/`. Until then it captures the trade-off and the technical shape an adoption would take.

## Scope of the question

The question is about **within-module** dependency injection: replacing ad-hoc constructor wiring inside a target with struct-based, overridable dependencies. For **cross-module** seams (one module consuming another), the existing [dependency-injection.md](../rules/dependency-injection.md) rules already apply: cross-module contracts are named protocols, not closure typealiases, and concrete types are wired only at the composition root. Adopting Dependencies would not change that; it would sit alongside it for the within-module case.

## Pros

- Built-in controlled values for common system interactions: `@Dependency(\.date.now)`, `@Dependency(\.uuid)`, `@Dependency(\.continuousClock)`. These remove a class of nondeterminism from tests without hand-rolling a clock or UUID provider.
- `withDependencies` gives a clean, local override scope in tests, so a test states exactly which collaborators it controls and leaves the rest at safe defaults.
- The `@DependencyClient` macro generates unimplemented test values that fail loudly when an un-overridden endpoint is called, which surfaces missing test setup early.
- `previewValue` integrates with SwiftUI previews for the planned native app.

## Cons

- A third-party dependency on the core engine, which otherwise aims to stay lean and portable. Every consumer of `TileKit` inherits the transitive dependency.
- Struct-of-closures dependencies are a different style from the named-protocol-seam approach the project already uses for cross-module contracts. Running both styles risks inconsistency about when to reach for which.
- The macro and property-wrapper machinery add a learning surface and a compile-time cost.
- The engine core (`TileKit`, the `Tile` / `TileType` primitives, the `Tiledown` namespace) is non-UI and has few genuine external-system touchpoints so far, so the payoff may be small until the surface grows.

## Technical context (what adoption would look like)

If Tiledown adopts the library, the shape below is the expected usage. This is reference material for the decision, not a mandate.

### Dependency structure

Define dependencies as structs with closure properties:

- Use the `@DependencyClient` macro.
- Mark all closures with `@Sendable`.
- No mutable stored properties.
- Provide `liveValue`, `testValue`, and `previewValue`.

### Dependency access

Access dependencies via the `@Dependency` property wrapper:

- Use `@ObservationIgnored` with `@Dependency` in `@Observable` classes.
- Do not access dependencies directly in initializers.
- Do not use global singletons or static instances.

### System interactions to wrap

- `Date()` to `@Dependency(\.date.now)`
- `UUID()` to `@Dependency(\.uuid)`
- `Task.sleep()` to `@Dependency(\.continuousClock)`
- URLSession to a custom APIClient dependency
- FileManager to a custom FileClient dependency
- UserDefaults to a custom SettingsClient dependency

### Testing

- Use `withDependencies` for test setup.
- Provide deterministic test values.
- Cover code paths with different dependency configurations.

### Escaping closures

Use `withEscapedDependencies` for escaping closures: completion handlers, delegate callbacks, library integrations (NIO, database operations).

### Pattern: basic dependency definition

```swift
@DependencyClient
struct TileClient {
    var fetchTile: @Sendable (UUID) async throws -> Tile
    var updateTile: @Sendable (Tile) async throws -> Void
    var deleteTile: @Sendable (UUID) async throws -> Void
}

extension TileClient: DependencyKey {
    static let liveValue = TileClient(
        fetchTile: { tileID in
            let url = URL(string: "https://api.example.com/tiles/\(tileID)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(Tile.self, from: data)
        },
        updateTile: { tile in
            var request = URLRequest(url: URL(string: "https://api.example.com/tiles/\(tile.id)")!)
            request.httpMethod = "PUT"
            request.httpBody = try JSONEncoder().encode(tile)
            _ = try await URLSession.shared.data(for: request)
        },
        deleteTile: { tileID in
            var request = URLRequest(url: URL(string: "https://api.example.com/tiles/\(tileID)")!)
            request.httpMethod = "DELETE"
            _ = try await URLSession.shared.data(for: request)
        }
    )

    static let testValue = TileClient()

    static let previewValue = TileClient(
        fetchTile: { _ in .mock },
        updateTile: { _ in },
        deleteTile: { _ in }
    )
}

extension DependencyValues {
    var tileClient: TileClient {
        get { self[TileClient.self] }
        set { self[TileClient.self] = newValue }
    }
}
```

### Pattern: stateful dependencies with actors

```swift
@DependencyClient
struct CacheClient {
    var save: @Sendable (String, Data) async throws -> Void
    var load: @Sendable (String) async -> Data?
    var clear: @Sendable () async throws -> Void
}

extension CacheClient: DependencyKey {
    static let liveValue: CacheClient = {
        actor CacheActor {
            private let fileManager = FileManager.default
            private let cacheDirectory: URL

            init() throws {
                self.cacheDirectory = try fileManager
                    .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appendingPathComponent("TileCache", isDirectory: true)
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            }

            func save(key: String, data: Data) throws {
                let url = cacheDirectory.appendingPathComponent(key)
                try data.write(to: url)
            }

            func load(key: String) -> Data? {
                let url = cacheDirectory.appendingPathComponent(key)
                return try? Data(contentsOf: url)
            }

            func clear() throws {
                try fileManager.removeItem(at: cacheDirectory)
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            }
        }

        let actor = try! CacheActor()

        return CacheClient(
            save: { key, data in try await actor.save(key: key, data: data) },
            load: { key in await actor.load(key: key) },
            clear: { try await actor.clear() }
        )
    }()

    static let testValue = CacheClient()

    static let previewValue: CacheClient = {
        actor InMemoryCache {
            var storage: [String: Data] = [:]

            func save(key: String, data: Data) {
                storage[key] = data
            }

            func load(key: String) -> Data? {
                storage[key]
            }

            func clear() {
                storage.removeAll()
            }
        }

        let cache = InMemoryCache()
        return CacheClient(
            save: { key, data in await cache.save(key: key, data: data) },
            load: { key in await cache.load(key: key) },
            clear: { await cache.clear() }
        )
    }()
}
```

### Pattern: ViewModel integration (planned native app)

```swift
@Observable
final class TileDetailViewModel {
    @ObservationIgnored @Dependency(\.tileClient) private var tileClient
    @ObservationIgnored @Dependency(\.cacheClient) private var cacheClient
    @ObservationIgnored @Dependency(\.date.now) private var now
    @ObservationIgnored @Dependency(\.uuid) private var uuid

    private(set) var tile: Tile?
    private(set) var isLoading = false
    private(set) var error: Error?

    init() {
        // Dependencies are injected; never read them here.
    }

    func loadTile(id: UUID) async {
        isLoading = true
        error = nil

        do {
            if let cachedData = await cacheClient.load("\(id)"),
               let cachedTile = try? JSONDecoder().decode(Tile.self, from: cachedData) {
                self.tile = cachedTile
            }

            let tile = try await tileClient.fetchTile(id)
            self.tile = tile

            if let encoded = try? JSONEncoder().encode(tile) {
                try? await cacheClient.save("\(id)", encoded)
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }
}
```

### Pattern: escaping closures

```swift
@Observable
final class WatchViewModel {
    @ObservationIgnored @Dependency(\.fileWatcherClient) private var fileWatcher
    @ObservationIgnored @Dependency(\.date.now) private var now

    func watch() {
        withEscapedDependencies { dependencies in
            fileWatcher.observe(
                onChange: { path in
                    let timestamp = dependencies.date.now
                    print("[\(timestamp)] Changed: \(path)")
                },
                onError: { error in
                    let timestamp = dependencies.date.now
                    print("[\(timestamp)] Error: \(error)")
                }
            )
        }
    }
}
```

### Testing patterns

```swift
@Test
func tileLoading() async throws {
    let expectedTile = Tile(id: UUID(0), name: "Test Tile")

    let viewModel = withDependencies {
        $0.tileClient.fetchTile = { _ in expectedTile }
        $0.cacheClient.load = { _ in nil }
        $0.cacheClient.save = { _, _ in }
    } operation: {
        TileDetailViewModel()
    }

    await viewModel.loadTile(id: UUID(0))

    #expect(viewModel.tile == expectedTile)
    #expect(!viewModel.isLoading)
    #expect(viewModel.error == nil)
}

@Test
func tileLoadingFailure() async throws {
    struct TestError: Error {}

    let viewModel = withDependencies {
        $0.tileClient.fetchTile = { _ in throw TestError() }
        $0.cacheClient.load = { _ in nil }
    } operation: {
        TileDetailViewModel()
    }

    await viewModel.loadTile(id: UUID(0))

    #expect(viewModel.tile == nil)
    #expect(viewModel.error is TestError)
}
```

### Preview patterns (planned native app)

```swift
#Preview("Success State") {
    let _ = prepareDependencies {
        $0.tileClient.fetchTile = { _ in .mock }
    }

    TileDetailView(viewModel: TileDetailViewModel())
}

#Preview("Error State") {
    let _ = prepareDependencies {
        $0.tileClient.fetchTile = { _ in
            struct PreviewError: Error {}
            throw PreviewError()
        }
    }

    TileDetailView(viewModel: TileDetailViewModel())
}
```

## Decision criteria

Revisit and decide when one of these becomes true:

- The engine accumulates several real external-system touchpoints (network, filesystem, clock, settings) that tests need to control, and hand-rolled injection starts to feel repetitive.
- The planned native macOS/iOS app starts, bringing ViewModels and SwiftUI previews that benefit from `previewValue`.
- A determinism bug in tests traces back to an un-controlled `Date()` / `UUID()` / sleep that a built-in controlled value would have prevented.

If none of these holds, the default is to stay with plain constructor injection and named protocol seams, and keep this decision open.
