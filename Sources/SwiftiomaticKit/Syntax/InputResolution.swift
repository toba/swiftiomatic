import Foundation

/// Resolved input source for a `lint` or `format` invocation.
public enum ResolvedInput: Equatable, Sendable {
    case stdin
    case urls([URL])
}

/// Resolves the raw `paths` argument list (from `LintFormatOptions.paths`) into a concrete input
/// source.
///
/// Behavior:
/// - `["-"]` → standard input (explicit).
/// - non-empty path list → treat as file/directory URLs; directories are auto-recursed by
///   `FileIterator` downstream, so callers don't need to set `--recursive`.
/// - empty path list → recurse from the current working directory when stdin is a TTY (the
///   ergonomic default for interactive use, matching `ruff` / `eslint`); otherwise read stdin so
///   pipelines like `cat MyFile.swift | sm lint` keep working.
public func resolveInputs(rawPaths: [String], stdinIsTTY: Bool) -> ResolvedInput {
    if rawPaths == ["-"] { return .stdin }
    if rawPaths.isEmpty {
        return stdinIsTTY ? .urls([URL(fileURLWithPath: ".")]) : .stdin
    }
    return .urls(rawPaths.map(URL.init(fileURLWithPath:)))
}
