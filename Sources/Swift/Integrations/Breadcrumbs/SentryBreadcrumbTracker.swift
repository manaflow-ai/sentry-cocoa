// swiftlint:disable missing_docs
internal import _SentryPrivate

#if (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK
public import UIKit
#endif

#if (os(macOS) || targetEnvironment(macCatalyst)) && !SENTRY_NO_UI_FRAMEWORK
import Cocoa
#endif

@objc @_spi(Private) public final class SentryBreadcrumbTracker: NSObject, @unchecked Sendable {
    
    private static let swizzleSendActionKey = "SentryBreadcrumbTrackerSwizzleSendAction"
    private static let swizzleViewDidAppearKey = SentryTypedSwizzle.Key()
    
    private final class State {
        weak var delegate: SentryBreadcrumbDelegate?
        var notificationObservers: [NSObjectProtocol] = []
    }

    private let state = SentryMutex(State())
    private let reportAccessibilityIdentifier: Bool
    
    @objc(initReportAccessibilityIdentifier:)
    init(reportAccessibilityIdentifier: Bool) {
        self.reportAccessibilityIdentifier = reportAccessibilityIdentifier
        super.init()
    }
    
    deinit {
        SentryDependencyContainer.sharedInstance().reachability.remove(self)
    }
    
    @objc(startWithDelegate:)
    func start(with delegate: SentryBreadcrumbDelegate) {
        state.withLock { $0.delegate = delegate }
        addEnabledCrumb()
        trackApplicationNotifications()
        trackNetworkConnectivityChanges()
    }
    
#if (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK
    @objc
    func startSwizzle() {
        swizzleSendAction()
        swizzleViewDidAppear()
    }
#endif // (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK
    
    @objc
    func stop() {
#if (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK
        SentryDependencyContainer.sharedInstance().swizzleWrapper.removeSwizzleSendAction(forKey: Self.swizzleSendActionKey)
#endif // (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK
        
        let observers = state.withLock { state in
            let observers = state.notificationObservers
            state.notificationObservers.removeAll()
            state.delegate = nil
            return observers
        }
        let notificationCenter = NotificationCenter.default
        for observer in observers {
            notificationCenter.removeObserver(observer)
        }
        stopTrackNetworkConnectivityChanges()
    }
    
    private func trackApplicationNotifications() {
#if (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK
        trackApplicationNotificationsUIKit()
#elseif os(macOS) && !SENTRY_NO_UI_FRAMEWORK
        trackApplicationNotificationsMacOS()
#else // watchOS or other platforms
        SentrySDKLog.debug("NO UIKit, macOS and Catalyst -> [SentryBreadcrumbTracker trackApplicationNotifications] does nothing.")
#endif
    }
    
#if (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK
    private func trackApplicationNotificationsUIKit() {
        let notificationCenter = NotificationCenter.default
        
        // not available for macOS
        let memoryWarningObserver = notificationCenter.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            let crumb = Breadcrumb(level: .warning, category: "device.event")
            crumb.type = "system"
            crumb.setData(value: "LOW_MEMORY", key: "action")
            crumb.message = "Low memory"
            self.sendToDelegate(crumb)
        }
        storeNotificationObserver(memoryWarningObserver)
        
        let willEnterForegroundObserver = notificationCenter.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            self.addBreadcrumb(type: "navigation", category: "app.lifecycle", level: .info, dataKey: "state", dataValue: "foreground")
        }
        storeNotificationObserver(willEnterForegroundObserver)
        
        let didBecomeActiveObserver = notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            self.addBreadcrumb(type: "navigation", category: "app.lifecycle", level: .info, dataKey: "state", dataValue: "active")
        }
        storeNotificationObserver(didBecomeActiveObserver)
        
        let willResignActiveObserver = notificationCenter.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            self.addBreadcrumb(type: "navigation", category: "app.lifecycle", level: .info, dataKey: "state", dataValue: "inactive")
        }
        storeNotificationObserver(willResignActiveObserver)
        
        let didEnterBackgroundObserver = notificationCenter.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            self.addBreadcrumb(type: "navigation", category: "app.lifecycle", level: .info, dataKey: "state", dataValue: "background")
        }
        storeNotificationObserver(didEnterBackgroundObserver)
    }
#endif // (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK
    
#if os(macOS) && !SENTRY_NO_UI_FRAMEWORK
    private func trackApplicationNotificationsMacOS() {
        let notificationCenter = NotificationCenter.default
        
        let didBecomeActiveObserver = notificationCenter.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            self.addBreadcrumb(type: "navigation", category: "app.lifecycle", level: .info, dataKey: "state", dataValue: "active")
        }
        storeNotificationObserver(didBecomeActiveObserver)
        
        let willResignActiveObserver = notificationCenter.addObserver(
            forName: NSApplication.willResignActiveNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            self.addBreadcrumb(type: "navigation", category: "app.lifecycle", level: .info, dataKey: "state", dataValue: "inactive")
        }
        storeNotificationObserver(willResignActiveObserver)
    }
#endif // os(macOS)
    
    private func trackNetworkConnectivityChanges() {
        SentryDependencyContainer.sharedInstance().reachability.add(self)
    }
    
    private func stopTrackNetworkConnectivityChanges() {
        SentryDependencyContainer.sharedInstance().reachability.remove(self)
    }

    private func storeNotificationObserver(_ observer: NSObjectProtocol) {
        state.withLock { $0.notificationObservers.append(observer) }
    }

    private func sendToDelegate(_ crumb: Breadcrumb) {
        let delegate = state.withLock { $0.delegate }
        delegate?.add(crumb)
    }
    
    private func addBreadcrumb(type: String, category: String, level: SentryLevel, dataKey: String, dataValue: String) {
        let crumb = Breadcrumb(level: level, category: category)
        crumb.type = type
        crumb.setData(value: dataValue, key: dataKey)
        sendToDelegate(crumb)
    }
    
    private func addEnabledCrumb() {
        let crumb = Breadcrumb(level: .info, category: "started")
        crumb.type = "debug"
        crumb.message = "Breadcrumb Tracking"
        sendToDelegate(crumb)
    }
    
#if (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK
    @MainActor
    private static func avoidSender(_ sender: Any?, forTarget target: Any?, action: String) -> Bool {
        guard let sender = sender, let target = target else {
            return true
        }
        
        if let textField = sender as? UITextField {
            // This is required to avoid creating breadcrumbs for every key pressed in a text field.
            // Textfield may invoke many types of event, in order to check if is a
            // `UIControlEventEditingChanged` we need to compare the current action to all events
            // attached to the control. This may cause a false negative if the developer is using the
            // same action for different events, but this trade off is acceptable because using the same
            // action for `.editingChanged` and another event is not supposed to happen.
            let actions = textField.actions(forTarget: target, forControlEvent: .editingChanged)
            return actions?.contains(action) ?? false
        }
        return false
    }
    
    private func swizzleSendAction() {
        SentryDependencyContainer.sharedInstance().swizzleWrapper.swizzleSendAction(
            { [weak self] action, target, sender, event in
                MainActor.assumeIsolated {
                    guard let self = self else { return }

                    if Self.avoidSender(sender, forTarget: target, action: action) {
                        return
                    }

                    var data: [String: Any]?
                    if let event = event {
                        for touch in event.allTouches ?? [] {
                            if let view = touch.view,
                               touch.phase == .cancelled || touch.phase == .ended {
                                data = Self.extractData(from: view, includeAccessibilityIdentifier: self.reportAccessibilityIdentifier)
                            }
                        }
                    }

                    let crumb = Breadcrumb(level: .info, category: "touch", data: data ?? [:])
                    crumb.type = "user"
                    crumb.message = action
                    self.sendToDelegate(crumb)
                }
            },
            forKey: Self.swizzleSendActionKey
        )
    }
    
    private func swizzleViewDidAppear() {
        let tracker = WeakReference(value: self)
        SentrySwizzleWrapperHelper.swizzleViewDidAppear(
            { viewController in
                MainActor.assumeIsolated {
                    guard let self = tracker.value else { return }

                    let crumb = Breadcrumb(level: .info, category: "ui.lifecycle", data: Self.fetchInfo(about: viewController))
                    crumb.type = "navigation"
                    self.sendToDelegate(crumb)
                }
            },
            forKey: Self.swizzleViewDidAppearKey.pointer
        )
    }
    
    @_spi(Private)
    @MainActor
    public static func extractData(from view: UIView, includeAccessibilityIdentifier: Bool) -> [String: Any] {
        var result: [String: Any] = ["view": SwiftDescriptor.getSanitizedViewDescription(view)]

        if view.tag > 0 {
            result["tag"] = view.tag
        }

        if includeAccessibilityIdentifier,
           let identifier = view.accessibilityIdentifier,
           !identifier.isEmpty {
            result["accessibilityIdentifier"] = identifier
        }

        if let button = view as? UIButton,
           let title = button.currentTitle,
           !title.isEmpty {
            result["title"] = title
        }

        return result
    }

    @MainActor
    private static func fetchInfo(about controller: UIViewController) -> [String: Any] {
        var info: [String: Any] = [:]
        
        info["screen"] = SwiftDescriptor.getViewControllerClassName(controller)
        
        if let title = controller.navigationItem.title, !title.isEmpty {
            info["title"] = controller.navigationItem.title
        } else if let title = controller.title, !title.isEmpty {
            info["title"] = title
        }
        
        info["beingPresented"] = controller.isBeingPresented ? "true" : "false"
        
        if let presentingViewController = controller.presentingViewController {
            info["presentingViewController"] = SwiftDescriptor.getViewControllerClassName(presentingViewController)
        }
        
        if let parentViewController = controller.parent {
            info["parentViewController"] = SwiftDescriptor.getViewControllerClassName(parentViewController)
        }
        
        if let window = controller.view?.window {
            info["window"] = SwiftDescriptor.getSanitizedViewDescription(window)
            info["window_isKeyWindow"] = window.isKeyWindow ? "true" : "false"
            info["window_windowLevel"] = String(describing: window.windowLevel.rawValue)
            info["is_window_rootViewController"] = (window.rootViewController == controller) ? "true" : "false"
        }
        
        return info
    }
#endif // (os(iOS) || os(tvOS) || os(visionOS)) && !SENTRY_NO_UI_FRAMEWORK
}

extension SentryBreadcrumbTracker: SentryReachabilityObserver {
    @objc
    public func connectivityChanged(_ connected: Bool, typeDescription: String) {
        let crumb = Breadcrumb(level: .info, category: "device.connectivity")
        crumb.type = "connectivity"
        crumb.setData(value: typeDescription, key: "connectivity")
        sendToDelegate(crumb)
    }
}
// swiftlint:enable missing_docs
