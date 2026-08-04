// swiftlint:disable missing_docs
#if canImport(UIKit) && !SENTRY_NO_UIKIT
#if os(iOS) || os(tvOS)
import Foundation
import ObjectiveC.NSObjCRuntime
import UIKit
#if os(iOS)
import WebKit
#endif

@objcMembers
public final class SentryRedactViewHelper: NSObject {
    private static var associatedRedactObjectHandle: UInt8 = 0
    private static var associatedIgnoreObjectHandle: UInt8 = 0
    private static var associatedClipOutObjectHandle: UInt8 = 0
    private static var associatedPriorityRedactObjectHandle: UInt8 = 0
    
    override private init() {}
    
    @_spi(Private) public static func maskView(_ view: UIView) {
        objc_setAssociatedObject(view, &associatedRedactObjectHandle, true, .OBJC_ASSOCIATION_ASSIGN)
    }
    
    static func shouldMaskView(_ view: UIView) -> Bool {
        (objc_getAssociatedObject(view, &associatedRedactObjectHandle) as? NSNumber)?.boolValue ?? false
    }
    
    static func shouldUnmask(_ view: UIView) -> Bool {
        (objc_getAssociatedObject(view, &associatedIgnoreObjectHandle) as? NSNumber)?.boolValue ?? false
    }
    
    @_spi(Private) public static func unmaskView(_ view: UIView) {
        objc_setAssociatedObject(view, &associatedIgnoreObjectHandle, true, .OBJC_ASSOCIATION_ASSIGN)
    }
    
    static func shouldClipOut(_ view: UIView) -> Bool {
        (objc_getAssociatedObject(view, &associatedClipOutObjectHandle) as? NSNumber)?.boolValue ?? false
    }
    
    static public func clipOutView(_ view: UIView) {
        objc_setAssociatedObject(view, &associatedClipOutObjectHandle, true, .OBJC_ASSOCIATION_ASSIGN)
    }
    
    static func shouldPriorityRedact(_ view: UIView) -> Bool {
        (objc_getAssociatedObject(view, &associatedPriorityRedactObjectHandle) as? NSNumber)?.boolValue ?? false
    }
    
    static public func priorityMaskView(_ view: UIView) {
        objc_setAssociatedObject(view, &associatedPriorityRedactObjectHandle, true, .OBJC_ASSOCIATION_ASSIGN)
    }
}

#endif
#endif
// swiftlint:enable missing_docs
