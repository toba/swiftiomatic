import SwiftSyntax

/// The width a node takes when the layout puts it on one line
///
/// The trimmed description carries the line breaks the source wrote and the indentation under them.
/// The layout writes one space in place of each break, so every run of whitespace counts as one
/// character here. A rule that budgets against the source width instead reaches a different answer
/// for every re-indentation of the same code, and its rewrite then needs a second format call to
/// settle.
///
/// A run of whitespace inside a string literal collapses too, so the result can fall short of the
/// printed width by the characters that run holds. The value is a budget for a rewrite the layout
/// re-measures, not the printed width.
///
/// - Parameters:
///   - node: the node to measure
/// - Returns: The width in characters.
func joinedWidth(of node: some SyntaxProtocol) -> Int {
    var width = 0
    var afterWhitespace = false

    for character in node.trimmedDescription {
        if character.isWhitespace {
            afterWhitespace = true
            continue
        }
        if afterWhitespace, width > 0 { width += 1 }
        afterWhitespace = false
        width += 1
    }
    return width
}
