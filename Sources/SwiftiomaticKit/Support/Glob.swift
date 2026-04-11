import Foundation

// Adapted from https://gist.github.com/efirestone/ce01ae109e08772647eb061b3bb387c3

/// POSIX `glob(3)` wrapper with support for `**` (globstar) expansion
enum Glob {
  /// Resolves a glob pattern into a sorted list of unique, absolute file paths
  ///
  /// Supports `*`, `?`, `[]`, and `**` (recursive directory matching).
  ///
  /// - Parameters:
  ///   - pattern: A file-system glob pattern.
  /// - Returns: Matching file paths, deduplicated and sorted.
  static func resolveGlob(_ pattern: String) -> [String] {
    let globCharset = CharacterSet(charactersIn: "*?[]")
    guard pattern.rangeOfCharacter(from: globCharset) != nil else {
      return [pattern]
    }

    return expandGlobstar(pattern: pattern)
      .reduce(into: [String]()) { paths, pattern in
        var globResult = glob_t()
        defer { globfree(&globResult) }

        let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
        if glob(pattern, flags, nil, &globResult) == 0 {
          paths.append(contentsOf: populateFiles(globResult: globResult))
        }
      }
      .unique
      .sorted()
      .map { $0.absolutePathStandardized() }
  }

  /// Creates absolute glob patterns from a root directory and a relative pattern
  ///
  /// Appends `/**` when the pattern targets a directory so that all contained
  /// Swift files are matched.
  ///
  /// - Parameters:
  ///   - root: The root directory to anchor the pattern against.
  ///   - pattern: A relative or absolute glob pattern.
  /// - Returns: One or two absolute glob patterns covering the intended scope.
  static func createGlobPatterns(root: String, pattern: String) -> [String] {
    var absolutPathPattern = pattern
    if !pattern.starts(with: root) {
      // If the root is not already part of the pattern, prepend it.
      absolutPathPattern = root + (root.hasSuffix("/") ? "" : "/") + absolutPathPattern
    }
    absolutPathPattern = absolutPathPattern.absolutePathStandardized()
    if pattern.hasSuffix(".swift") || pattern.hasSuffix("/**") {
      // Suffix is already well defined.
      return [absolutPathPattern]
    }
    if pattern.hasSuffix("/") {
      // Matching all files in the folder.
      return [absolutPathPattern + "**"]
    }
    // The pattern could match files in the last folder in the path or all contained files if the last component
    // represents folders.
    return [
      absolutPathPattern,
      absolutPathPattern + "/**",
    ]
  }

  // MARK: Private

  private static func expandGlobstar(pattern: String) -> [String] {
    guard pattern.contains("**") else {
      return [pattern]
    }
    var parts = pattern.components(separatedBy: "**")
    let firstPart = parts.removeFirst()
    let fileManager = FileManager.default
    guard firstPart.isEmpty || fileManager.fileExists(atPath: firstPart) else {
      return []
    }
    let searchPath = firstPart.isEmpty ? fileManager.currentDirectoryPath : firstPart
    var directories = [String]()
    do {
      directories = try fileManager.subpathsOfDirectory(atPath: searchPath)
        .compactMap { subpath in
          let fullPath = (firstPart as NSString).appendingPathComponent(subpath)
          guard isDirectory(path: fullPath) else { return nil }
          return fullPath
        }
    } catch {
      SwiftiomaticError.genericWarning("Error parsing file system item: \(error)").print()
    }

    // Check the base directory for the glob star as well.
    directories.insert(firstPart, at: 0)

    var lastPart = parts.joined(separator: "**")
    var results = [String]()

    // Include the globstar root directory ("dir/") in a pattern like "dir/**" or "dir/**/"
    if lastPart.isEmpty {
      results.append(firstPart)
      lastPart = "*"
    }

    for directory in directories {
      let partiallyResolvedPattern: String
      if directory.isEmpty {
        partiallyResolvedPattern =
          lastPart.starts(with: "/") ? String(lastPart.dropFirst()) : lastPart
      } else {
        partiallyResolvedPattern = (directory as NSString).appendingPathComponent(lastPart)
      }
      results.append(contentsOf: expandGlobstar(pattern: partiallyResolvedPattern))
    }

    return results
  }

  private static func isDirectory(path: String) -> Bool {
    var isDirectoryBool = ObjCBool(false)
    let isDirectory = FileManager.default.fileExists(
      atPath: path,
      isDirectory: &isDirectoryBool,
    )
    return isDirectory && isDirectoryBool.boolValue
  }

  private static func populateFiles(globResult: glob_t) -> [String] {
    let matchCount = globResult.gl_matchc
    return (0..<Int(matchCount)).compactMap { index in
      globResult.gl_pathv[index].flatMap { String(validatingCString: $0) }
    }
  }
}
