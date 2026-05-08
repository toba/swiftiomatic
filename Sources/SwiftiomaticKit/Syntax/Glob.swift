import Foundation

/// Shell-style glob matcher used by the `excludes` configuration to skip paths during recursive
/// directory walks.
///
/// Patterns are translated once to an `NSRegularExpression` (anchored, full-path match):
/// - `*` — any run of non-`/` characters
/// - `?` — any single non-`/` character
/// - `[abc]` / `[a-z]` / `[!abc]` — character class (passed through with `!` rewritten as `^`)
/// - `**` — any number of path components (zero or more), only when used as a whole component
package struct Glob: Sendable {
    private let regex: NSRegularExpression

    package init?(pattern: String) {
        let regexSource = "^" + Glob.translate(normalize(pattern)) + "$"
        guard let r = try? NSRegularExpression(pattern: regexSource) else { return nil }
        self.regex = r
    }

    package func matches(_ path: String) -> Bool {
        let s = normalize(path)
        let range = NSRange(s.startIndex..<s.endIndex, in: s)
        return regex.firstMatch(in: s, range: range) != nil
    }

    /// Returns `true` if `path` matches any of the patterns. Invalid patterns are skipped.
    package static func matchesAny(_ patterns: [String], path: String) -> Bool {
        for pattern in patterns {
            if let glob = Glob(pattern: pattern), glob.matches(path) { return true }
        }
        return false
    }

    /// Translates a glob pattern to a regex body (no anchors).
    static func translate(_ pattern: String) -> String {
        var out = ""
        let chars = Array(pattern)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            switch c {
                case "*":
                    if i + 1 < chars.count, chars[i + 1] == "*" {
                        // `**` — match any number of path components (including zero).
                        // Greedy `.*` is fine since we anchor with `$`.
                        // If followed by `/`, swallow it so `**/foo` matches `foo` too.
                        if i + 2 < chars.count, chars[i + 2] == "/" {
                            out += "(?:.*/)?"
                            i += 3
                        } else {
                            out += ".*"
                            i += 2
                        }
                    } else {
                        out += "[^/]*"
                        i += 1
                    }
                case "?":
                    out += "[^/]"
                    i += 1
                case "[":
                    // Pass through to regex char class, rewriting leading `!` as `^`.
                    var j = i + 1
                    var body = ""
                    if j < chars.count, chars[j] == "!" {
                        body += "^"
                        j += 1
                    }
                    while j < chars.count, chars[j] != "]" {
                        body.append(chars[j])
                        j += 1
                    }
                    if j < chars.count {
                        out += "[" + body + "]"
                        i = j + 1
                    } else {
                        // Unterminated — escape literally.
                        out += NSRegularExpression.escapedPattern(for: "[")
                        i += 1
                    }
                default:
                    out += NSRegularExpression.escapedPattern(for: String(c))
                    i += 1
            }
        }
        return out
    }
}

private func normalize(_ s: String) -> String {
    var s = s
    while s.hasPrefix("./") { s.removeFirst(2) }
    while s.hasSuffix("/") { s.removeLast() }
    return s
}
