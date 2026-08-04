// swiftlint:disable missing_docs
#if (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK

internal import _SentryPrivate
import UIKit

@_spi(Private) @objc public final class SentryViewHierarchyProvider: NSObject, @unchecked Sendable {
    @objc public init(dispatchQueueWrapper: SentryDispatchQueueWrapper, applicationProvider: @escaping () -> SentryApplication?) {
        self._reportAccessibilityIdentifier = SentryMutex(true)
        self.dispatchQueueWrapper = dispatchQueueWrapper
        self.applicationProvider = applicationProvider
    }
    
    private let dispatchQueueWrapper: SentryDispatchQueueWrapper
    private let applicationProvider: () -> SentryApplication?
    private let _reportAccessibilityIdentifier: SentryMutex<Bool>
    
    /**
     * Whether we should add `accessibilityIdentifier` to the view hierarchy.
     */
    @objc public var reportAccessibilityIdentifier: Bool {
        get { _reportAccessibilityIdentifier.withLock { $0 } }
        set { _reportAccessibilityIdentifier.withLock { $0 = newValue } }
    }
    
    /**
     Get the view hierarchy in a json format.
     Always runs in the main thread.
     */
    @objc public func appViewHierarchyFromMainThread() -> Data? {
        SentrySDKLog.info("Starting to fetch the view hierarchy from the main thread.")
        let result = SentryMainActor.runSync(using: dispatchQueueWrapper) {
            self.appViewHierarchyOnMainActor()
        }
        SentrySDKLog.info("Finished fetching the view hierarchy from the main thread.")
        return result
    }
    
    @objc public func appViewHierarchy() -> Data? {
        SentryMainActor.runSync(using: dispatchQueueWrapper) {
            self.appViewHierarchyOnMainActor()
        }
    }

    @MainActor
    private func appViewHierarchyOnMainActor() -> Data? {
        let windows = applicationProvider()?.getWindows() ?? []
        return SentryViewHierarchyProviderHelper.appViewHierarchy(from: windows, reportAccessibilityIdentifier: reportAccessibilityIdentifier)
    }
    
    @discardableResult @objc(saveViewHierarchy:) public func saveViewHierarchy(_ filePath: String) -> Bool {
        SentryMainActor.runSync(using: dispatchQueueWrapper) {
            self.saveViewHierarchyOnMainActor(filePath)
        }
    }

    @MainActor
    private func saveViewHierarchyOnMainActor(_ filePath: String) -> Bool {
        let windows = applicationProvider()?.getWindows() ?? []
        return SentryViewHierarchyProviderHelper.saveViewHierarchy(filePath, windows: windows, reportAccessibilityIdentifier: reportAccessibilityIdentifier)
    }
}

#endif
// swiftlint:enable missing_docs
