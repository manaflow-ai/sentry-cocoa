internal import _SentryPrivate

#if os(iOS) && !SENTRY_NO_UI_FRAMEWORK

protocol ScreenshotSourceProvider {
    var screenshotSource: SentryScreenshotSource? { get }
}

protocol WindowFactoryProvider {
    var windowFactory: SentryUserFeedbackWindowFactory { get }
}

typealias UserFeedbackIntegrationProvider = ScreenshotSourceProvider & WindowFactoryProvider

final class UserFeedbackIntegration<Dependencies: UserFeedbackIntegrationProvider>: NSObject, SwiftIntegration {

    let driver: SentryUserFeedbackIntegrationDriver

    init?(with options: Options, dependencies: Dependencies) {
        guard let configuration = options.userFeedbackConfiguration else {
            return nil
        }

        // The screenshot source is coupled to the options, but due to the dependency container being
        // tightly to the options anyways, it was decided to not pass it to the container.
        guard let screenshotSource = dependencies.screenshotSource else {
            return nil
        }

        let windowFactory = SentryUncheckedSendable(dependencies.windowFactory)
        driver = SentryMainActor.runSyncUnchecked {
            SentryUserFeedbackIntegrationDriver(
                configuration: configuration,
                screenshotSource: screenshotSource,
                windowFactory: windowFactory.value
            )
        }
    }

    func uninstall() {
        let driver = driver
        SentryMainActor.runSyncUnchecked {
            driver.stop()
        }
    }
    
    static var name: String {
        "SentryUserFeedbackIntegration"
    }
}

#endif
