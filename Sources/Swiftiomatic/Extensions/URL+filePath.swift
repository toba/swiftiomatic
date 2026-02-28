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
        Issue.genericError(
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
}
