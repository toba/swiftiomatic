import Foundation

extension Configuration {
    // MARK: On-Disk Cache

    /// A SHA-256 fingerprint of this configuration's root directory and rule settings.
    ///
    /// ``LinterCache`` uses this as a cache key: lint results for a file are only valid
    /// when produced under the same configuration fingerprint. Changing any rule or its
    /// settings produces a different fingerprint, invalidating stale cached violations.
    var cacheDescription: String {
        let cacheRulesDescriptions =
            rules
                .map { rule in [type(of: rule).identifier, rule.cacheDescription] }
                .sorted { $0[0] < $1[0] }
        let jsonObject: [Any] = [rootDirectory, cacheRulesDescriptions]
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject) {
            return jsonData.sha256().hexString
        }
        queuedFatalError("Could not serialize configuration for cache")
    }

    /// The directory where ``LinterCache`` stores its per-file violation caches.
    ///
    /// Resolves to `<cachePath>/SwiftLint/<version>/<buildID>/`, falling back to
    /// `~/Library/Caches/` when no custom ``cachePath`` is set. The directory is
    /// created on access if it doesn't exist.
    var cacheURL: URL {
        let baseURL: URL
        if let path = cachePath {
            baseURL = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        }

        let versionedDirectory = [
            "SwiftLint",
            LintVersion.current.value,
            ExecutableInfo.buildID,
        ].compactMap(\.self).joined(separator: "/")

        let folder = baseURL.appendingPathComponent(versionedDirectory)

        do {
            try FileManager.default.createDirectory(
                at: folder, withIntermediateDirectories: true, attributes: nil,
            )
        } catch {
            Issue.genericWarning("Cannot create cache: " + error.localizedDescription).print()
        }

        return folder
    }
}
