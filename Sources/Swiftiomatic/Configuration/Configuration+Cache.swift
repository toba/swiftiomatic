import Foundation

extension Configuration {
    // MARK: On-Disk Cache

    /// A SHA-256 fingerprint of this configuration's root directory and rule settings
    ///
    /// ``LinterCache`` uses this as a cache key: lint results for a file are only valid
    /// when produced under the same configuration fingerprint. Changing any rule or its
    /// settings produces a different fingerprint, invalidating stale cached violations.
    var cacheDescription: String {
        var data = Data(rootDirectory.utf8)
        for rule in rules.sorted(by: { type(of: $0).identifier < type(of: $1).identifier }) {
            data.append(contentsOf: type(of: rule).identifier.utf8)
            data.append(0) // separator
            data.append(contentsOf: rule.cacheDescription.utf8)
            data.append(0)
        }
        return data.sha256().hexString
    }

    /// The directory where ``LinterCache`` stores its per-file violation caches
    ///
    /// Resolves to `<cachePath>/Swiftiomatic/<version>/<buildID>/`, falling back to
    /// `~/Library/Caches/` when no custom ``cachePath`` is set.
    var cacheURL: URL {
        let baseURL: URL
        if let path = cachePath {
            baseURL = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        }

        let versionedDirectory = [
            "Swiftiomatic",
            SwiftiomaticVersion.current.value,
            ExecutableInfo.buildID,
        ].compactMap(\.self).joined(separator: "/")

        return baseURL.appendingPathComponent(versionedDirectory)
    }

    /// Create the cache directory at ``cacheURL`` if it doesn't already exist
    func prepareCacheDirectory() {
        do {
            try FileManager.default.createDirectory(
                at: cacheURL, withIntermediateDirectories: true, attributes: nil,
            )
        } catch {
            SwiftiomaticError.genericWarning("Cannot create cache: " + error.localizedDescription).print()
        }
    }
}
