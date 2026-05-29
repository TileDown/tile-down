# Swift engineering: core rules

The engineering bar for every Swift task in Tiledown / TileKit. Always applies.

## Primary directive

Choose the optimal path, not the fastest. Respecting existing code, ownership, and idioms is higher priority than speed. Clarify ambiguities before coding; do not assume requirements.

## Core rules

1. **Surface 2-3 options when trade-offs matter.** Clarify uncertainty before coding. On obvious blockers (build break, own-code bug, fatal regression), fix without asking. On routine edits with no real choice, just do the work.

   **One exception:** a trivial-looking code change with non-trivial downstream blast radius (DB schema or version bump, public API break, release artefact, file-format change) needs the user's call on *semantics* even when the code is one line. The clarification is "should this be 1.0.2 to 1.0.3 or to 1.1.0?", not "I see three implementation options."

2. **Progressive architecture.** Start with the simplest thing that works. Add abstraction only when a second concrete consumer exists, then generalise when a pattern emerges. Do not pre-abstract.

   ```swift
   // 1. Direct
   func fetch() { ... }

   // 2. Protocol once a second implementation appears
   protocol Fetchable { func fetch() }

   // 3. Generic once a pattern emerges across types
   protocol Repository<T> { ... }
   ```

3. **Make impossible states unrepresentable.** Use exhaustive enums with associated values. Never force-unwrap (`!`, `try!`) in production code. Errors carry both a human-readable reason and an actionable recovery path.

4. **Testable by design.** Inject every dependency through the initialiser. Test behaviour, not implementation. Concrete framework types are wrapped behind a protocol so tests can substitute a fake.

5. **Profile, then optimise.** Use value semantics by default. Pick the right data structure first. Optimise only with a profile in hand.

## Clarification templates

Use when a task is architecturally ambiguous (see Core rule 1).

**Architecture choice:**

```text
For [FEATURE], I see these approaches:

Option A: [NAME] - [one-line benefit]
  Best when: [specific use case]
  Trade-off: [main limitation]

Option B: [NAME] - [one-line benefit]
  Best when: [specific use case]
  Trade-off: [main limitation]

Which fits [the specific concern that's driving this choice]?
```

**Technical choice:**

```text
For [TECHNICAL CHOICE]:

[OPTION 1]: [concise description]
```swift
// minimal example
```
Use when: [specific condition]

[OPTION 2]: [concise description]
```swift
// minimal example
```
Use when: [specific condition]

What's your [specific metric / constraint]?
```

## Patterns

**Dependency injection**, always inject, never hardcode:

```swift
protocol TimeProvider { var now: Date { get } }
struct Service {
    init(time: TimeProvider = SystemTime()) { ... }
}
```

**Error design**, reason + recovery, localised:

```swift
enum DomainError: LocalizedError {
    case specific(reason: String, recovery: String)

    var errorDescription: String? { /* reason */ }
    var recoverySuggestion: String? { /* recovery */ }
}
```

## Quality gates

Before declaring a Swift change done:

- [ ] No force unwrapping (`!`, `try!`) introduced
- [ ] Every error path has a recovery path or a documented terminal failure
- [ ] All new dependencies injected via the initialiser
- [ ] Every new public API is documented (one-paragraph minimum)
- [ ] Edge cases handled: `nil`, empty collection, invalid input, cancelled task
- [ ] Apple-platform APIs verified against the authoritative reference (confirm the API exists with the claimed signature and behaviour, and that it follows current Apple conventions)

## File ownership

**Never modify screens or views** unless the user has explicitly asked you to change that specific screen. This applies to every screen. If a task needs screen edits, flag which screens are affected and wait for explicit approval before editing them.

## Component discipline

A native UI app is planned for Tiledown. When it lands, UI components follow these rules:

- UI components live in their component package (e.g. `TileDownComponents`). Never inside a feature package or a screen.
- **One component per file.** File name equals component name (e.g. `TilePreviewComponent.swift` contains only `TilePreviewComponent`).
- Components conform to the `Component` protocol from the component package.
- Never create UI components outside the component packages. If a new component is needed, add it to the appropriate component package.
- Never inline reusable UI inside screens. Extract it as a component first.
- Follow the existing component structure: `Data` struct + `make()` method + a separate content `View` for complex UI.

## Respect existing idioms

Before writing code in a package, read the surrounding files and follow the patterns already there exactly. Do not introduce new naming conventions, new structural choices, or new dependency-injection styles that diverge from what's already in the codebase. Idiom consistency is a higher-priority signal than personal preference.
