import Testing
@_spi(Private) @testable import SentrySwift

@Suite("Sentry dependency bootstrap")
struct SentryDependencyBootstrapTests {
    @Test("debug image provider shares the initialized binary image cache")
    func debugImageProviderUsesDependencyCache() {
        let cache = Dependencies.binaryImageCache
        let provider = Dependencies.debugImageProvider

        #expect(provider.binaryImageCache === cache)
    }
}
