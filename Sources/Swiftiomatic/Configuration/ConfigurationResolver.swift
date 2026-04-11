import Foundation
import Synchronization
import Yams

/// Resolves per-directory configuration by collecting and merging `.swiftiomatic.yaml` files
/// from a file's directory up to the project root.
///
/// In a monorepo, different subdirectories can have different conventions:
///
/// ```
/// MyApp/
///   .swiftiomatic.yaml          # root config
///   Sources/
///     .swiftiomatic.yaml        # overrides for main app
///   Packages/LegacySDK/
///     .swiftiomatic.yaml        # relaxed rules for legacy code
/// ```
///
/// Merge semantics: child values override parent values. Arrays replace entirely (not append).
/// A config file with `inherit: false` stops the chain — parent configs are ignored.
public final class ConfigurationResolver: Sendable {
    /// Cached resolved configurations keyed by directory path
    private let cache = Mutex<[String: Configuration]>([:])

    /// Optional explicit config path (bypasses chain resolution)
    private let explicitConfigPath: String?

    /// Root directory beyond which we stop walking (optional; filesystem root if nil)
    private let rootDirectory: String?

    public init(configPath: String? = nil, rootDirectory: String? = nil) {
        self.explicitConfigPath = configPath
        self.rootDirectory = rootDirectory
    }

    /// Get the effective configuration for a file at the given path.
    ///
    /// Files in the same directory share the same resolved configuration.
    /// Results are cached per directory.
    public func configuration(for filePath: String) -> Configuration {
        // Explicit config path bypasses chain resolution
        if let path = explicitConfigPath {
            return (try? Configuration.loadUnified(from: path)) ?? .default
        }

        let directory = directoryPath(for: filePath)

        return cache.withLock { cache in
            if let cached = cache[directory] {
                return cached
            }
            let config = resolveConfiguration(for: directory)
            cache[directory] = config
            return config
        }
    }

    /// Resolve the effective configuration for the given directory by merging the config chain.
    private func resolveConfiguration(for directory: String) -> Configuration {
        let chain = collectConfigChain(from: directory)
        guard !chain.isEmpty else { return .default }

        // Merge from root → leaf (root first, leaf overrides)
        var merged: [String: Any] = [:]
        for configPath in chain.reversed() {
            guard let yaml = try? Configuration.loadYAML(from: configPath) else { continue }
            // Strip `inherit` key before merging — it's metadata, not config
            var cleaned = yaml
            cleaned.removeValue(forKey: "inherit")
            merged = Self.mergeYAML(base: merged, override: cleaned)
        }

        return Configuration.loadUnified(from: merged)
    }

    /// Collect `.swiftiomatic.yaml` files from leaf directory up to root.
    ///
    /// Returns paths ordered leaf → root. If a config contains `inherit: false`,
    /// the chain stops there (that file is included, but nothing above it).
    func collectConfigChain(from directory: String) -> [String] {
        let fm = FileManager.default
        var chain: [String] = []
        var url = URL(filePath: directory, directoryHint: .isDirectory)
            .standardizedFileURL

        let rootURL = rootDirectory.map {
            URL(filePath: $0, directoryHint: .isDirectory).standardizedFileURL
        }

        while true {
            let candidate = url.appending(path: Configuration.defaultFileName)
                .path(percentEncoded: false)

            if fm.fileExists(atPath: candidate) {
                chain.append(candidate)

                // Check for inherit: false
                if let yaml = try? Configuration.loadYAML(from: candidate),
                   let inherit = yaml["inherit"] as? Bool,
                   !inherit
                {
                    break
                }
            }

            // Stop at root directory if specified
            if let rootURL,
               url.path(percentEncoded: false) == rootURL.path(percentEncoded: false)
            {
                break
            }

            let parent = url.deletingLastPathComponent().standardizedFileURL
            if parent.path(percentEncoded: false) == url.path(percentEncoded: false) { break }
            url = parent
        }

        return chain
    }

    /// Deep-merge two YAML dictionaries. Override values win; arrays replace entirely.
    static func mergeYAML(
        base: [String: Any],
        override: [String: Any],
    ) -> [String: Any] {
        var result = base

        for (key, overrideValue) in override {
            if let overrideDict = overrideValue as? [String: Any],
               let baseDict = result[key] as? [String: Any]
            {
                // Recursively merge nested dictionaries
                result[key] = mergeYAML(base: baseDict, override: overrideDict)
            } else {
                // Scalars and arrays: child replaces parent entirely
                result[key] = overrideValue
            }
        }

        return result
    }

    // MARK: - Helpers

    private func directoryPath(for filePath: String) -> String {
        let url = URL(filePath: filePath)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), isDir.boolValue {
            return url.standardizedFileURL.path(percentEncoded: false)
        }
        return url.deletingLastPathComponent().standardizedFileURL.path(percentEncoded: false)
    }
}
