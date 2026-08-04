internal import _SentryPrivate
import Foundation

/**
 * Crash installation reporter that handles Sentry-specific reporting details.
 *
 * This class extends SentryCrashInstallation to provide Sentry-specific crash report
 * processing through a SentryCrashReportSink.
 */
final class SentryCrashInstallationReporter: SentryCrashInstallation {

    /// Objective-C block types do not carry Swift sendability annotations. This box makes the
    /// imported completion's immutable, copy-on-create lifetime explicit at the interop boundary.
    private final class CompletionBox: @unchecked Sendable {
        private let completion: SentryCrashReportFilterCompletion?

        init(_ completion: SentryCrashReportFilterCompletion?) {
            self.completion = completion
        }

        func call(_ reports: [Any]?, completed: Bool, error: Error?) {
            completion?(reports, completed, error)
        }
    }

    private let inAppLogic: SentryInAppLogic
    private let crashWrapper: SentryCrashWrapper
    private let dispatchQueue: SentryDispatchQueueWrapper

    init(
        inAppLogic: SentryInAppLogic,
        crashWrapper: SentryCrashWrapper,
        dispatchQueue: SentryDispatchQueueWrapper
    ) {
        self.inAppLogic = inAppLogic
        self.crashWrapper = crashWrapper
        self.dispatchQueue = dispatchQueue
        super.init(requiredProperties: [])
    }

    override func sink() -> (any SentryCrashReportFilter)? {
        return SentryCrashReportSink(
            inAppLogic: inAppLogic,
            crashWrapper: crashWrapper,
            dispatchQueue: dispatchQueue
        )
    }

    override func sendAllReports(completion onCompletion: SentryCrashReportFilterCompletion?) {
        let completionBox = CompletionBox(onCompletion)
        super.sendAllReports { filteredReports, completed, error in
            if let error = error {
                SentrySDKLog.error("Error sending crash reports: \(error.localizedDescription)")
            }
            SentrySDKLog.debug("Sent \(String(describing: filteredReports?.count)) crash report(s)")
            if completed {
                completionBox.call(filteredReports, completed: completed, error: error)
            }
        }
    }
}
