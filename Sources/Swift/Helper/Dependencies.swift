// swiftlint:disable missing_docs
internal import _SentryPrivate

@objc(SentryDependencies) @_spi(Private) public final class Dependencies: NSObject {
    private struct State {
        let random: SentryRandomProtocol = SentryRandom()
        let threadWrapper = SentryThreadWrapper()
        let processInfoWrapper: SentryProcessInfoSource = ProcessInfo.processInfo
        let infoPlistWrapper: SentryInfoPlistWrapperProvider = SentryInfoPlistWrapper()
        let dispatchQueueWrapper = SentryDispatchQueueWrapper()
        let notificationCenterWrapper: SentryNSNotificationCenterWrapper = NotificationCenter.default
        let binaryImageCache: SentryBinaryImageCache
        let debugImageProvider: SentryDebugImageProvider
        let sysctlWrapper = SentrySysctl()
        let dateProvider = SentryDefaultCurrentDateProvider()
        let objcRuntimeWrapper = SentryDefaultObjCRuntimeWrapper()
#if !os(watchOS) && !os(macOS) && !SENTRY_NO_UI_FRAMEWORK
        lazy var uiDeviceWrapper = SentryDefaultUIDeviceWrapper(queueWrapper: dispatchQueueWrapper)
#endif // !os(watchOS) && !os(macOS) && !SENTRY_NO_UI_FRAMEWORK

        init() {
            let binaryImageCache = SentryBinaryImageCache()
            self.binaryImageCache = binaryImageCache
            self.debugImageProvider = SentryDebugImageProvider(binaryImageCache: binaryImageCache)
        }
    }

    private static let state = SentryMutex(State())

    @objc public static var random: SentryRandomProtocol { state.withLock { $0.random } }
    @objc public static var threadWrapper: SentryThreadWrapper { state.withLock { $0.threadWrapper } }
    @objc public static var processInfoWrapper: SentryProcessInfoSource { state.withLock { $0.processInfoWrapper } }
    static var infoPlistWrapper: SentryInfoPlistWrapperProvider { state.withLock { $0.infoPlistWrapper } }
    @objc public static var dispatchQueueWrapper: SentryDispatchQueueWrapper { state.withLock { $0.dispatchQueueWrapper } }
    @objc public static var notificationCenterWrapper: SentryNSNotificationCenterWrapper { state.withLock { $0.notificationCenterWrapper } }
    @objc public static var binaryImageCache: SentryBinaryImageCache { state.withLock { $0.binaryImageCache } }
    @objc public static var debugImageProvider: SentryDebugImageProvider { state.withLock { $0.debugImageProvider } }
    @objc public static var sysctlWrapper: SentrySysctl { state.withLock { $0.sysctlWrapper } }
    @objc public static var dateProvider: SentryDefaultCurrentDateProvider { state.withLock { $0.dateProvider } }
    public static var objcRuntimeWrapper: SentryDefaultObjCRuntimeWrapper { state.withLock { $0.objcRuntimeWrapper } }
#if !os(watchOS) && !os(macOS) && !SENTRY_NO_UI_FRAMEWORK
    @objc public static var uiDeviceWrapper: SentryDefaultUIDeviceWrapper { state.withLock { $0.uiDeviceWrapper } }
#endif // !os(watchOS) && !os(macOS) && !SENTRY_NO_UI_FRAMEWORK
}
// swiftlint:enable missing_docs
