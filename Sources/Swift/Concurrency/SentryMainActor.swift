import Foundation

/// Executes synchronous SDK queries against main-actor Apple APIs without
/// weakening actor checking at each call site.
enum SentryMainActor {
    private struct Transfer<Value>: @unchecked Sendable {
        let value: Value
    }

    static func runSync<Result: Sendable>(
        using queueWrapper: SentryDispatchQueueWrapper = Dependencies.dispatchQueueWrapper,
        _ operation: @escaping @MainActor @Sendable () -> Result
    ) -> Result {
        if Thread.isMainThread {
            return MainActor.assumeIsolated(operation)
        }

        let result = SentryMutex<Result?>(nil)
        queueWrapper.dispatchSyncOnMainQueue {
            result.withLock { value in
                value = MainActor.assumeIsolated(operation)
            }
        }
        return result.withLock { $0! }
    }

    /// Compatibility bridge for synchronous Objective-C APIs that return
    /// UIKit references. Callers retain their existing obligation to use the
    /// returned reference only from the main thread.
    static func runSyncUnchecked<Result>(
        using queueWrapper: SentryDispatchQueueWrapper = Dependencies.dispatchQueueWrapper,
        _ operation: @escaping @MainActor () -> Result
    ) -> Result {
        let transferredOperation = Transfer(value: operation)
        return runSync(using: queueWrapper) {
            Transfer(value: transferredOperation.value())
        }.value
    }
}
