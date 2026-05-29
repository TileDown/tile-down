# App Font Registration Rules

Font-registration rules for the planned Tiledown native macOS editor app (the engine is non-UI and is out of scope here). Register custom fonts using Core Text in SPM packages. Never use Info.plist approaches. Resources must use `.process()` in Package.swift and always use `Bundle.module` for resource access.

## Core rules

### Rule 1: CoreText registration

Use `CTFontManagerRegisterFontsForURL` for font registration:

- MUST import CoreText and CoreGraphics.
- MUST use `Bundle.module` (NOT `Bundle.main`).
- MUST handle errors with `Unmanaged<CFError>?`.
- MUST provide console logging for success/failure.
- MUST filter font files by extension (.otf, .ttf).

### Rule 2: Package.swift configuration

Use `.process()` for font resources:

- NEVER use `.copy()`. It will not work with `Bundle.module`.
- MUST organize fonts in a dedicated subdirectory (e.g. `Fonts/`).
- The package MUST have zero dependencies (foundation layer).

### Rule 3: Platform imports

Import the macOS UI framework where platform types are needed:

- Use `#if canImport(AppKit)` and import AppKit for platform types.
- Core Text and Core Graphics are the registration APIs and need no UI framework import to register fonts.

### Rule 4: App initialization

Register fonts in app init **before** UI renders:

- Call in `App.init()` or `AppDelegate.applicationDidFinishLaunching`.
- Registration is synchronous and must complete before SwiftUI renders.

### Rule 5: Never use Info.plist

Do not use Info.plist font registration in SPM packages:

- `UIAppFonts` only works in app bundles, NOT packages.
- `ATSApplicationFontsPath` only works in app bundles.
- CoreText is the ONLY approach that works in SPM packages.

## Implementation pattern

### Package.swift configuration

```swift
let appFontTarget = Target.target(
    name: "AppFont",
    dependencies: [],  // Foundation layer; zero dependencies
    resources: [
        .process("Fonts"),  // MUST be .process(); .copy() silently fails to register fonts
    ]
)
```

Why `.process()` not `.copy()`:

- `.process()`: resources processed and accessible via `Bundle.module`.
- `.copy()`: resources copied verbatim, may not work correctly.

### Font registration implementation

```swift
import CoreGraphics
import CoreText
import Foundation

#if canImport(AppKit)
import AppKit
#endif

public enum FontRegistration {
    /// Register custom fonts shipped with the AppFont package.
    public static func registerFonts() {
        // Use Bundle.module for SPM packages.
        guard let resourceURLs = Bundle.module.urls(
            forResourcesWithExtension: nil,
            subdirectory: nil
        ) else {
            print("No resources found in AppFont bundle")
            return
        }

        // Filter by font extension (.otf, .ttf).
        let fontURLs = resourceURLs.filter { url in
            let ext = url.pathExtension.lowercased()
            return ext == "otf" || ext == "ttf"
        }

        guard !fontURLs.isEmpty else {
            print("No font files found in AppFont bundle")
            return
        }

        // Register each font with error handling.
        for url in fontURLs {
            var errorRef: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(
                url as CFURL,
                .process,  // Register for the current process
                &errorRef
            )

            if !success {
                print("Failed to register font: \(url.lastPathComponent)")
                if let error = errorRef?.takeRetainedValue() {
                    print("   Error: \(error)")
                }
            } else {
                print("Registered font: \(url.lastPathComponent)")
            }
        }
    }
}
```

### Package directory structure

```
Sources/AppFont/
├── FontRegistration.swift   # CoreText registration (this file)
├── ScaledFont.swift         # Font modifiers (e.g. .appFont())
├── FontStyles.swift         # Font style definitions
└── Fonts/                   # Font resources
    ├── EditorSans-Regular.otf
    ├── EditorSans-Bold.otf
    ├── EditorSans-Light.otf
    └── EditorSans-Italic.otf
```

### App initialization

```swift
import SwiftUI
import AppFont

@main
struct TiledownApp: App {
    init() {
        // Register fonts before any UI renders.
        FontRegistration.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Font usage in SwiftUI

```swift
import SwiftUI
import AppFont

struct MyView: View {
    var body: some View {
        VStack {
            Text("Headline")
                .appFont(.headline)  // Custom font with Dynamic Type

            Text("Body text")
                .appFont(.body)
        }
    }
}
```

## Why this pattern?

- **Works in SPM packages.** Info.plist approaches only work in app bundles; Core Text registration works in packages, frameworks, and apps.
- **Explicit error reporting.** Console logs show which fonts loaded and why a failure happened.
- **Works on macOS.** A single code path using Core Text and AppKit, no per-platform branching needed for the editor's target.
- **Uses `Bundle.module`.** SPM manages the bundle; no manual path handling.
- **Multiple formats.** `.otf` (recommended) and `.ttf`, filtered by extension.

### CoreText vs Info.plist

| Approach | Works in app bundle | Works in SPM package |
|---|---|---|
| Info.plist (`UIAppFonts`) | Yes | No |
| Info.plist (`ATSApplicationFontsPath`) | Yes | No |
| CoreText (`CTFontManagerRegisterFontsForURL`) | Yes | Yes |

CoreText is the only approach that works universally.

## Common mistakes

- Using Info.plist (`UIAppFonts` / `ATSApplicationFontsPath`) in a package: does not work.
- Using `.copy()` for resources: will not work with `Bundle.module`.
- Using `Bundle.main` in package code: `Bundle.main` is for apps, not packages.
- Skipping error handling on `CTFontManagerRegisterFontsForURL`.
- Registering fonts in `.onAppear` instead of app init: too late, UI already rendered with system fonts.

## Checklist

- [ ] Used `.process()` for resources in Package.swift
- [ ] Created `FontRegistration.swift` with CoreText registration
- [ ] Imported CoreText and CoreGraphics
- [ ] Imported AppKit under `#if canImport(AppKit)` where platform types are needed
- [ ] Used `Bundle.module` for resource access
- [ ] Filtered font files by extension (.otf, .ttf)
- [ ] Used `CTFontManagerRegisterFontsForURL` with `.process` scope
- [ ] Implemented error handling with `Unmanaged<CFError>?`
- [ ] Added console logging for success/failure
- [ ] Called registration in app init BEFORE UI renders
- [ ] Fonts organized in a `Fonts/` subdirectory
- [ ] Package has zero dependencies
- [ ] NEVER used Info.plist (`UIAppFonts`, `ATSApplicationFontsPath`)
- [ ] NEVER used `Bundle.main` in package code
- [ ] NEVER used `.copy()` for font resources
