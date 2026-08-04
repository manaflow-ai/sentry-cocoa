# Manaflow Sentry source fork

- This fork exists only as cmux's source-built crash-reporting dependency.
- Support macOS 14 and iOS 18 or newer.
- Build with Swift 6 language mode and strict concurrency checking.
- Use AppKit on macOS and UIKit on iOS. Do not add declarative UI adapters.
- Protect shared mutable state with `SentryMutex` or isolate it to a global actor.
- Keep `Package.swift`, `Package@swift-6.1.swift`, and `Package@swift-6.2.swift` equivalent.
- Verify changes with `swift build --disable-index-store` on macOS and an iOS consumer build.
- Preserve the upstream license and attribution.
