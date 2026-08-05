// swiftlint:disable missing_docs
internal import _SentryPrivate
import Foundation

@objcMembers
@_spi(Private) public class SentryWatchdogTerminationAttributesProcessor: NSObject {

    private let dispatchQueueWrapper: SentryDispatchQueueWrapper
    private let scopePersistentStore: SentryMutex<SentryScopePersistentStore?>

    init(
        withDispatchQueueWrapper dispatchQueueWrapper: SentryDispatchQueueWrapper,
        scopePersistentStore: SentryScopePersistentStore?
    ) {
        self.dispatchQueueWrapper = dispatchQueueWrapper
        self.scopePersistentStore = SentryMutex(scopePersistentStore)

        super.init()

        clear()
    }
    
    public func clear() {
        SentrySDKLog.debug("Deleting all stored data in in persistent store")
        scopePersistentStore.withLock { $0?.deleteAllCurrentState() }
    }

    public func setContext(_ context: [String: [String: Any]]?) {
        setData(data: context, field: .context) { store, data in
            store.encode(context: data)
        }
    }
    
    public func setUser(_ user: User?) {
        setData(data: user, field: .user) { store, data in
            store.encode(user: data)
        }
    }
    
    public func setDist(_ dist: String?) {
        setData(data: dist, field: .dist) { store, data in
            store.encode(string: data)
        }
    }
    
    public func setEnvironment(_ environment: String?) {
        setData(data: environment, field: .environment) { store, data in
            store.encode(string: data)
        }
    }
    
    public func setTags(_ tags: [String: String]?) {
        setData(data: tags, field: .tags) { store, data in
            store.encode(tags: data)
        }
    }
    
    public func setExtras(_ extras: [String: Any]?) {
        setData(data: extras, field: .extras) { store, data in
            store.encode(extras: data)
        }
    }
    
    public func setFingerprint(_ fingerprint: [String]?) {
        setData(data: fingerprint, field: .fingerprint) { store, data in
            store.encode(fingerprint: data)
        }
    }
    
    // MARK: - Private
    private enum WriteAction: Sendable {
        case delete
        case write(Data)
        case skip
    }

    private func setData<T>(
        data: T?,
        field: SentryScopeField,
        encode: (SentryScopePersistentStore, T) -> Data?
    ) {
        SentrySDKLog.debug("Setting \(field.name) in background queue: \(String(describing: data))")
        let action = scopePersistentStore.withLock { store -> WriteAction in
            guard let store else { return .skip }
            guard let data else { return .delete }
            guard let encoded = encode(store, data) else { return .skip }
            return .write(encoded)
        }

        let persistentStore = scopePersistentStore
        dispatchQueueWrapper.dispatchAsync {
            persistentStore.withLock { store in
                guard let store else {
                    SentrySDKLog.debug("Can not set \(field.name), reason: persistent store is nil")
                    return
                }
                switch action {
                case .delete:
                    SentrySDKLog.debug("Data for \(field.name) is nil, deleting active file.")
                    store.deleteCurrentFieldOnDisk(field: field)
                case .write(let data):
                    store.writeEncodedDataToDisk(field: field, data: data)
                case .skip:
                    break
                }
            }
        }
    }
}
// swiftlint:enable missing_docs
