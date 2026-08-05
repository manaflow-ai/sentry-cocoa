// swiftlint:disable missing_docs
#if !os(watchOS) && !os(macOS) && !SENTRY_NO_UI_FRAMEWORK
public import UIKit

@_spi(Private) @objc public protocol SentryUIDeviceWrapper {
    func start()
    func stop()
    func getSystemVersion() -> String

#if os(iOS)
    var orientation: UIDeviceOrientation { get }
    var isBatteryMonitoringEnabled: Bool { get }
    var batteryState: UIDevice.BatteryState { get }
    var batteryLevel: Float { get }
#endif
}

@_spi(Private) @objc public final class SentryDefaultUIDeviceWrapper: NSObject, SentryUIDeviceWrapper, @unchecked Sendable {

    private struct State: Sendable {
        var systemVersion = ""
        var cleanupBatteryMonitoring = false
        var cleanupDeviceOrientationNotifications = false
    }

    private let queueWrapper: SentryDispatchQueueWrapper
    private let state = SentryMutex(State())
    
    // This one shouldn't be used because it accesses `Dependencies` directly rather than being
    // initialized with dependencies, but since we need to subclass NSObject it has to be here.
    @available(*, unavailable)
    override convenience init() {
        self.init(queueWrapper: Dependencies.dispatchQueueWrapper)
    }

    @objc public init(queueWrapper: SentryDispatchQueueWrapper) {
        self.queueWrapper = queueWrapper
    }

    @objc public func start() {
        let state = state
        queueWrapper.dispatchAsyncOnMainQueueIfNotMainThread {
            MainActor.assumeIsolated {
                let device = UIDevice.current
                var cleanupBatteryMonitoring = false
                var cleanupDeviceOrientationNotifications = false
#if os(iOS)
                if !device.isGeneratingDeviceOrientationNotifications {
                    cleanupDeviceOrientationNotifications = true
                    device.beginGeneratingDeviceOrientationNotifications()
                }

                // Needed so we can read the battery level.
                if !device.isBatteryMonitoringEnabled {
                    cleanupBatteryMonitoring = true
                    device.isBatteryMonitoringEnabled = true
                }
#endif

                state.withLock {
                    $0.systemVersion = device.systemVersion
                    $0.cleanupBatteryMonitoring = cleanupBatteryMonitoring
                    $0.cleanupDeviceOrientationNotifications = cleanupDeviceOrientationNotifications
                }
            }
        }
    }

    @objc public func stop() {
        let state = state
        queueWrapper.dispatchAsyncOnMainQueueIfNotMainThread {
            MainActor.assumeIsolated {
#if os(iOS)
                let cleanup = state.withLock { state -> (orientation: Bool, battery: Bool) in
                    let cleanup = (
                        orientation: state.cleanupDeviceOrientationNotifications,
                        battery: state.cleanupBatteryMonitoring
                    )
                    state.cleanupDeviceOrientationNotifications = false
                    state.cleanupBatteryMonitoring = false
                    return cleanup
                }
                let device = UIDevice.current
                if cleanup.orientation {
                    device.endGeneratingDeviceOrientationNotifications()
                }
                if cleanup.battery {
                    device.isBatteryMonitoringEnabled = false
                }
#endif
            }
        }
    }

    deinit {
        stop()
    }

#if os(iOS)
    @objc public var orientation: UIDeviceOrientation {
        SentryMainActor.runSync(using: queueWrapper) { UIDevice.current.orientation }
    }

    @objc public var isBatteryMonitoringEnabled: Bool {
        SentryMainActor.runSync(using: queueWrapper) { UIDevice.current.isBatteryMonitoringEnabled }
    }

    @objc public var batteryState: UIDevice.BatteryState {
        SentryMainActor.runSync(using: queueWrapper) { UIDevice.current.batteryState }
    }

    @objc public var batteryLevel: Float {
        SentryMainActor.runSync(using: queueWrapper) { UIDevice.current.batteryLevel }
    }
#endif // os(iOS)

    @objc public func getSystemVersion() -> String {
        state.withLock { $0.systemVersion }
    }
}
#endif
// swiftlint:enable missing_docs
