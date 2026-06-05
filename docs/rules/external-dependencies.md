# No External Dependencies

Tiledown is static, fast, and portable. Do not add new external dependencies to
ship a feature.

## Core rule

No new external dependency may be added to the repository, build, runtime, test
suite, example site, or generated output.

This includes:

- Third-party Swift packages in `Packages/Package.swift`.
- JavaScript or CSS libraries, whether vendored, downloaded, or loaded from a
  CDN.
- Binary tools invoked by the build, generator, tests, examples, or release
  process.
- System package requirements such as Homebrew, apt, ImageMagick, Node, npm, or
  Python libraries.
- Hosted services used as part of normal build or render behavior.

## Existing state

Existing declared package dependencies are inherited project state. They are not
permission to add more dependencies, widen their scope, or introduce a second
toolchain for similar behavior.

Do not add another external package because an existing package already exists.
The dependency budget is closed.

## Required alternatives

Before reaching for a dependency:

- Use the Swift standard library, Foundation, and system frameworks already
  available on the supported platforms.
- Prefer small in-repo implementations for narrow behavior.
- Keep optional behavior optional and inert when its required platform capability
  is unavailable.
- Use protocol seams for platform-specific behavior, with concrete
  implementations kept inside the repo.
- If the feature cannot be implemented without a new dependency, stop and surface
  that as a product constraint.

## Review rule

Any change that modifies package dependencies, imports a new third-party product,
downloads code at build time, adds a CDN asset, or requires a new system tool is
not acceptable as part of ordinary feature work.

Changing this policy requires a dedicated maintainer decision and a separate
architecture note. Do not hide it inside a feature, fix, release, or example-site
change.
