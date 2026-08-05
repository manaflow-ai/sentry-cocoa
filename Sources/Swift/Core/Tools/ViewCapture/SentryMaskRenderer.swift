#if canImport(UIKit) && !SENTRY_NO_UI_FRAMEWORK
#if os(iOS) || os(tvOS)

import UIKit

protocol SentryMaskRenderer: Sendable {
    func maskScreenshot(screenshot image: UIImage, size: CGSize, masking: [SentryRedactRegion]) -> UIImage
}

protocol SentryMaskRendererContext {
    var cgContext: CGContext { get }
    var currentImage: UIImage { get }
}

#endif // os(iOS) || os(tvOS)
#endif // canImport(UIKit) && !SENTRY_NO_UI_FRAMEWORK
