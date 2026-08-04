# Manaflow Sentry source fork

This repository is a narrow source-built Sentry dependency for cmux. It is derived from Sentry Cocoa 9.24 and retains Sentry's original license and attribution.

The package exposes one `Sentry` library, supports macOS 14 and iOS 18 or newer, and compiles in Swift 6 language mode with strict concurrency checking. It includes native AppKit and UIKit integrations. Binary frameworks, compatibility wrappers, sample distribution projects, and optional declarative UI adapters are intentionally absent.

```swift
.package(
    url: "https://github.com/manaflow-ai/sentry-cocoa.git",
    revision: "<audited-commit>"
)
```

Build the package with:

```sh
swift build --disable-index-store
```

See [LICENSE](LICENSE) for licensing terms.
