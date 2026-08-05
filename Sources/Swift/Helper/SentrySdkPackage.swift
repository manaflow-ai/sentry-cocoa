// swiftlint:disable missing_docs
internal import _SentryPrivate
import Foundation

/// This is required to identify the package manager used when installing sentry.
private enum SentryPackageManagerOption: UInt {
    case swiftPackageManager = 0
    case cocoaPods = 1
    case unknown = 2
}

#if SWIFT_PACKAGE
private let SENTRY_PACKAGE_INFO = SentryMutex(SentryPackageManagerOption.swiftPackageManager)
#elseif COCOAPODS
private let SENTRY_PACKAGE_INFO = SentryMutex(SentryPackageManagerOption.cocoaPods)
#else
private let SENTRY_PACKAGE_INFO = SentryMutex(SentryPackageManagerOption.unknown)
#endif

@objc
@_spi(Private) public final class SentrySdkPackage: NSObject {

    private static func getSentrySDKPackageName(_ packageManager: SentryPackageManagerOption) -> String? {
        switch packageManager {
        case .swiftPackageManager:
            return "spm:getsentry/\(SentryMeta.sdkName)"
        case .cocoaPods:
            return "cocoapods:getsentry/\(SentryMeta.sdkName)"
        case .unknown:
            // We don't know if the user installed Sentry with Xcode, manually or Carthage using the prebuild xcframework
            return nil
        }
    }

    private static func getSentrySDKPackage(_ packageManager: SentryPackageManagerOption) -> [String: String]? {
        if packageManager == .unknown {
            return nil
        }

        guard let name = getSentrySDKPackageName(packageManager) else {
            return nil
         }

        return ["name": name, "version": SentryMeta.versionString]
    }

    @objc
    public static func global() -> [String: String]? {
        return getSentrySDKPackage(SENTRY_PACKAGE_INFO.withLock { $0 })
    }

    #if SENTRY_TEST || SENTRY_TEST_CI
    @objc
    public static func setPackageManager(_ manager: UInt) {
        SENTRY_PACKAGE_INFO.withLock {
            $0 = SentryPackageManagerOption(rawValue: manager) ?? .unknown
        }
    }

    @objc
    public static func resetPackageManager() {
        SENTRY_PACKAGE_INFO.withLock { $0 = .unknown }
    }
    #endif
}
// swiftlint:enable missing_docs
