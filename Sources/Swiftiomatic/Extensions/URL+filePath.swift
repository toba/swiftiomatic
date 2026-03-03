import Foundation

extension URL {
    /// The POSIX file system path for this URL, trapping if the URL has no file representation
    var filepath: String {
        withUnsafeFileSystemRepresentation { ptr in
            guard let ptr else {
                preconditionFailure("URL '\(self)' has no file system representation")
            }
            return String(cString: ptr)
        }
    }

    /// The POSIX file system path for this URL, or `nil` if the URL cannot be represented as a path
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

    /// Whether this URL points to an existing file with a `.swift` extension
    var isSwiftFile: Bool {
        filepath.isFile && pathExtension == "swift"
    }

    /// Resolves a potentially relative or tilde-prefixed path against a directory
    ///
    /// - Parameters:
    ///   - path: A file path that may be relative or start with `~`.
    ///   - directory: The base directory to resolve relative paths against.
    static func expandingPath(_ path: String, in directory: String) -> URL {
        let expanded = (path as NSString).expandingTildeInPath
        if expanded.hasPrefix("/") {
            return URL(fileURLWithPath: expanded).standardized
        }
        return URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(path)
            .standardized
    }
}

/// Legacy free-function wrapper -- prefer ``URL/expandingPath(_:in:)``
///
/// - Parameters:
///   - path: A file path that may be relative or start with `~`.
///   - directory: The base directory to resolve relative paths against.
func expandPath(_ path: String, in directory: String) -> URL {
    URL.expandingPath(path, in: directory)
}
