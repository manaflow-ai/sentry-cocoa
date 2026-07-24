#if SDK_V10
#    import <Foundation/Foundation.h>
#    if !__has_include(<SentryObjC/SentryObjCDefines.h>)
#        import "SentryObjCDefines.h"
#    else
#        import <SentryObjC/SentryObjCDefines.h>
#    endif

NS_ASSUME_NONNULL_BEGIN

/// The active Session Replay network header capture mode.
typedef NS_ENUM(NSInteger, SentryObjCReplayNetworkHeaderCaptureMode) {
    /// Inherit header and cookie collection from data collection options.
    SentryObjCReplayNetworkHeaderCaptureModeInherit = 0,
    /// Capture only explicitly listed headers.
    SentryObjCReplayNetworkHeaderCaptureModeHeaders
};

/// Controls which HTTP headers Session Replay captures.
@interface SentryObjCReplayNetworkHeaderCapture : NSObject
SENTRY_NO_INIT

/// The active capture mode.
@property (nonatomic, readonly) SentryObjCReplayNetworkHeaderCaptureMode mode;

/// Explicitly selected headers. Empty when inheriting.
@property (nonatomic, readonly, copy) NSArray<NSString *> *headers;

/// Inherit header and cookie collection from global data collection options.
+ (instancetype)inherit;

/// Capture only the listed headers while always filtering sensitive values.
+ (instancetype)headers:(NSArray<NSString *> *)headers;

@end

NS_ASSUME_NONNULL_END
#endif // SDK_V10
