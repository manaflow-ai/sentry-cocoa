// swiftlint:disable missing_docs
#if canImport(UIKit) && !SENTRY_NO_UI_FRAMEWORK
#if os(iOS) || os(tvOS)
import Foundation
public import UIKit

@_spi(Private) public typealias ScreenshotCallback = @MainActor @Sendable (_ maskedViewImage: UIImage) -> Void

@objc
@_spi(Private) public protocol SentryViewScreenshotProvider: NSObjectProtocol {
    @MainActor func image(view: UIView, onComplete: @escaping ScreenshotCallback)
}
#endif
#endif
// swiftlint:enable missing_docs
