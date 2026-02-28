import Foundation

/// Discovers Swift source files, excluding build artifacts and vendored code.
enum FileDiscovery {
    /// Default directory names to exclude.
    static let excludedDirectories: Set<String> = [
        ".build", ".git", "Pods", "DerivedData", "Carthage",
        "GRDB", ".swiftpm",
    ]

    /// Default file suffixes to exclude.
    static let excludedSuffixes = [".generated.swift", ".pb.swift"]

    /// Find all `.swift` files under the given paths, applying exclusions.
    static func findSwiftFiles(
        in paths: [String],
        additionalExclusions: [String] = [],
    ) -> [String] {
        let fm = FileManager.default
        var results: [String] = []
        let extraExclusions = Set(additionalExclusions)

        for path in paths {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: path, isDirectory: &isDir) else { continue }

            if isDir.boolValue {
                collectSwiftFiles(
                    in: path,
                    fileManager: fm,
                    extraExclusions: extraExclusions,
                    into: &results,
                )
            } else if path.hasSuffix(".swift"), !isExcludedFile(path) {
                results.append(path)
            }
        }

        return results.sorted()
    }

    private static func collectSwiftFiles(
        in directory: String,
        fileManager fm: FileManager,
        extraExclusions: Set<String>,
        into results: inout [String],
    ) {
        let directoryURL = URL(filePath: directory, directoryHint: .isDirectory)
        guard let enumerator = fm.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else { return }

        for case let fileURL as URL in enumerator {
            let lastComponent = fileURL.lastPathComponent

            if excludedDirectories.contains(lastComponent)
                || extraExclusions.contains(lastComponent)
            {
                enumerator.skipDescendants()
                continue
            }

            guard fileURL.pathExtension == "swift" else { continue }
            let path = fileURL.path(percentEncoded: false)
            guard !isExcludedFile(path) else { continue }
            results.append(path)
        }
    }

    private static func isExcludedFile(_ path: String) -> Bool {
        excludedSuffixes.contains { path.hasSuffix($0) }
    }
}
