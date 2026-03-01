import Foundation

extension URL {
  var filepath: String {
    withUnsafeFileSystemRepresentation { ptr in
      guard let ptr else {
        preconditionFailure("URL '\(self)' has no file system representation")
      }
      return String(cString: ptr)
    }
  }

  var filepathGuarded: String? {
    withUnsafeFileSystemRepresentation { ptr in
      guard let ptr else {
        SwiftiomaticError.genericError(
          "File with URL '\(self)' cannot be represented as a file system path; skipping it",
        ).print()
        return nil
      }
      return String(cString: ptr)
    }
  }

  var isSwiftFile: Bool {
    filepath.isFile && pathExtension == "swift"
  }

  /// Resolves a potentially relative or tilde-prefixed path against a directory.
  static func expandingPath(_ path: String, in directory: String) -> URL {
    let expanded = (path as NSString).expandingTildeInPath
    if expanded.hasPrefix("/") {
      return URL(fileURLWithPath: expanded).standardized
    }
    return URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(path)
      .standardized
  }
}

/// Legacy free-function wrapper — prefer `URL.expandingPath(_:in:)`.
func expandPath(_ path: String, in directory: String) -> URL {
  URL.expandingPath(path, in: directory)
}
