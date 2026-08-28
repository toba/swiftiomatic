/// Glob patterns matching paths that should be skipped during recursive directory walks.
///
/// Patterns are matched against paths relative to the directory being walked (or relative to the
/// iterator's working directory when an absolute path is iterated). A directory matched by any
/// pattern is pruned — its contents are not visited. A file matched by any pattern is skipped.
///
/// Supported syntax:
/// - `*` — matches any run of characters except `/`
/// - `?` — matches any single character except `/`
/// - `[abc]` / `[a-z]` — character class
/// - `**` — matches any number of path components (including zero), only when used as a whole path
///   component
///
/// Examples: `.build/**`, `**/Generated/**`, `vendor/**`, `**/*.generated.swift`.
package struct Excludes: LayoutRule {
    package static let description =
        "Glob patterns matching paths to skip during recursive walks. Supports `*`, `?`, `[…]`, and `**` (across path separators)."
    package static let defaultValue: [String] = []
}
