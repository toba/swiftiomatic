import XcodeKit

/// Captures a selection range before buffer mutation so it can be restored afterwards.
struct SelectionSnapshot {
    let startLine: Int
    let startColumn: Int
    let endLine: Int
    let endColumn: Int

    init(_ range: XCSourceTextRange) {
        startLine = range.start.line
        startColumn = range.start.column
        endLine = range.end.line
        endColumn = range.end.column
    }

    /// Restore the selection, clamping to the buffer's valid line count.
    func restore(in buffer: XCSourceTextBuffer) -> XCSourceTextRange {
        let maxLine = max(buffer.lines.count - 1, 0)
        return XCSourceTextRange(
            start: XCSourceTextPosition(
                line: min(startLine, maxLine),
                column: startColumn
            ),
            end: XCSourceTextPosition(
                line: min(endLine, maxLine),
                column: endColumn
            )
        )
    }
}

/// Restore an array of selection snapshots into the buffer.
func restoreSelections(_ snapshots: [SelectionSnapshot], in buffer: XCSourceTextBuffer) {
    let selections = buffer.selections
    selections.removeAllObjects()
    for snapshot in snapshots {
        selections.add(snapshot.restore(in: buffer))
    }
}
