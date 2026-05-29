# Point-Free Dependencies Rules

How to wire within-module dependency injection in TileKit using Point-Free's Dependencies library with struct-based dependencies.

Scope: **within-module** dependency injection using Point-Free's Dependencies library with struct-based dependencies. For **cross-module** seams (one module consuming another), see `dependency-injection.md` rules 1 to 4: cross-module contracts are named protocols, not closure typealiases, and concrete types are wired only at the composition root.

All external system interactions must be controlled through dependencies for testability and determinism.

## Core rules

### Rule 1: Dependency structure

Define dependencies as structs with closure properties:
- MUST use `@DependencyClient` macro
- MUST mark all closures with `@Sendable`
- MUST NOT have mutable stored properties
- MUST provide `liveValue`, `testValue`, and `previewValue`

### Rule 2: Dependency access

Access dependencies via `@Dependency` property wrapper:
- MUST use `@ObservationIgnored` with `@Dependency` in `@Observable` classes
- MUST NOT access dependencies directly in initializers
- MUST NOT use global singletons or static instances

### Rule 3: System interactions

Wrap these system calls in dependencies:
- `Date()` to `@Dependency(\.date.now)`
- `UUID()` to `@Dependency(\.uuid)`
- `Task.sleep()` to `@Dependency(\.continuousClock)`
- URLSession to a custom APIClient dependency
- FileManager to a custom FileClient dependency
- UserDefaults to a custom SettingsClient dependency

### Rule 4: Testing

Override dependencies in tests:
- MUST use `withDependencies` for test setup
- MUST provide deterministic test values
- MUST test all code paths with different dependency configurations

### Rule 5: Escaping closures

Use `withEscapedDependencies` for escaping closures:
- Required for completion handlers
- Required for delegate callbacks
- Required for library integrations (NIO, database operations)

## Implementation patterns

### Pattern 1: Basic dependency definition

```swift
// RULE: Every dependency MUST follow this structure
@DependencyClient
struct TileClient {
    // RULE: All methods MUST be @Sendable closures
    var fetchTile: @Sendable (UUID) async throws -> Tile
    var updateTile: @Sendable (Tile) async throws -> Void
    var deleteTile: @Sendable (UUID) async throws -> Void
}

// RULE: MUST implement DependencyKey
extension TileClient: DependencyKey {
    // RULE: MUST provide liveValue with real implementation
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

    // RULE: MUST provide testValue (unimplemented by default)
    static let testValue = TileClient()

    // RULE: SHOULD provide previewValue for SwiftUI previews
    static let previewValue = TileClient(
        fetchTile: { _ in .mock },
        updateTile: { _ in },
        deleteTile: { _ in }
    )
}

// RULE: MUST register in DependencyValues
extension DependencyValues {
    var tileClient: TileClient {
        get { self[TileClient.self] }
        set { self[TileClient.self] = newValue }
    }
}
```

### Pattern 2: Stateful dependencies with actors

```swift
// RULE: Use actors for thread-safe state management
@DependencyClient
struct CacheClient {
    var save: @Sendable (String, Data) async throws -> Void
    var load: @Sendable (String) async -> Data?
    var clear: @Sendable () async throws -> Void
}

extension CacheClient: DependencyKey {
    static let liveValue: CacheClient = {
        // RULE: Internal state MUST be managed by actors
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

        // RULE: Create actor once and share across closures
        let actor = try! CacheActor()

        return CacheClient(
            save: { key, data in try await actor.save(key: key, data: data) },
            load: { key in await actor.load(key: key) },
            clear: { try await actor.clear() }
        )
    }()

    static let testValue = CacheClient()

    // RULE: Preview implementations can use in-memory storage
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

### Pattern 3: ViewModel integration

```swift
// RULE: ViewModels MUST declare dependencies with @ObservationIgnored
@Observable
final class TileDetailViewModel {
    // RULE: MUST use @ObservationIgnored to prevent observation of dependencies
    @ObservationIgnored @Dependency(\.tileClient) private var tileClient
    @ObservationIgnored @Dependency(\.cacheClient) private var cacheClient
    @ObservationIgnored @Dependency(\.date.now) private var now
    @ObservationIgnored @Dependency(\.uuid) private var uuid

    private(set) var tile: Tile?
    private(set) var isLoading = false
    private(set) var error: Error?

    // RULE: NEVER access dependencies in init
    init() {
        // Dependencies are automatically injected
    }

    func loadTile(id: UUID) async {
        isLoading = true
        error = nil

        do {
            // RULE: Try cache first
            if let cachedData = await cacheClient.load("\(id)"),
               let cachedTile = try? JSONDecoder().decode(Tile.self, from: cachedData) {
                self.tile = cachedTile
            }

            // RULE: Fetch fresh data
            let tile = try await tileClient.fetchTile(id)
            self.tile = tile

            // RULE: Update cache
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

### Pattern 4: Escaping closures

```swift
// RULE: MUST use withEscapedDependencies for escaping closures
@Observable
final class WatchViewModel {
    @ObservationIgnored @Dependency(\.fileWatcherClient) private var fileWatcher
    @ObservationIgnored @Dependency(\.date.now) private var now

    func watch() {
        // RULE: Wrap escaping closures with withEscapedDependencies
        withEscapedDependencies { dependencies in
            fileWatcher.observe(
                onChange: { path in
                    // Dependencies are available here
                    let timestamp = dependencies.date.now
                    print("[\(timestamp)] Changed: \(path)")
                },
                onError: { error in
                    // Dependencies are available here
                    let timestamp = dependencies.date.now
                    print("[\(timestamp)] Error: \(error)")
                }
            )
        }
    }
}
```

## Testing patterns

### Pattern 1: Basic test override

```swift
// RULE: ALWAYS use withDependencies in tests
@Test
func tileLoading() async throws {
    let expectedTile = Tile(id: UUID(0), name: "Test Tile")

    let viewModel = withDependencies {
        // RULE: Override only needed dependencies
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

// RULE: Test error scenarios
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

### Pattern 2: Complex test scenarios

```swift
// RULE: Create test helpers for common scenarios
extension TileClient {
    static func failing(error: Error) -> TileClient {
        TileClient(
            fetchTile: { _ in throw error },
            updateTile: { _ in throw error },
            deleteTile: { _ in throw error }
        )
    }

    static func delayed(by duration: Duration) -> TileClient {
        withDependencies {
            $0.continuousClock = .immediate
        } operation: {
            @Dependency(\.continuousClock) var clock

            return TileClient(
                fetchTile: { id in
                    try await clock.sleep(for: duration)
                    return Tile(id: id, name: "Delayed Tile")
                },
                updateTile: { _ in
                    try await clock.sleep(for: duration)
                },
                deleteTile: { _ in
                    try await clock.sleep(for: duration)
                }
            )
        }
    }
}

// RULE: Test timing and cancellation
@Test
func loadingCancellation() async throws {
    let viewModel = withDependencies {
        $0.tileClient = .delayed(by: .seconds(1))
        $0.continuousClock = .immediate
    } operation: {
        TileDetailViewModel()
    }

    let task = Task {
        await viewModel.loadTile(id: UUID(0))
    }

    // Cancel immediately
    task.cancel()
    await task.value

    #expect(viewModel.tile == nil)
}
```

## Preview patterns

```swift
// RULE: Use prepareDependencies for SwiftUI previews
#Preview("Success State") {
    let _ = prepareDependencies {
        $0.tileClient.fetchTile = { _ in .mock }
    }

    TileDetailView(viewModel: TileDetailViewModel())
}

#Preview("Loading State") {
    let _ = prepareDependencies {
        $0.tileClient.fetchTile = { _ in
            try await Task.sleep(for: .seconds(10))
            return .mock
        }
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

## Decision trees

### When to create a dependency?

```
Does the code interact with external systems?
├─ YES → Create a dependency
│   ├─ Network calls → APIClient
│   ├─ File system → FileClient
│   ├─ User defaults → SettingsClient
│   ├─ System time → Use built-in date/clock
│   └─ Random values → Use built-in uuid
└─ NO → Use regular functions/computed properties
```

### How to structure dependencies?

```
Is the dependency stateless?
├─ YES → Simple struct with closures
└─ NO → Does it need thread safety?
    ├─ YES → Use actor for internal state
    └─ NO → Consider if it should be stateless
```

### Testing strategy?

```
What aspect needs testing?
├─ Success path → Override with successful responses
├─ Error handling → Override with throwing implementations
├─ Timing/delays → Use immediate clock + controlled delays
├─ Cancellation → Use immediate clock + task cancellation
└─ State changes → Override multiple times in sequence
```

## Common mistakes to avoid

### DON'T: Access dependencies in init
```swift
// WRONG
@Observable
final class BadViewModel {
    let api = DependencyValues.liveValue.tileClient // Will crash in tests!
}
```

### DON'T: Forget @Sendable
```swift
// WRONG
@DependencyClient
struct BadClient {
    var fetch: () async -> Data // Missing @Sendable!
}
```

### DON'T: Use protocols
```swift
// WRONG
protocol TileClientProtocol {
    func fetchTile(id: UUID) async throws -> Tile
}
```

### DON'T: Have mutable state
```swift
// WRONG
@DependencyClient
struct BadCache {
    var storage: [String: Data] = [:] // Mutable state!
}
```

### DON'T: Use Task.detached
```swift
// WRONG
Task.detached {
    // Dependencies are NOT available here!
    await tileClient.fetchTile(id)
}
```

## Implementation checklist

Before submitting dependency code, verify:

- [ ] All dependencies use @DependencyClient macro
- [ ] All closures marked with @Sendable
- [ ] No mutable stored properties in dependency structs
- [ ] Live, test, and preview values defined
- [ ] Registered in DependencyValues extension
- [ ] ViewModels use @ObservationIgnored with @Dependency
- [ ] Escaping closures wrapped with withEscapedDependencies
- [ ] Tests use withDependencies for overrides
- [ ] Previews use prepareDependencies
- [ ] No direct system calls (Date(), UUID(), etc.)
- [ ] Thread-safe implementation via actors where needed
- [ ] No protocols used for dependency definition
- [ ] No global singletons or static instances
- [ ] Test helpers provided for common scenarios
