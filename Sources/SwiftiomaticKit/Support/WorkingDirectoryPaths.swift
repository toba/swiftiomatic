import Foundation

/// Makes a file path relative to the working directory when the file is inside it.
struct WorkingDirectoryPaths: Sendable {
    /// The working directory path with a trailing slash. A file path with this prefix is relative.
    let rootPath: String

    /// The `file://` URI of the working directory, with a trailing slash.
    let rootURI: String

    init(_ workingDirectory: URL) {
        let directory = workingDirectory.standardizedFileURL
        let uri = directory.absoluteString

        rootPath = directory.path.hasSuffix("/") ? directory.path : directory.path + "/"
        rootURI = uri.hasSuffix("/") ? uri : uri + "/"
    }

    /// Returns the standardized absolute form of the path.
    func standardized(_ file: String) -> String { URL(fileURLWithPath: file).standardizedFileURL.path }

    /// Returns the path relative to the working directory, or `nil` when the file is outside it.
    func relativePath(of file: String) -> String? {
        let path = standardized(file)
        return path.hasPrefix(rootPath) ? String(path.dropFirst(rootPath.count)) : nil
    }

    /// Returns the relative path when the file is inside the working directory, and the absolute
    /// path otherwise.
    func displayPath(of file: String) -> String { relativePath(of: file) ?? standardized(file) }
}
