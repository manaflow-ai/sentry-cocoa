#if SDK_V10
// swiftlint:disable missing_docs
#if SWIFT_PACKAGE
internal import SentrySwift
#else
internal import Sentry
#endif
import Foundation

@objc public enum SentryObjCReplayNetworkHeaderCaptureMode: Int {
    case inherit
    case headers
}

@objc(SentryObjCReplayNetworkHeaderCapture)
public final class SentryObjCReplayNetworkHeaderCapture: NSObject {
    private let box: Box<SentryReplayOptions.NetworkHeaderCapture>

    internal var wrapped: SentryReplayOptions.NetworkHeaderCapture {
        box.value
    }

    internal init(_ wrapped: SentryReplayOptions.NetworkHeaderCapture) {
        self.box = Box(wrapped)
    }

    @objc public var mode: SentryObjCReplayNetworkHeaderCaptureMode {
        switch box.value {
        case .inherit: return .inherit
        case .headers: return .headers
        @unknown default: return .inherit
        }
    }

    @objc public var headers: [String] {
        switch box.value {
        case .inherit: return []
        case .headers(let headers): return headers
        @unknown default: return []
        }
    }

    @objc public static func inherit() -> SentryObjCReplayNetworkHeaderCapture {
        SentryObjCReplayNetworkHeaderCapture(.inherit)
    }

    @objc public static func headers(_ headers: [String]) -> SentryObjCReplayNetworkHeaderCapture {
        SentryObjCReplayNetworkHeaderCapture(.headers(headers))
    }
}

// swiftlint:enable missing_docs
#endif // SDK_V10
