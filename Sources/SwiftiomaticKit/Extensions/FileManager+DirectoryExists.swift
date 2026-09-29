package import Foundation

extension FileManager {
    /// Whether a directory, or a symbolic link to a directory, exists at `path`
    ///
    /// `fileExists(atPath:isDirectory:)` takes its result through an `ObjCBool` pointer, which is
    /// an unsafe construct. This is the one call site for it. `URL.resourceValues(forKeys:)` is
    /// safe, but it does not follow a symbolic link, so it gives a different answer for a link to
    /// a directory.
    package func directoryExists(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return unsafe fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
