// swiftlint:disable missing_docs
import Foundation

typealias SentryLogOutput = @Sendable (String) -> Void

/// Logging configuration is captured under one lock before formatting and
/// invoking the output callback. The callback runs after the lock is released.
@objc
@_spi(Private) public final class SentrySDKLog: NSObject {

    private struct State {
        var isDebug = true
        var diagnosticLevel = SentryLevel.error
        var logOutput: SentryLogOutput = { print($0) }
        var dateProvider: SentryCurrentDateProvider = SentryDefaultCurrentDateProvider()
    }

    private static let stateLock = NSRecursiveLock()
    // Every access is serialized by `stateLock`.
    nonisolated(unsafe) private static var state = State()

    static var isDebug: Bool {
        stateLock.synchronized { state.isDebug }
    }

    static var diagnosticLevel: SentryLevel {
        stateLock.synchronized { state.diagnosticLevel }
    }

    /**
     * Threshold log level to always log, regardless of the current configuration
     */
    static let alwaysLevel = SentryLevel.fatal
    static func _configure(_ isDebug: Bool, diagnosticLevel: SentryLevel) {
        stateLock.synchronized {
            state.isDebug = isDebug
            state.diagnosticLevel = diagnosticLevel
        }
    }
    
    @objc
    public static func log(message: String, andLevel level: SentryLevel) {
        guard willLog(atLevel: level) else { return }
        
        // We use the time interval because date format is
        // expensive and we only care about the time difference between the
        // log messages. We don't use system uptime because of privacy concerns
        // see: NSPrivacyAccessedAPICategorySystemBootTime.
        let (time, output) = stateLock.synchronized {
            (state.dateProvider.date().timeIntervalSince1970, state.logOutput)
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
        return stateLock.synchronized {
            state.isDebug && level.rawValue >= state.diagnosticLevel.rawValue
        }
    }
 
    #if SENTRY_TEST || SENTRY_TEST_CI
    
    static func setOutput(_ output: @escaping SentryLogOutput) {
        stateLock.synchronized { state.logOutput = output }
    }
    
    static func getOutput() -> SentryLogOutput {
        stateLock.synchronized { state.logOutput }
    }
    
    static func setDateProvider(_ dateProvider: SentryCurrentDateProvider) {
        stateLock.synchronized { state.dateProvider = dateProvider }
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
