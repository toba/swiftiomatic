import SwiftSyntax

/// Write a string literal with many escaped quotes or backslashes as a raw string.
///
/// A raw string such as `#"{"name": "John"}"#` treats `"` and `\` as plain characters, so the text
/// reads as it prints. This helps with JSON, regular expressions and quoted names. Interpolation
/// still works in a raw string with the `\#(value)` form.
///
/// The rule counts the escaped quotes and escaped backslashes in the literal. It reports the
/// literal when the count is `minimumEscapes` or more. It stays silent when the literal also holds
/// another escape, such as `\n` or `\u{...}`, because the raw form needs `\#n` for it. It also
/// stays silent on a literal that is already a raw string. When the text holds `"#` , the message
/// suggests `##"..."##` , or more pounds when the text needs them.
///
/// Lint: A string literal with three or more escaped quotes or backslashes, and no other escape,
/// raises a warning.
final class UseRawStringForEscapes: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .literals }
    override class var guidance: GuidanceLevel { .consider }

    /// The smallest number of escaped quotes and backslashes that the rule reports.
    static let minimumEscapes = 3

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.openingPounds == nil else { return .visitChildren }
        var count = 0
        var pounds = 1

        for segment in node.segments {
            guard let text = segment.as(StringSegmentSyntax.self)?.content.text else { continue }
            guard let scan = Self.scan(text) else { return .visitChildren }
            count += scan.escapes
            pounds = max(pounds, scan.pounds)
        }
        if count >= Self.minimumEscapes { diagnose(.useRawString(pounds: pounds), on: node) }
        return .visitChildren
    }

    /// The number of `\"` and `\\` escapes in `text` and the number of `#` its raw form needs, or
    /// `nil` when `text` holds any other escape.
    ///
    /// A raw string with `n` pounds ends at a `"` that `n` pounds follow, and it starts an escape
    /// at a `\` that `n` pounds follow. The raw form therefore needs one pound more than the
    /// longest run of `#` after a quote or a backslash in the unescaped text.
    private static func scan(_ text: String) -> (escapes: Int, pounds: Int)? {
        var escapes = 0
        var pounds = 1
        // The number of `#` since the last quote or backslash, or `nil` after any other character.
        var run: Int?
        var iterator = text.unicodeScalars.makeIterator()

        while let scalar = iterator.next() {
            switch scalar {
                case "\\":
                    switch iterator.next() {
                        case "\"", "\\":
                            escapes += 1
                            run = 0
                        default: return nil
                    }
                case "\"": run = 0
                case "#":
                    if let current = run {
                        run = current + 1
                        pounds = max(pounds, current + 2)
                    }
                default: run = nil
            }
        }
        return (escapes, pounds)
    }
}

fileprivate extension Finding.Message {
    static func useRawString(pounds: Int) -> Finding.Message {
        let delimiter = String(repeating: "#", count: pounds)
        return "write this literal as a raw string such as \(delimiter)\"...\"\(delimiter) so its quotes and backslashes need no escapes"
    }
}
