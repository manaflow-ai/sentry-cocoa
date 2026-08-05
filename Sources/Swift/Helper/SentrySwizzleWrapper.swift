// swiftlint:disable missing_docs
internal import _SentryPrivate

#if (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK
public import UIKit

@_spi(Private) public typealias SentrySwizzleSendActionCallback = @MainActor @Sendable (String, Any?, Any?, UIEvent?) -> Void

#if DEBUG
protocol SentrySwizzleWrapperProtocol {
    func swizzleSendAction(_ callback: @escaping SentrySwizzleSendActionCallback, forKey key: String)
    func removeSwizzleSendAction(forKey key: String)
}
extension SentrySwizzleWrapper: SentrySwizzleWrapperProtocol {}
#else
typealias SentrySwizzleWrapperProtocol = SentrySwizzleWrapper
#endif

@_spi(Private) @objc public class SentrySwizzleWrapper: NSObject {
    
    static let sentrySwizzleSendActionCallbacks = SentryMutex<[String: SentrySwizzleSendActionCallback]>([:])
    
    @objc public func swizzleSendAction(_ callback: @escaping SentrySwizzleSendActionCallback, forKey key: String) {
        let shouldInstall = Self.sentrySwizzleSendActionCallbacks.withLock { callbacks -> Bool in
            callbacks[key] = callback
            return callbacks.count == 1
        }
        SentrySDKLog.debug("Swizzling sendAction for \(key)")

        if !shouldInstall {
            return
        }

        SentrySwizzleWrapperHelper.swizzle { action, target, sender, event in
            Self.sendActionCalled(action, target: target, sender: sender, event: event)
        }
    }
    
    /// For testing. We want the swizzling block above to call a static function to avoid having a block
    /// reference to an instance of this class.
    static func sendActionCalled(_ action: Selector, target: Any?, sender: Any?, event: UIEvent?) {
        let callbacks = Self.sentrySwizzleSendActionCallbacks.withLock { Array($0.values) }
        let target = SentryUncheckedSendable(target)
        let sender = SentryUncheckedSendable(sender)
        let event = SentryUncheckedSendable(event)
        MainActor.assumeIsolated {
            for callback in callbacks {
                callback(String(cString: sel_getName(action)), target.value, sender.value, event.value)
            }
        }
    }

    @objc public func removeSwizzleSendAction(forKey key: String) {
        _ = Self.sentrySwizzleSendActionCallbacks.withLock { $0.removeValue(forKey: key) }
    }
    
    func removeAllCallbacks() {
        Self.sentrySwizzleSendActionCallbacks.withLock { $0.removeAll() }
    }
    
    // For test purposes
    static func hasCallbacks() -> Bool {
        sentrySwizzleSendActionCallbacks.withLock { !$0.isEmpty }
    }
}
#endif
// swiftlint:enable missing_docs
