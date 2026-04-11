import Foundation

/// An interface for discovering files that can be linted
protocol LintableFileDiscovering: Sendable {
  /// Returns all lintable files found at the specified path
  ///
  /// If the path is relative, it is appended to the root directory or the
  /// current working directory when no root is provided.
  ///
  /// - Parameters:
  ///   - path: The path in which lintable files should be found.
  ///   - rootDirectory: The parent directory for the specified path. Defaults to the current working directory.
  ///   - excluder: The ``Excluder`` used to filter out files that should not be linted.
  /// - Returns: Files to lint.
  func filesToLint(inPath path: String, rootDirectory: String?, excluder: Excluder) -> [String]

  /// Returns the last modification date of the file at the given path
  ///
  /// - Parameters:
  ///   - path: The file whose modification date should be determined.
  /// - Returns: A date, if one was determined.
  func modificationDate(forFileAtPath path: String) -> Date?
}

/// A strategy for filtering out files that should not be linted
enum Excluder: Sendable {
  /// Glob-pattern matching via `fnmatch(3)`
  case matching(patterns: [String])
  /// Prefix-based path matching
  case byPrefix(prefixes: [String])
  /// Passes all files through without exclusion
  case noExclusion

  /// Whether the given path is excluded by this strategy
  ///
  /// - Parameters:
  ///   - path: The file path to test.
  /// - Returns: `true` if the path matches an exclusion pattern.
  func excludes(path: String) -> Bool {
    switch self {
    case .matching(let patterns):
      patterns.contains { fnmatch($0, path, FNM_PATHNAME) == 0 }
    case .byPrefix(let prefixes):
      prefixes.contains(where: { path.hasPrefix($0) })
    case .noExclusion:
      false
    }
  }
}
