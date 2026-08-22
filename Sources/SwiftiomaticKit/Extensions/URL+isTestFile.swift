import Foundation

package extension URL {
    /// Reports whether this file sits in a test target.
    ///
    /// The check is by path shape, because a rule sees one file at a time and never the package
    /// manifest. A file qualifies when a path component is `Tests` or the file name ends with
    /// `Tests.swift` . Test code keeps mutable counters and re-arms observation by design, so a
    /// rule that guards a production invariant skips these files.
    var isTestFile: Bool {
        if path.contains("/Tests/") { return true }
        return lastPathComponent.hasSuffix("Tests.swift")
    }
}
