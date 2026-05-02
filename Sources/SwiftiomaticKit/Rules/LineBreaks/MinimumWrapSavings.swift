/// Minimum column savings required to wrap a continuation break whose wrapped
/// chunk would still exceed the line length.
///
/// When the formatter is about to fire a `.continue` break and the chunk that
/// follows is longer than `LineLength`, it would overflow whether wrapped or
/// not. In that case the wrap only fires when it shortens the line by at least
/// this many columns; otherwise the over-long content stays inline rather than
/// taking on extra indentation that doesn't help the line fit.
///
/// Lower values wrap more aggressively even when the wrap doesn't help; higher
/// values keep over-long content inline more often.
package struct MinimumWrapSavings: LayoutRule {
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description =
        "Minimum columns wrapping must save before applying a continuation break whose wrapped chunk would still exceed the line length."
    package static let defaultValue = 8
}
