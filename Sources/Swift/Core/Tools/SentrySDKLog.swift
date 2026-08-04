// swiftlint:disable missing_docs
import Foundation

public typealias SentryLogOutput = @Sendable (String) -> Void

/// Logging state is protected by `SentryMutex`, so configuration and output changes are immediately
/// visible to every thread without racing concurrent log calls.
@objc
@_spi(Private) public final class SentrySDKLog: NSObject {

    private struct State {
        var isDebug = true
        var diagnosticLevel = SentryLevel.error
        var logOutput: SentryLogOutput
        var dateProvider: SentryCurrentDateProvider
    }

    private static let defaultLogOutput: SentryLogOutput = { print($0) }
    private static let state = SentryMutex(
        State(
            logOutput: defaultLogOutput,
            dateProvider: SentryDefaultCurrentDateProvider()
        )
    )

    static private(set) var isDebug: Bool {
        get { state.withLock { $0.isDebug } }
        set { state.withLock { $0.isDebug = newValue } }
    }

    static private(set) var diagnosticLevel: SentryLevel {
        get { state.withLock { $0.diagnosticLevel } }
        set { state.withLock { $0.diagnosticLevel = newValue } }
    }

    /**
     * Threshold log level to always log, regardless of the current configuration
     */
    static let alwaysLevel = SentryLevel.fatal
    static func _configure(_ isDebug: Bool, diagnosticLevel: SentryLevel) {
        state.withLock {
            $0.isDebug = isDebug
            $0.diagnosticLevel = diagnosticLevel
        }
    }

    @objc
    public static func log(message: String, andLevel level: SentryLevel) {
        guard willLog(atLevel: level) else { return }

        // We use the time interval because date format is
        // expensive and we only care about the time difference between the
        // log messages. We don't use system uptime because of privacy concerns
        // see: NSPrivacyAccessedAPICategorySystemBootTime.
        let (time, output) = state.withLock {
            ($0.dateProvider.date().timeIntervalSince1970, $0.logOutput)
        }
        output("[Sentry] [\(level)] [\(time)] \(message)")
    }

    /**
     * @return @c YES if the current logging configuration will log statements at the current level,
     * @c NO if not.
     */
    @objc
    public static func willLog(atLevel level: SentryLevel) -> Bool {
        if level == .none {
            return false
        }
        if level.rawValue >= alwaysLevel.rawValue {
            return true
        }
        return state.withLock {
            $0.isDebug && level.rawValue >= $0.diagnosticLevel.rawValue
        }
    }

    /// Sets a custom log output handler. This allows hybrid SDKs (React Native, Flutter, etc.)
    /// to intercept SDK log messages and forward them to their respective consoles.
    /// - Note: Exposed through `PrivateSentrySDKOnly.setLogOutput` for hybrid SDK consumption.
    /// - Parameter output: A closure to handle log output. If `nil` is passed (which can happen
    ///   from Objective-C callers despite nullability annotations), the default `print` handler is used.
    @objc
    public static func setOutput(_ output: SentryLogOutput?) {
        // Objective-C callers can pass nil at runtime despite NS_ASSUME_NONNULL annotations.
        // Fall back to default print handler to prevent crashes when logging.
        state.withLock { $0.logOutput = output ?? defaultLogOutput }
    }

    #if SENTRY_TEST || SENTRY_TEST_CI

        static func getOutput() -> SentryLogOutput {
            state.withLock { $0.logOutput }
        }

        static func setDateProvider(_ dateProvider: SentryCurrentDateProvider) {
            state.withLock { $0.dateProvider = dateProvider }
        }

    #endif
}

extension SentrySDKLog {
    private static func log(level: SentryLevel, message: String, file: String, line: Int) {
        guard willLog(atLevel: level) else { return }
        let path = file as NSString
        let fileName = (path.lastPathComponent as NSString).deletingPathExtension
        log(message: "[\(fileName):\(line)] \(message)", andLevel: level)
    }

    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .debug, message: message, file: file, line: line)
    }

    static func info(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .info, message: message, file: file, line: line)
    }

    static func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .warning, message: message, file: file, line: line)
    }

    static func error(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .error, message: message, file: file, line: line)
    }

    static func fatal(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .fatal, message: message, file: file, line: line)
    }
}
// swiftlint:enable missing_docs
