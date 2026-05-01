import SwiftSyntax
import ConfigurationKit

/// Picks the appropriate severity for a measured metric value against two-tier thresholds. Returns
/// `nil` when the value is at or below the warning threshold (no finding should be emitted).
func metricSeverity(value: Int, warning: Int, error: Int) -> Lint? {
    if value > error { .error } else if value > warning { .warn } else { nil }
}

/// Counts the number of source lines spanned by the given node, optionally excluding lines that are
/// blank or contain only comments.
func bodyLineCount(
    of node: some SyntaxProtocol,
    in converter: SourceLocationConverter,
    countingMeaningfulLinesOnly: Bool = true
) -> Int {
    let start = node.startLocation(converter: converter).line
    let end = node.endLocation(converter: converter).line
    let totalLines = max(end - start - 1, 0)  // exclude the lines containing { and }

    guard countingMeaningfulLinesOnly else { return totalLines }

    // Walk tokens within the node and collect line numbers that contain at least one non-trivia,
    // non-comment token.
    var meaningfulLines = Set<Int>()

    for token in node.tokens(viewMode: .sourceAccurate) {
        let line = token.startLocation(converter: converter).line
        if line > start, line < end { meaningfulLines.insert(line) }
    }
    return meaningfulLines.count
}
