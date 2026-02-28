import Foundation

/// An interface for discovering files that can be linted.
protocol LintableFileDiscovering: Sendable {
    /// Returns all files that can be linted in the specified path. If the path is relative, it will be appended to the
    /// specified root path, or current working directory if no root directory is specified.
    ///
    /// - parameter path:          The path in which lintable files should be found.
    /// - parameter rootDirectory: The parent directory for the specified path. If none is provided, the current working
    ///                            directory will be used.
    /// - parameter excluder:     The excluder used to filter out files that should not be linted.
    ///
    /// - returns: Files to lint.
    func filesToLint(inPath path: String, rootDirectory: String?, excluder: Excluder) -> [String]

    /// Returns the date when the file at the specified path was last modified. Returns `nil` if the file cannot be
    /// found or its last modification date cannot be determined.
    ///
    /// - parameter path: The file whose modification date should be determined.
    ///
    /// - returns: A date, if one was determined.
    func modificationDate(forFileAtPath path: String) -> Date?
}

/// An excluder for filtering out files that should not be linted.
enum Excluder: Sendable {
    /// Full matching excluder using glob patterns via fnmatch(3).
    case matching(patterns: [String])
    /// Prefix-based excluder using path prefixes.
    case byPrefix(prefixes: [String])
    /// An excluder that does not exclude any files.
    case noExclusion

    func excludes(path: String) -> Bool {
        switch self {
            case let .matching(patterns):
                patterns.contains { fnmatch($0, path, FNM_PATHNAME) == 0 }
            case let .byPrefix(prefixes):
                prefixes.contains(where: { path.hasPrefix($0) })
            case .noExclusion:
                false
        }
    }
}
