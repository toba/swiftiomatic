/// The indentation of the current output line, kept as a stack of segments with a running width.
///
/// `LayoutCoordinator` pushes one segment for each open break and pops it at the matching close
/// break. Only the top segment changes in place. The width is a running total, so a width query
/// does not walk the stack. `append(to:)` writes the indentation text straight into a string, so a
/// line indent allocates no intermediate `String` or array.
struct LayoutIndentation {
    /// One entry of the indentation stack.
    enum Segment: Equatable {
        /// The given number of configured indentation units.
        case units(Int)

        /// The given number of spaces, used by alignment breaks.
        case spaces(Int)
    }

    /// The text of one configured indentation unit.
    let unitText: String

    /// The column width of one configured indentation unit.
    let unitWidth: Int

    /// The open-break segments, from the outermost to the innermost.
    private var segments: [Segment] = []

    /// The total column width of `segments` .
    private var segmentsWidth = 0

    /// Whether the current line is a continuation line. A continuation line adds one unit after
    /// the segments.
    var isContinuation = false

    /// Whether the indentation is temporarily empty. A standalone comment that keeps its column 0
    /// uses this.
    var isSuppressed = false

    init(unit: Indent, tabWidth: Int) {
        unitText = unit.text
        unitWidth = unit.length(tabWidth: tabWidth)
    }

    /// The column width of the indentation.
    var width: Int {
        isSuppressed ? 0 : segmentsWidth + (isContinuation ? unitWidth : 0)
    }

    /// Pushes a segment onto the stack.
    mutating func push(_ segment: Segment) {
        segments.append(segment)
        segmentsWidth += width(of: segment)
    }

    /// Removes the top segment from the stack.
    mutating func pop() {
        guard let segment = segments.popLast() else { return }
        segmentsWidth -= width(of: segment)
    }

    /// Replaces the top segment of the stack.
    mutating func replaceLast(with segment: Segment) {
        guard let last = segments.last else { return }
        segmentsWidth += width(of: segment) - width(of: last)
        segments[segments.count - 1] = segment
    }

    /// Appends the indentation text to the given string.
    func append(to output: inout String) {
        guard !isSuppressed else { return }

        for segment in segments {
            switch segment {
                case let .units(count): for _ in 0..<count { output.append(unitText) }
                case let .spaces(count): appendSpaces(count, to: &output)
            }
        }
        if isContinuation { output.append(unitText) }
    }

    private func width(of segment: Segment) -> Int {
        switch segment {
            case let .units(count): count * unitWidth
            case let .spaces(count): count
        }
    }
}

/// Appends the given number of spaces to the string without an intermediate allocation.
func appendSpaces(_ count: Int, to output: inout String) {
    var remaining = count

    while remaining > 0 {
        let chunk = min(remaining, 64)
        output.append(SpacePadding.spaces(chunk))
        remaining -= chunk
    }
}
