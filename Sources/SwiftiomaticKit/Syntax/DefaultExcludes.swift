/// Glob patterns for directories that should never be descended into during a recursive lint or
/// format walk: VCS metadata, package manager caches, IDE state, and language ecosystem build
/// artifacts. Each pattern uses the `**/` prefix so it matches the directory at any depth, and
/// `Glob` already handles the zero-component case so top-level `.build` is matched too.
public let defaultRecursionExcludes: [String] = [
    "**/.build",
    "**/.swiftpm",
    "**/.git",
    "**/.hg",
    "**/.svn",
    "**/.idea",
    "**/.vscode",
    "**/.bundle",
    "**/.tuist",
    "**/DerivedData",
    "**/build",
    "**/Build",
    "**/Pods",
    "**/Carthage",
    "**/node_modules",
]
