// swiftlint:disable missing_docs
internal import _SentryPrivate

@objc(SentryDependencies) @_spi(Private) public final class Dependencies: NSObject {
    // These process-lifetime wrappers provide their own synchronization. They
    // are immutable compatibility seams for Objective-C callers.
    @objc nonisolated(unsafe) public static let random: SentryRandomProtocol = SentryRandom()
    @objc nonisolated(unsafe) public static let threadWrapper = SentryThreadWrapper()
    @objc nonisolated(unsafe) public static let processInfoWrapper: SentryProcessInfoSource = ProcessInfo.processInfo
    nonisolated(unsafe) static let infoPlistWrapper: SentryInfoPlistWrapperProvider = SentryInfoPlistWrapper()
    @objc nonisolated(unsafe) public static let sessionReplayEnvironmentChecker: SentrySessionReplayEnvironmentChecker = {
        SentrySessionReplayEnvironmentChecker(infoPlistWrapper: Dependencies.infoPlistWrapper)
    }()
    @objc nonisolated(unsafe) public static let dispatchQueueWrapper = SentryDispatchQueueWrapper()
    @objc nonisolated(unsafe) public static let notificationCenterWrapper: SentryNSNotificationCenterWrapper = NotificationCenter.default
    @objc nonisolated(unsafe) public static let crashWrapper = SentryCrashWrapper(processInfoWrapper: Dependencies.processInfoWrapper)
    @objc nonisolated(unsafe) public static let binaryImageCache = SentryBinaryImageCache()
    @objc nonisolated(unsafe) public static let debugImageProvider = SentryDebugImageProvider()
    @objc nonisolated(unsafe) public static let sysctlWrapper = SentrySysctl()
    @objc nonisolated(unsafe) public static let dateProvider = SentryDefaultCurrentDateProvider()
    nonisolated(unsafe) public static let objcRuntimeWrapper = SentryDefaultObjCRuntimeWrapper()
#if !os(watchOS) && !os(macOS) && !SENTRY_NO_UIKIT
    @objc nonisolated(unsafe) public static let uiDeviceWrapper = SentryDefaultUIDeviceWrapper(queueWrapper: Dependencies.dispatchQueueWrapper)
#endif // !os(watchOS) && !os(macOS) && !SENTRY_NO_UIKIT
    // Mutable only by the SDK's serialized test reset hooks.
    @objc nonisolated(unsafe) public static var threadInspector = SentryThreadInspector()
    @objc nonisolated(unsafe) public static var fileIOTracker = SentryFileIOTracker(threadInspector: threadInspector, processInfoWrapper: processInfoWrapper)
}
// swiftlint:enable missing_docs
