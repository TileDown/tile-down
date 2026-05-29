# Testing Tiledown on Linux

The engine targets macOS and Linux (see [DESIGN.md](DESIGN.md) G3/D5). This guide
shows how to build and test the package on Linux. You do not need a Linux machine:
any of the routes below run a Linux toolchain from a macOS host.

## The authoritative gate is CI

Every push and pull request runs the full Linux build and test in GitHub Actions
(the `swift-linux` job in [`.github/workflows/ci.yml`](../.github/workflows/ci.yml),
a `swift:6.1` container running `swift build && swift test`). That is the
authoritative answer to "is it green on Linux." Everything below is for catching
breakage before you push, or for debugging a Linux-only failure interactively.

## What can differ on Linux

The core is pure Swift, so most Linux issues are compile-time: an API missing in
swift-corelibs-foundation, a wrong `#if os(...)`, a missing `import FoundationNetworking`.
A smaller class is runtime behaviour that only differs at execution (`Decimal`
formatting, `FileManager` enumeration and path semantics, `JSONEncoder` key order,
`CharacterSet`). Compile checks catch the first class; you must run the tests to
catch the second.

## Routes, lightest to heaviest

All routes below are free and open source. (OrbStack and Docker Desktop also work
but have commercial licensing; they are not required.)

### A. Docker or Colima (full build + test, CI parity)

[Colima](https://github.com/abiosoft/colima) gives a standard `docker` CLI from a
lightweight Linux VM, so the command matches CI exactly.

```sh
brew install colima docker
colima start --vm-type vz            # Apple Virtualization backend
# from the repo root:
docker run --rm -v "$PWD":/work -w /work/Packages swift:6.1 \
  bash -lc "swift build && swift test"
```

[Podman](https://podman.io) is an equally free, daemonless alternative; substitute
`podman` for `docker` after `podman machine init && podman machine start`.

### B. Lima VM with a Swift toolchain (full build + test, no Docker)

[Lima](https://github.com/lima-vm/lima) runs a Linux VM without a container layer.
Start a Linux VM, install the Swift Linux toolchain inside it (via your distro's
package manager or [swiftly](https://www.swift.org/install/linux/)), then build and
test the mounted repo from inside the VM:

```sh
# inside the VM, repo mounted at e.g. /work
cd /work/Packages && swift build && swift test
```

### C. A native Linux machine

Install Swift from [swift.org/install/linux](https://www.swift.org/install/linux/),
clone the repo, then:

```sh
cd Packages && swift build && swift test
```

### D. Cross-compile only (fast compile check, no VM, cannot run tests)

The [Static Linux SDK](https://www.swift.org/documentation/articles/static-linux-getting-started.html)
cross-compiles a Linux binary from macOS with no VM or container. It catches the
compile-time class of Linux breakage in seconds, but it cannot execute the tests,
so it is a pre-push smoke check, not a substitute for a real run. It requires the
open-source swift.org toolchain (not Xcode's) at a version matching the SDK.

```sh
swift sdk install <static-linux-sdk-url-for-your-toolchain>
cd Packages && swift build --swift-sdk aarch64-swift-linux-musl
```

## Confirming a run really happened on Linux

A Linux build produces ELF binaries under a Linux target triple, where a macOS
build would produce Mach-O under `arm64-apple-macosx`. To check:

```sh
# inside the Linux environment, from Packages/
readlink .build/debug                       # -> aarch64-unknown-linux-gnu/debug
file .build/*-linux-gnu/debug/TiledownPackageTests.xctest
# -> ELF 64-bit ... for GNU/Linux
```

## Picking a route

- Just want the answer: push and let CI run it.
- Want a fast local pre-push check: route D (cross-compile), or route A/B if you
  also want the tests to actually execute.
- Debugging a Linux-only failure: route A or B, so you can open a shell, run a
  single test with `swift test --filter <name>`, add prints, and iterate.
