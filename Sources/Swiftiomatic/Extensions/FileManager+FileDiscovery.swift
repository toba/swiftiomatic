import Foundation

extension FileManager: LintableFileDiscovering, @unchecked @retroactive Sendable {
  func filesToLint(
    inPath path: String,
    rootDirectory: String? = nil,
    excluder: Excluder,
  ) -> [String] {
    let absolutePath = URL(
      fileURLWithPath: path.absolutePathRepresentation(
        rootDirectory: rootDirectory ?? currentDirectoryPath,
      ),
    )

    // If path is a file, filter and return it directly.
    if absolutePath.isSwiftFile {
      let filePath = absolutePath.standardized.filepath
      return excluder.excludes(path: filePath) ? [] : [filePath]
    }

    // Fast path when there are no exclusions.
    if case .noExclusion = excluder {
      return subpaths(atPath: absolutePath.filepath)?.parallelCompactMap { element in
        let absoluteElementPath = URL(fileURLWithPath: element, relativeTo: absolutePath)
        return absoluteElementPath.isSwiftFile
          ? absoluteElementPath.standardized
            .filepath : nil
      } ?? []
    }

    return collectFiles(atPath: absolutePath, excluder: excluder)
  }

  private func collectFiles(atPath absolutePath: URL, excluder: Excluder) -> [String] {
    guard let enumerator = enumerator(
      at: absolutePath,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: []
    ) else {
      return []
    }

    var files = [String]()
    var directoriesToWalk = [String]()

    for case let elementURL as URL in enumerator {
      guard
        let absoluteStandardizedElementPath = elementURL.standardized
          .filepathGuarded
      else {
        continue
      }
      if elementURL.path.isFile {
        if elementURL.pathExtension == "swift",
          !excluder.excludes(path: absoluteStandardizedElementPath)
        {
          files.append(absoluteStandardizedElementPath)
        }
      } else {
        enumerator.skipDescendants()
        if !excluder.excludes(path: absoluteStandardizedElementPath) {
          directoriesToWalk.append(absoluteStandardizedElementPath)
        }
      }
    }

    return files
      + directoriesToWalk.parallelFlatMap {
        collectFiles(
          atPath: URL(fileURLWithPath: $0, isDirectory: true),
          excluder: excluder,
        )
      }
  }

  func modificationDate(forFileAtPath path: String) -> Date? {
    (try? attributesOfItem(atPath: path))?[.modificationDate] as? Date
  }
}
