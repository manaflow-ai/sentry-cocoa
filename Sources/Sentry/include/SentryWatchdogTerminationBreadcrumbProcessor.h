#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SentryFileManager;
@class SentryDispatchQueueWrapper;

@interface SentryWatchdogTerminationBreadcrumbProcessor : NSObject

- (instancetype)initWithMaxBreadcrumbs:(NSInteger)maxBreadcrumbs;

- (instancetype)initWithMaxBreadcrumbs:(NSInteger)maxBreadcrumbs
                           fileManager:(SentryFileManager *_Nullable)fileManager;

- (instancetype)initWithMaxBreadcrumbs:(NSInteger)maxBreadcrumbs
                           fileManager:(SentryFileManager *_Nullable)fileManager
                  dispatchQueueWrapper:(SentryDispatchQueueWrapper *)dispatchQueueWrapper;

- (void)addSerializedBreadcrumb:(NSDictionary *)crumb;

- (void)clearBreadcrumbs;

- (void)clear;

@end

NS_ASSUME_NONNULL_END
