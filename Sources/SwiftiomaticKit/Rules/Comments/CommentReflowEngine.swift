import Foundation

/// Pure reflow engine for `///` and `//` comment runs.
///
/// Given a list of body lines (the text after the comment prefix and an optional single leading
/// space), returns a new list of body lines that fit `availableWidth` columns. DocC structures —
/// parameter blocks, lists, code fences, block quotes, and atomic tokens like URLs / inline code /
/// Markdown links — are preserved.
///
/// Returns `nil` if the input is already optimal (no change).
package enum CommentReflowEngine {
    package static func reflow(
        lines: [String],
        availableWidth: Int
    ) -> [String]? {
        guard availableWidth > 2 else { return nil }
        let blocks = parseBlocks(lines)
        var output: [String] = []
        for block in blocks { block.render(into: &output, width: availableWidth) }
        return output == lines ? nil : output
    }

    // MARK: - Block parsing

    /// A logical chunk of the comment, derived from the input lines.
    fileprivate enum Block {
        case blank
        case codeFence(open: String, body: [String], close: String?)
        case paragraph(text: String)
        case list(items: [ListItem], parameterBlock: Bool)
        case blockQuote(inner: [Block])
        case verbatim(line: String)

        func render(into out: inout [String], width: Int) {
            switch self {
                case .blank: out.append("")
                case let .codeFence(open, body, close):
                    out.append(open)
                    out.append(contentsOf: body)
                    if let close { out.append(close) }
                case let .paragraph(text):
                    out.append(
                        contentsOf: wrapParagraph(
                            text: text,
                            width: width,
                            continuation: ""
                        ))
                case .list(let items, _):
                    for item in items {
                        let marker = item.marker  // e.g. "- " or "  - " or "1. "
                        let continuation = String(repeating: " ", count: marker.count)
                        let firstLineLeading = marker
                        let wrapped = wrapParagraph(
                            text: item.text,
                            width: max(8, width - marker.count),
                            continuation: ""
                        )

                        if wrapped.isEmpty {
                            out.append(firstLineLeading.trimmingTrailingWhitespace())
                        } else {
                            out.append(firstLineLeading + wrapped[0])
                            for tail in wrapped.dropFirst() { out.append(continuation + tail) }
                        }
                        // Render any nested blocks inside this list item, indented under the
                        // marker.
                        var nestedOut: [String] = []

                        for nested in item.nested {
                            nested.render(into: &nestedOut, width: max(8, width - marker.count))
                        }
                        for line in nestedOut {
                            if line.isEmpty {
                                out.append("")
                            } else {
                                out.append(continuation + line)
                            }
                        }
                    }
                case let .blockQuote(inner):
                    var nestedOut: [String] = []
                    for b in inner { b.render(into: &nestedOut, width: max(8, width - 2)) }
                    // First line of each contiguous non-blank run gets "> ", continuation lines get
                    // lazy indent (" "). Blank separator lines keep "> " (rendered as ">").
                    var pendingFirst = true

                    for line in nestedOut {
                        if line.isEmpty {
                            out.append(">")
                            pendingFirst = true
                        } else if pendingFirst {
                            out.append("> " + line)
                            pendingFirst = false
                        } else {
                            out.append("  " + line)
                        }
                    }
                case let .verbatim(line): out.append(line)
            }
        }
    }

    fileprivate struct ListItem {
        var marker: String  // "- ", "* ", "1. ", "  - ", etc.
        var text: String  // body of the item (single logical paragraph)
        var nested: [Block] = []  // nested content (e.g. param descriptions)
    }

    /// Parses body lines into blocks. Single-pass, handles fences, block quotes, lists, and
    /// `- Parameters:` blocks specially.
    private static func parseBlocks(_ lines: [String]) -> [Block] {
        var blocks: [Block] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]
            // Code fence
            if let fenceMarker = fenceOpener(line) {
                var body: [String] = []
                var close: String?
                i += 1

                while i < lines.count {
                    if isFenceCloser(lines[i], opener: fenceMarker) {
                        close = lines[i]
                        i += 1
                        break
                    }
                    body.append(lines[i])
                    i += 1
                }
                blocks.append(.codeFence(open: line, body: body, close: close))
                continue
            }
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                blocks.append(.blank)
                i += 1
                continue
            }
            // Block quote: contiguous lines starting with ">".
            if line.hasPrefix(">") {
                var quoted: [String] = []

                while i < lines.count, lines[i].hasPrefix(">") {
                    let dropped = String(lines[i].dropFirst())
                    let stripped = dropped.hasPrefix(" ") ? String(dropped.dropFirst()) : dropped
                    quoted.append(stripped)
                    i += 1
                }
                let innerBlocks = parseBlocks(quoted)
                blocks.append(.blockQuote(inner: innerBlocks))
                continue
            }
            // List (incl. `- Parameters:` block)
            if listMarker(line) != nil {
                let (items, consumed, isParamBlock) = parseList(lines, startingAt: i)
                blocks.append(.list(items: items, parameterBlock: isParamBlock))
                i += consumed
                continue
            }
            // Paragraph: collect contiguous non-special lines.
            var paraLines: [String] = []

            while i < lines.count {
                let l = lines[i]
                if l.trimmingCharacters(in: .whitespaces).isEmpty { break }
                if l.hasPrefix(">") { break }
                if listMarker(l) != nil { break }
                if fenceOpener(l) != nil { break }
                paraLines.append(l.trimmingCharacters(in: .whitespaces))
                i += 1
            }
            blocks.append(.paragraph(text: paraLines.joined(separator: " ")))
        }
        return blocks
    }

    /// Returns the fence string (e.g. "` ` ` " or "~~~") if ` line` opens a fenced code block.
    private static func fenceOpener(_ line: String) -> String? {
        let trimmed = line.drop(while: { $0 == " " })
        if trimmed.hasPrefix("```") { return "```" }
        return trimmed.hasPrefix("~~~") ? "~~~" : nil
    }

    private static func isFenceCloser(_ line: String, opener: String) -> Bool {
        let trimmed = line.drop(while: { $0 == " " })
        return trimmed.hasPrefix(opener)
    }

    /// Returns the list marker (incl. trailing space) and the index where the body starts within
    /// `line` , or nil if `line` is not a list item.
    private static func listMarker(_ line: String) -> (marker: String, bodyOffset: Int)? {
        // Allow up to 3 leading spaces of indent before the marker.
        var idx = line.startIndex
        var leading = 0

        while idx < line.endIndex, line[idx] == " ", leading < 3 {
            idx = line.index(after: idx)
            leading += 1
        }
        guard idx < line.endIndex else { return nil }
        let ch = line[idx]
        // Bullet: -, *, +
        if ch == "-" || ch == "*" || ch == "+" {
            let next = line.index(after: idx)

            if next < line.endIndex, line[next] == " " {
                let markerEnd = line.index(after: next)
                let marker = String(line[line.startIndex..<markerEnd])
                return (
                    marker: marker, bodyOffset: line.distance(from: line.startIndex, to: markerEnd)
                )
            }
            return nil
        }
        // Ordered: digits + "."
        if ch.isNumber {
            var j = idx
            while j < line.endIndex, line[j].isNumber { j = line.index(after: j) }

            if j < line.endIndex,
               line[j] == ".",
               line.index(after: j) < line.endIndex,
               line[line.index(after: j)] == " "
            {
                let markerEnd = line.index(j, offsetBy: 2)
                let marker = String(line[line.startIndex..<markerEnd])
                return (
                    marker: marker, bodyOffset: line.distance(from: line.startIndex, to: markerEnd)
                )
            }
        }
        return nil
    }

    /// Parses a contiguous list starting at `start` . List ends on blank line or non-list line at
    /// the same or lesser indentation. Returns the parsed items, lines consumed, and whether this
    /// list is a `- Parameters:` block (its first item's text is exactly "Parameters:").
    private static func parseList(
        _ lines: [String],
        startingAt start: Int
    ) -> (items: [ListItem], consumed: Int, parameterBlock: Bool) {
        var items: [ListItem] = []
        var i = start
        var isParamBlock = false
        var firstItemMarkerIndent: Int?

        while i < lines.count {
            let line = lines[i]
            guard let m = listMarker(line) else { break }
            let leading = line.prefix(while: { $0 == " " }).count

            if let baseline = firstItemMarkerIndent, leading > baseline {
                // A more-indented marker is a nested list — handle by treating the next list as
                // nested under the previous item via continuation lines below. For simplicity we
                // fold it into the previous item's `nested` blocks.
                let nestedStart = i
                let (rawNested, consumed, _) = parseList(lines, startingAt: nestedStart)
                // Strip leading whitespace from nested item markers; the parent's `continuation`
                // prefix is the sole authoritative source of indentation when rendering nested
                // blocks. Without this, the original leading spaces would compound with the
                // parent's continuation, doubling the indent at each nesting level.
                let nested = rawNested.map { item -> ListItem in
                    var copy = item
                    copy.marker = String(item.marker.drop(while: { $0 == " " }))
                    return copy
                }
                if !items.isEmpty {
                    items[items.count - 1].nested.append(
                        .list(
                            items: nested,
                            parameterBlock: false
                        ))
                }
                i += consumed
                continue
            }
            if firstItemMarkerIndent == nil {
                firstItemMarkerIndent = leading
                let bodyText = String(line[line.index(line.startIndex, offsetBy: m.bodyOffset)...])
                if bodyText.trimmingCharacters(in: .whitespaces) == "Parameters:" {
                    isParamBlock = true
                }
            }
            let bodyText = String(line[line.index(line.startIndex, offsetBy: m.bodyOffset)...])
            var item = ListItem(
                marker: String(repeating: " ", count: leading)
                    + String(m.marker.drop(while: { $0 == " " })),
                text: bodyText.trimmingCharacters(in: .whitespaces)
            )
            i += 1
            // Collect continuation lines: indented further than the marker, not blank, not a new
            // list marker at the same indent.
            while i < lines.count {
                let next = lines[i]
                if next.trimmingCharacters(in: .whitespaces).isEmpty { break }
                let nextLeading = next.prefix(while: { $0 == " " }).count
                if nextLeading <= leading, listMarker(next) != nil { break }
                if nextLeading <= leading { break }

                if let nm = listMarker(next), nextLeading > leading {
                    // nested list inside this item
                    let (rawNested, consumed, _) = parseList(lines, startingAt: i)
                    let nested = rawNested.map { item -> ListItem in
                        var copy = item
                        copy.marker = String(item.marker.drop(while: { $0 == " " }))
                        return copy
                    }
                    item.nested.append(.list(items: nested, parameterBlock: false))
                    _ = nm
                    i += consumed
                    continue
                }
                // Plain continuation: append to the item's text.
                item.text += " " + next.trimmingCharacters(in: .whitespaces)
                i += 1
            }
            items.append(item)
        }
        return (items, i - start, isParamBlock)
    }

    // MARK: - Atom-aware paragraph wrap

    /// Greedy word-wrap for a paragraph, respecting unbreakable atoms (URLs, inline code, Markdown
    /// links, autolinks). Atoms larger than `width` get their own line and are allowed to overflow.
    fileprivate static func wrapParagraph(
        text: String,
        width: Int,
        continuation _: String
    ) -> [String] {
        let atoms = tokenize(text)
        guard !atoms.isEmpty else { return [] }
        var lines: [String] = []
        var current = ""

        for atom in atoms {
            if current.isEmpty {
                current = atom
                continue
            }
            // current + " " + atom fits?
            if current.count + 1 + atom.count <= width {
                current += " " + atom
            } else {
                lines.append(current)
                current = atom
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }

    /// Splits a paragraph into atoms: words plus indivisible runs (URLs, inline code, Markdown
    /// links, autolinks). Whitespace is the separator and is dropped.
    package static func tokenize(_ text: String) -> [String] {
        var atoms: [String] = []
        let scalars = Array(text)
        var i = 0
        var pending = ""
        func flush() {
            if !pending.isEmpty {
                atoms.append(pending)
                pending = ""
            }
        }
        while i < scalars.count {
            let c = scalars[i]

            if c == " " || c == "\t" {
                flush()
                i += 1
                continue
            }
            // Inline code span: a run of N backticks closes on the next run of exactly N backticks.
            // Handles single-backtick code spans AND DocC double-backtick symbol references (
            // ``Foo/bar()`` ). Without this, `` ` `` would close on the second opening backtick,
            // splitting the symbol reference into separate atoms and letting the wrapper insert
            // spaces inside it.
            if c == "`" {
                var openCount = 0
                var k = i

                while k < scalars.count, scalars[k] == "`" {
                    openCount += 1
                    k += 1
                }
                // Search for a closing run of exactly `openCount` backticks.
                var j = k
                var closeStart: Int?

                while j < scalars.count {
                    if scalars[j] == "`" {
                        var run = 0
                        var m = j

                        while m < scalars.count, scalars[m] == "`" {
                            run += 1
                            m += 1
                        }
                        if run == openCount {
                            closeStart = j
                            break
                        }
                        j = m
                        continue
                    }
                    j += 1
                }
                if let cs = closeStart {
                    flush()
                    let endExclusive = cs + openCount
                    atoms.append(String(scalars[i..<endExclusive]))
                    i = endExclusive
                    continue
                }
            }
            // Markdown link: [text](url) — atomic if balanced.
            if c == "[" {
                if let end = matchMarkdownLink(scalars, from: i) {
                    flush()
                    atoms.append(String(scalars[i...end]))
                    i = end + 1
                    continue
                }
            }
            // Autolink: <scheme://...>
            if c == "<" {
                if let end = matchAutolink(scalars, from: i) {
                    flush()
                    atoms.append(String(scalars[i...end]))
                    i = end + 1
                    continue
                }
            }
            // URL: http(s)://... — read until whitespace.
            if c == "h", isURLStart(scalars, at: i) {
                flush()
                var j = i
                while j < scalars.count, scalars[j] != " ", scalars[j] != "\t" { j += 1 }
                atoms.append(String(scalars[i..<j]))
                i = j
                continue
            }
            pending.append(c)
            i += 1
        }
        flush()
        return atoms
    }

    private static func matchMarkdownLink(_ s: [Character], from i: Int) -> Int? {
        // [text](url)
        var j = i + 1
        var depth = 1

        while j < s.count {
            if s[j] == "[" {
                depth += 1
            } else if s[j] == "]" {
                depth -= 1
                if depth == 0 { break }
            }
            j += 1
        }
        guard j < s.count, j + 1 < s.count, s[j + 1] == "(" else { return nil }
        var k = j + 2
        var pdepth = 1

        while k < s.count {
            if s[k] == "(" {
                pdepth += 1
            } else if s[k] == ")" {
                pdepth -= 1
                if pdepth == 0 { return k }
            }
            k += 1
        }
        return nil
    }

    private static func matchAutolink(_ s: [Character], from i: Int) -> Int? {
        var j = i + 1
        // Need at least one ":" before ">" to qualify as URL-ish.
        var sawColon = false

        while j < s.count, s[j] != ">", s[j] != " " {
            if s[j] == ":" { sawColon = true }
            j += 1
        }
        guard j < s.count, s[j] == ">", sawColon else { return nil }
        return j
    }

    private static func isURLStart(_ s: [Character], at i: Int) -> Bool {
        let httpChars: [Character] = ["h", "t", "t", "p"]
        guard i + 6 <= s.count else { return false }
        for k in 0..<4 where s[i + k] != httpChars[k] { return false }
        // http:// or https://
        if s[i + 4] == ":" { return s[i + 5] == "/" && s[i + 6 - 1] == "/" }
        if i + 8 <= s.count, s[i + 4] == "s", s[i + 5] == ":" {
            return s[i + 6] == "/" && s[i + 7] == "/"
        }
        return false
    }
}

fileprivate extension String {
    func trimmingTrailingWhitespace() -> String {
        var end = endIndex

        while end > startIndex {
            let prev = index(before: end)
            if self[prev] == " " || self[prev] == "\t" { end = prev } else { break }
        }
        return String(self[..<end])
    }
}
