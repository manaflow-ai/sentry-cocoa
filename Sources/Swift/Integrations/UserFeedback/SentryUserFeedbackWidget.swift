// swiftlint:disable todo

import Foundation
#if os(iOS) && !SENTRY_NO_UI_FRAMEWORK
import UIKit

typealias SentryUserFeedbackWindowFactory = @MainActor @Sendable (SentryUserFeedbackConfiguration) -> UIWindow

@MainActor protocol SentryUserFeedbackWidgetDelegate: NSObjectProtocol {
    func showForm()
}

@available(iOSApplicationExtension, unavailable)
@MainActor final class SentryUserFeedbackWidget {
    private lazy var button = {
        let button = SentryUserFeedbackWidgetButtonView(config: config, target: self, selector: #selector(showForm))
        return button
    }()

    lazy var rootVC = RootViewController(config: config, button: button)

    private var window: UIWindow?

    let config: SentryUserFeedbackConfiguration
    weak var delegate: (any SentryUserFeedbackWidgetDelegate)?

    nonisolated static let defaultWindowFactory: SentryUserFeedbackWindowFactory = { config in
        // A connected scene is required to host the widget's overlay window. If launch has not
        // produced one yet, the application can show the feedback form after scene connection.
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return SentryUserFeedbackWidget.Window(config: config, windowScene: scene)
        } else {
            return SentryUserFeedbackWidget.Window(config: config)
        }
    }

    init(config: SentryUserFeedbackConfiguration, delegate: any SentryUserFeedbackWidgetDelegate, windowFactory: @escaping SentryUserFeedbackWindowFactory = defaultWindowFactory) {
        self.config = config
        self.delegate = delegate

        let window = windowFactory(config)
        window.rootViewController = rootVC
        window.isHidden = false
        self.window = window
    }

    @objc func showForm() {
        self.delegate?.showForm()
    }

    final class Window: UIWindow {
        private func _init(config: SentryUserFeedbackConfiguration) {
            windowLevel = config.widgetConfig.windowLevel
        }

        init(config: SentryUserFeedbackConfiguration, windowScene: UIWindowScene) {
            super.init(windowScene: windowScene)
            _init(config: config)
        }

        init(config: SentryUserFeedbackConfiguration) {
            super.init(frame: UIScreen.main.bounds)
            _init(config: config)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            // Only let the overlay window intercept all touches when it owns the presented form.
            if rootViewController?.presentedViewController != nil {
                return super.hitTest(point, with: event)
            }
            
            guard let result = super.hitTest(point, with: event) else {
                return nil
            }
            guard result.isKind(of: SentryUserFeedbackWidgetButtonView.self) else {
                return nil
            }
            return result
        }
    }

    final class RootViewController: UIViewController {
        let defaultWidgetSpacing: CGFloat = 8
        private(set) var isWidgetVisible = true
        weak var button: SentryUserFeedbackWidgetButtonView?
        init(config: SentryUserFeedbackConfiguration, button: SentryUserFeedbackWidgetButtonView) {
            self.button = button
            super.init(nibName: nil, bundle: nil)

            view.addSubview(button)

            var constraints = [NSLayoutConstraint]()
            if config.widgetConfig.location.contains(.bottom) {
                constraints.append(button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -config.widgetConfig.layoutUIOffset.vertical))
            }
            if config.widgetConfig.location.contains(.top) {
                constraints.append(button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: config.widgetConfig.layoutUIOffset.vertical))
            }
            if config.widgetConfig.location.contains(.trailing) {
                constraints.append(button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -config.widgetConfig.layoutUIOffset.horizontal))
            }
            if config.widgetConfig.location.contains(.leading) {
                constraints.append(button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: config.widgetConfig.layoutUIOffset.horizontal))
            }
            NSLayoutConstraint.activate(constraints)
        }

        required init?(coder: NSCoder) {
            fatalError("SentryUserFeedbackWidget.RootViewController is not intended to be initialized from a nib or storyboard.")
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            button?.updateAccessibilityFrame()
        }

        func setWidget(visible: Bool, animated: Bool) {
            isWidgetVisible = visible
            if visible {
                button?.isHidden = false
            }
            if animated && UIView.areAnimationsEnabled {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                    self.button?.alpha = visible ? 1 : 0
                } completion: { [weak self] _ in
                    guard self?.isWidgetVisible == visible else { return }
                    self?.button?.isHidden = !visible
                }
            } else {
                button?.alpha = visible ? 1 : 0
                button?.isHidden = !visible
            }
        }
    }
}

#endif // os(iOS) && !SENTRY_NO_UI_FRAMEWORK

// swiftlint:enable todo
