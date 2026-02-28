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
    guard let root = absolutePath.filepathGuarded,
      let enumerator = enumerator(atPath: root)
    else {
      return []
    }

    var files = [String]()
    var directoriesToWalk = [String]()

    while let element = enumerator.nextObject() as? String {
      let absoluteElementPath = URL(fileURLWithPath: element, relativeTo: absolutePath)
      guard
        let absoluteStandardizedElementPath = absoluteElementPath.standardized
          .filepathGuarded
      else {
        continue
      }
      if absoluteElementPath.path.isFile {
        if absoluteElementPath.pathExtension == "swift",
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
