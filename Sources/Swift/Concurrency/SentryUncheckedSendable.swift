/// Explicit transfer wrapper for immutable references whose framework types
/// have not adopted `Sendable`, but whose documented use is queue-confined.
struct SentryUncheckedSendable<Value>: @unchecked Sendable {
    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}
