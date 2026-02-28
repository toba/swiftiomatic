import Foundation

extension Configuration {
    // MARK: Caching Configurations By Identifier (In-Memory)

    private nonisolated(unsafe) static var cachedConfigurationsByIdentifier = [
        String: Configuration
    ]()
    private static let cachedConfigurationsByIdentifierLock = NSLock()

    /// Since the cache is stored in a static var, this function is used to reset the cache during tests
    static func resetCache() {
        cachedConfigurationsByIdentifierLock.lock()
        cachedConfigurationsByIdentifier = [:]
        cachedConfigurationsByIdentifierLock.unlock()
    }

    func setCached(forIdentifier identifier: String) {
        Self.cachedConfigurationsByIdentifierLock.lock()
        Self.cachedConfigurationsByIdentifier[identifier] = self
        Self.cachedConfigurationsByIdentifierLock.unlock()
    }

    static func getCached(forIdentifier identifier: String) -> Configuration? {
        cachedConfigurationsByIdentifierLock.lock()
        defer { cachedConfigurationsByIdentifierLock.unlock() }
        return cachedConfigurationsByIdentifier[identifier]
    }

    /// Returns a copy of the current `Configuration` with its `computedCacheDescription` property set to the value of
    /// `cacheDescription`, which is expensive to compute.
    ///
    /// - returns: A new `Configuration` value.
    func withPrecomputedCacheDescription() -> Configuration {
        var result = self
        result.computedCacheDescription = result.cacheDescription
        return result
    }

    // MARK: Nested Config Is Self Cache

    private nonisolated(unsafe) static var nestedConfigIsSelfByIdentifier = [String: Bool]()
    private static let nestedConfigIsSelfByIdentifierLock = NSLock()

    static func setIsNestedConfigurationSelf(forIdentifier identifier: String, value: Bool) {
        nestedConfigIsSelfByIdentifierLock.lock()
        nestedConfigIsSelfByIdentifier[identifier] = value
        nestedConfigIsSelfByIdentifierLock.unlock()
    }

    static func getIsNestedConfigurationSelf(forIdentifier identifier: String) -> Bool {
        nestedConfigIsSelfByIdentifierLock.lock()
        defer { Self.nestedConfigIsSelfByIdentifierLock.unlock() }
        return nestedConfigIsSelfByIdentifier[identifier] ?? false
    }

    // MARK: SwiftLint Cache (On-Disk)

    var cacheDescription: String {
        if let computedCacheDescription {
            return computedCacheDescription
        }

        let cacheRulesDescriptions =
            rules
                .map { rule in [type(of: rule).identifier, rule.cacheDescription] }
                .sorted { $0[0] < $1[0] }
        let jsonObject: [Any] = [rootDirectory, cacheRulesDescriptions]
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject) {
            return jsonData.sha256().toHexString()
        }
        queuedFatalError("Could not serialize configuration for cache")
    }

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
                at: folder, withIntermediateDirectories: true, attributes: nil
            )
        } catch {
            Issue.genericWarning("Cannot create cache: " + error.localizedDescription).print()
        }

        return folder
    }
}
