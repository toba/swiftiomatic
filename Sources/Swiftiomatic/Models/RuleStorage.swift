import Synchronization

/// A storage mechanism for aggregating the results of `CollectingRule`s.
final class RuleStorage: CustomStringConvertible, Sendable {
    private struct Box: @unchecked Sendable {
        var data: [ObjectIdentifier: [SwiftSource: Any]] = [:]
    }

    private let storage = Mutex(Box())

    var description: String {
        storage.withLock { $0.data.description }
    }

    /// Creates a `RuleStorage` with no initial stored data.
    init() {}

    /// Collects file info for a given rule into the storage.s
    ///
    /// - parameter info: The file information to store.
    /// - parameter file: The file for which this information pertains to.
    /// - parameter rule: The rule that generated this info.
    func collect<R: CollectingRule>(info: R.FileInfo, for file: SwiftSource, in _: R) {
        let key = ObjectIdentifier(R.self)
        storage.withLock { box in
            box.data[key, default: [:]][file] = info
        }
    }

    /// Retrieves all file information for a given rule that was collected via `collect(...)`.
    ///
    /// - parameter rule: The rule whose collected information should be retrieved.
    ///
    /// - returns: All file information for a given rule that was collected via `collect(...)`.
    func collectedInfo<R: CollectingRule>(for _: R) -> [SwiftSource: R.FileInfo]? {
        storage.withLock { box in
            box.data[ObjectIdentifier(R.self)] as? [SwiftSource: R.FileInfo]
        }
    }
}
