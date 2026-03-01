import Foundation

extension URL {
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
