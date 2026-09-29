package import Foundation
import Synchronization

/// Finds the configuration file that applies to a path, and caches the result for each directory.
///
/// The result is the same as the result of
/// ``Configuration/url(forConfigurationFileApplyingTo:)`` . That walk checks each directory up to
/// the root for each file. This type records the result for each directory that a walk visits.
/// Sibling files and nested directories then stop at the first directory that has a cached result.
///
/// The cache does not see files that change during its life. Make one instance for each run.
package final class ConfigurationDiscovery: Sendable {
    /// For each standardized directory path, the configuration file that applies, or `nil` when
    /// no configuration file applies.
    private let directories = Mutex<[String: URL?]>([:])

    package init() {}

    /// Returns the URL of the configuration file that applies to the given file or directory, or
    /// `nil` when the walk up to the root finds no configuration file.
    package func configurationFileURL(applyingTo url: URL) -> URL? {
        var directory = url.absoluteURL.standardized
        if !FileManager.default.directoryExists(atPath: directory.path) {
            directory.deleteLastPathComponent()
        }

        var visited: [String] = []
        var result: URL?

        while true {
            let key = directory.path

            if let cached = directories.withLock({ $0[key] }) {
                result = cached
                break
            }
            visited.append(key)

            let candidate = directory.appendingPathComponent("swiftiomatic.json")

            if FileManager.default.isReadableFile(atPath: candidate.path) {
                result = candidate
                break
            }
            if directory.isRoot { break }
            directory.deleteLastPathComponent()
        }

        // The file system calls run outside the lock. Two workers can walk the same directories
        // at the same time. They find the same result, so the second write is harmless.
        if !visited.isEmpty {
            directories.withLock { cache in
                for key in visited { cache[key] = .some(result) }
            }
        }
        return result
    }
}
