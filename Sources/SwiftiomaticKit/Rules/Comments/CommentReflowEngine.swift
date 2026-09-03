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
        case list(items: [ListItem])
        case blockQuote(inner: [Block])
        case verbatim(line: String)

        var isBlank: Bool {
            if case .blank = self { return true }
            return false
        }

        func render(into out: inout [String], width: Int) {
            switch self {
                case .blank: out.append("")
                case let .codeFence(open, body, close):
                    out.append(open)
                    out.append(contentsOf: body)
                    if let close { out.append(close) }
                case let .paragraph(text):
                    out.append(contentsOf: wrapParagraph(text: text, width: width))
                case let .list(items):
                    for item in items {
                        let marker = item.marker  // e.g. "- " or "  - " or "1. "
                        let continuation = String(repeating: " ", count: marker.count)
                        let firstLineLeading = marker
                        let wrapped = wrapParagraph(
                            text: item.text,
                            width: max(8, width - marker.count)
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
                    // every line carries the marker, and a blank separator renders as ">".
                    // CommonMark accepts a lazy continuation for a paragraph alone, so a fence
                    // whose body lines drop the marker leaks out of the quote and never closes
                    // inside it
                    for line in nestedOut { out.append(line.isEmpty ? ">" : "> " + line) }
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
            // CommonMark indented code block: four spaces of indent, opening after a blank line or
            // at the start of the comment. The lines carry code, so they keep their indentation and
            // their line breaks. The fenced path already does this for the fenced form.
            if isIndentedCodeLine(line), blocks.isEmpty || blocks.last?.isBlank == true {
                var last = i
                var j = i

                while j < lines.count {
                    if lines[j].trimmingCharacters(in: .whitespaces).isEmpty {
                        j += 1
                        continue
                    }
                    guard isIndentedCodeLine(lines[j]) else { break }
                    last = j
                    j += 1
                }
                // trailing blanks stop at the last content line, so the loop reads them as
                // separators
                for codeLine in lines[i...last] {
                    blocks.append(.verbatim(line: codeLine.trimmingTrailingWhitespace()))
                }
                i = last + 1
                continue
            }
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
            // CommonMark link reference definition (`[label]: url`). Preserve verbatim — wrapping
            // the URL or merging adjacent definitions onto one line breaks the Markdown.
            if isLinkReferenceDefinition(line) {
                blocks.append(.verbatim(line: line))
                i += 1
                continue
            }
            // Block quote: a `>`-prefixed line, plus any CommonMark "lazy continuation" lines that
            // follow without a `>` prefix (non-blank, not a list / fence / link-ref). The renderer
            // re-adds `> ` on every output line.
            if line.hasPrefix(">") {
                var quoted: [String] = []
                // a fence that opens inside the quote runs to its closer, so an unmarked line
                // between the two is fence body rather than the end of the quote
                var openFence: String?

                while i < lines.count {
                    let cur = lines[i]

                    if cur.hasPrefix(">") {
                        let dropped = String(cur.dropFirst())
                        let stripped = dropped.hasPrefix(" ")
                            ? String(dropped.dropFirst())
                            : dropped
                        updateFenceState(stripped, &openFence)
                        quoted.append(stripped)
                        i += 1
                        continue
                    }
                    if openFence == nil {
                        if cur.trimmingCharacters(in: .whitespaces).isEmpty { break }
                        if listMarker(cur) != nil { break }
                        if fenceOpener(cur) != nil { break }
                        if isLinkReferenceDefinition(cur) { break }
                        quoted.append(cur.trimmingCharacters(in: .whitespaces))
                        i += 1
                        continue
                    }
                    // strip only the lazy indent the renderer used to emit, so the code keeps its
                    // own indentation
                    let body = cur.hasPrefix("  ") ? String(cur.dropFirst(2)) : cur
                    updateFenceState(body, &openFence)
                    quoted.append(body.trimmingTrailingWhitespace())
                    i += 1
                }
                let innerBlocks = parseBlocks(quoted)
                blocks.append(.blockQuote(inner: innerBlocks))
                continue
            }
            // List (incl. `- Parameters:` block)
            if listMarker(line) != nil {
                let (items, consumed) = parseList(lines, startingAt: i)
                blocks.append(.list(items: items))
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
                if isLinkReferenceDefinition(l) { break }
                paraLines.append(l.trimmingCharacters(in: .whitespaces))
                i += 1
            }
            blocks.append(.paragraph(text: paraLines.joined(separator: " ")))
        }
        return blocks
    }

    /// Returns `true` if `line` is a CommonMark link reference definition of the form
    /// `[label]: destination`, allowing up to 3 leading spaces of indent. These lines must remain
    /// on their own — wrapping the destination or merging an adjacent definition into the previous
    /// line invalidates the reference.
    private static func isLinkReferenceDefinition(_ line: String) -> Bool {
        var idx = line.startIndex
        var leading = 0

        while idx < line.endIndex, line[idx] == " ", leading < 3 {
            idx = line.index(after: idx)
            leading += 1
        }
        guard idx < line.endIndex, line[idx] == "[" else { return false }
        let afterOpen = line.index(after: idx)
        guard let closeBracket = line[afterOpen...].firstIndex(of: "]") else { return false }
        // Label must be non-empty and contain no `[` (CommonMark forbids unescaped brackets).
        guard closeBracket > afterOpen,
              !line[afterOpen..<closeBracket].contains("[") else { return false }
        let afterClose = line.index(after: closeBracket)
        guard afterClose < line.endIndex, line[afterClose] == ":" else { return false }
        // Must be followed by whitespace (or end of line in lazy parsers — but we require non-empty
        // destination on the same line, which is the common case in Swift docs).
        let afterColon = line.index(after: afterClose)
        guard afterColon < line.endIndex, line[afterColon] == " " else { return false }
        let dest = line[afterColon...].drop(while: { $0 == " " })
        return !dest.isEmpty
    }

    /// True when `line` holds content behind four or more spaces, or behind a tab. CommonMark reads
    /// such a line as an indented code block when a blank line precedes it.
    private static func isIndentedCodeLine(_ line: String) -> Bool {
        guard line.hasPrefix("    ") || line.hasPrefix("\t") else { return false }
        return !line.trimmingCharacters(in: .whitespaces).isEmpty
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

    /// Tracks whether a fence is open across the lines of a block quote.
    ///
    /// - Parameters:
    ///   - line: One line of quoted content, with the `>` marker already removed
    ///   - openFence: The marker of the fence now open, or `nil` when no fence is open
    private static func updateFenceState(_ line: String, _ openFence: inout String?) {
        if let marker = openFence {
            if isFenceCloser(line, opener: marker) { openFence = nil }
        } else if let marker = fenceOpener(line) { openFence = marker }
    }

    /// DocC list-item keywords that must always sit at the outermost list indent — siblings of
    /// `- Parameters:`, never nested under it. Matched case-sensitively and only when followed by a
    /// colon (the syntax DocC actually recognizes).
    private static let doccTopLevelKeywords: Set<String> = [
        "Returns", "Throws", "Precondition", "Postcondition", "Requires", "Invariant",
        "Complexity", "Important", "Note", "Warning", "Attention", "Author", "Authors",
        "Bug", "Copyright", "Date", "Experiment", "Remark", "SeeAlso", "Since", "Tag",
        "ToDo", "Version",
    ]

    /// Returns true if `bodyText` (a list item's text after the `- ` marker) begins with a DocC
    /// top-level keyword followed by a colon.
    private static func isDocCTopLevelKeyword(_ bodyText: String) -> Bool {
        let trimmed = bodyText.drop(while: { $0 == " " })
        guard let colon = trimmed.firstIndex(of: ":") else { return false }
        let head = String(trimmed[..<colon])
        return doccTopLevelKeywords.contains(head)
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
    /// the same or lesser indentation. Returns the parsed items and the lines consumed.
    private static func parseList(
        _ lines: [String],
        startingAt start: Int
    ) -> (items: [ListItem], consumed: Int) {
        var items: [ListItem] = []
        var i = start
        var firstItemMarkerIndent: Int?

        while i < lines.count {
            let line = lines[i]
            guard let m = listMarker(line) else { break }
            var leading = line.prefix(while: { $0 == " " }).count
            let bodyText = String(line[line.index(line.startIndex, offsetBy: m.bodyOffset)...])

            // DocC top-level keywords (`Returns:`, `Throws:`, etc.) must sit at the outer list's
            // indent, even if the source has them indented under a `- Parameters:` block. When we
            // see one inside a nested list, end the nested list so the outer call picks it up. When
            // the outer call sees one over-indented, force it to the baseline indent.
            if isDocCTopLevelKeyword(bodyText) {
                if let baseline = firstItemMarkerIndent, baseline > 0 {
                    // We're inside a nested list (e.g. Parameters' children). Stop here so the
                    // caller resumes parsing at this line at the outer indent.
                    break
                }
                if let baseline = firstItemMarkerIndent, leading > baseline {
                    // Outer list at baseline 0 saw an over-indented keyword. Treat it as a
                    // top-level sibling rather than recursing into a nested list.
                    leading = baseline
                }
            }

            if let baseline = firstItemMarkerIndent, leading > baseline {
                // A more-indented marker is a nested list — handle by treating the next list as
                // nested under the previous item via continuation lines below. For simplicity we
                // fold it into the previous item's `nested` blocks.
                let nestedStart = i
                let (rawNested, consumed) = parseList(lines, startingAt: nestedStart)
                // Strip leading whitespace from nested item markers; the parent's `continuation`
                // prefix is the sole authoritative source of indentation when rendering nested
                // blocks. Without this, the original leading spaces would compound with the
                // parent's continuation, doubling the indent at each nesting level.
                let nested = rawNested.map { item -> ListItem in
                    var copy = item
                    copy.marker = String(item.marker.drop(while: { $0 == " " }))
                    return copy
                }
                if !items.isEmpty { items[items.count - 1].nested.append(.list(items: nested)) }
                i += consumed
                continue
            }
            if firstItemMarkerIndent == nil { firstItemMarkerIndent = leading }
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

                // Even if `next` is more indented than this item's marker, a DocC top-level keyword
                // (`Returns:`, `Throws:`, …) must not be folded into this item or its nested list —
                // break out so the parent parser can dedent it.
                if let nm = listMarker(next) {
                    let nextBody = String(
                        next[next.index(next.startIndex, offsetBy: nm.bodyOffset)...])
                    if isDocCTopLevelKeyword(nextBody) { break }
                }

                if listMarker(next) != nil, nextLeading > leading {
                    // nested list inside this item
                    let (rawNested, consumed) = parseList(lines, startingAt: i)
                    let nested = rawNested.map { item -> ListItem in
                        var copy = item
                        copy.marker = String(item.marker.drop(while: { $0 == " " }))
                        return copy
                    }
                    item.nested.append(.list(items: nested))
                    i += consumed
                    continue
                }
                // Plain continuation: append to the item's text.
                item.text += " " + next.trimmingCharacters(in: .whitespaces)
                i += 1
            }
            items.append(item)
        }
        return (items, i - start)
    }

    // MARK: - Atom-aware paragraph wrap

    /// Greedy word-wrap for a paragraph, respecting unbreakable atoms (URLs, inline code, Markdown
    /// links, autolinks). Atoms larger than `width` get their own line and are allowed to overflow.
    fileprivate static func wrapParagraph(text: String, width: Int) -> [String] {
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
        let characters = Array(text)
        var i = 0
        var pending = ""
        func flush() {
            if !pending.isEmpty {
                atoms.append(pending)
                pending = ""
            }
        }
        while i < characters.count {
            let c = characters[i]

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

                while k < characters.count, characters[k] == "`" {
                    openCount += 1
                    k += 1
                }
                // Search for a closing run of exactly `openCount` backticks.
                var j = k
                var closeStart: Int?

                while j < characters.count {
                    if characters[j] == "`" {
                        var run = 0
                        var m = j

                        while m < characters.count, characters[m] == "`" {
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
                    let endExclusive = cs + openCount
                    pending.append(String(characters[i..<endExclusive]))
                    i = endExclusive
                    continue
                }
            }
            // Markdown link: [text](url) — atomic if balanced.
            if c == "[" {
                if let link = matchMarkdownLink(characters, from: i) {
                    pending.append(String(characters[i...link.end]))
                    i = link.end + 1
                    continue
                }
            }
            // Autolink: <scheme://...>
            if c == "<" {
                if let end = matchAutolink(characters, from: i) {
                    pending.append(String(characters[i...end]))
                    i = end + 1
                    continue
                }
            }
            // URL: a scheme with "://" or a "www." host — read until whitespace.
            if c.isLetter, isURLStart(characters, at: i) {
                let j = endOfBareURL(characters, from: i)
                pending.append(String(characters[i..<j]))
                i = j
                continue
            }
            pending.append(c)
            i += 1
        }
        flush()
        return atoms
    }

    /// Matches `[text](url)` starting at `i` . Returns the index of the first character of the
    /// target and the index of the closing `)` .
    private static func matchMarkdownLink(
        _ s: [Character],
        from i: Int
    ) -> (targetStart: Int, end: Int)? {
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
                if pdepth == 0 { return (targetStart: j + 2, end: k) }
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

    /// True when a bare URL starts at `i` .
    ///
    /// A bare URL needs explicit URL syntax: a scheme followed by `://` , or a `www.` host prefix.
    /// A property access such as `post.id` carries neither, so it never qualifies. Upstream
    /// SwiftLint added the same restriction in commit `e3f29820` , because a detector that reads
    /// `post.id` as a host name hides a real overlong line.
    private static func isURLStart(_ s: [Character], at i: Int) -> Bool {
        guard i < s.count else { return false }
        // www. host, with no scheme.
        if i + 4 <= s.count,
           s[i] == "w" || s[i] == "W",
           s[i + 1] == "w" || s[i + 1] == "W",
           s[i + 2] == "w" || s[i + 2] == "W",
           s[i + 3] == "." { return true }
        // scheme://
        guard s[i].isLetter else { return false }
        var j = i

        while j < s.count,
              s[j].isLetter || s[j].isNumber || s[j] == "+" || s[j] == "."
                  || s[j] == "-"
        { j += 1 }
        guard j + 3 <= s.count, s[j] == ":", s[j + 1] == "/", s[j + 2] == "/" else { return false }
        return true
    }

    /// True when the character at `i` opens a word. The characters a scheme accepts are the ones
    /// that continue a word.
    private static func isWordStart(_ s: [Character], at i: Int) -> Bool {
        guard i > 0 else { return true }
        let p = s[i - 1]
        return !(p.isLetter || p.isNumber || p == "+" || p == "." || p == "-")
    }

    /// The index one past the last character of the bare URL that starts at `i` . A bare URL runs
    /// to the next whitespace.
    private static func endOfBareURL(_ s: [Character], from i: Int) -> Int {
        var j = i

        while j < s.count, s[j] != " ", s[j] != "\t" { j += 1 }
        return j
    }

    // MARK: - URL runs

    /// The character ranges of the URL runs in `characters` .
    ///
    /// A run is a Markdown link, an autolink, or a bare URL, and it is indivisible. Every form
    /// needs explicit URL syntax in its target: a scheme followed by `://` , or a `www.` host. The
    /// ranges never overlap, and they are in ascending order.
    ///
    /// `LineLengthLimit` subtracts these ranges before it measures a line. A URL cannot wrap, so a
    /// finding about one names no fix the reader can apply.
    package static func urlRuns(in characters: [Character]) -> [Range<Int>] {
        var runs: [Range<Int>] = []
        var i = 0

        while i < characters.count {
            let c = characters[i]

            if c == "[",
               let link = matchMarkdownLink(characters, from: i),
               isURLStart(characters, at: link.targetStart)
            {
                runs.append(i..<(link.end + 1))
                i = link.end + 1
                continue
            }
            if c == "<",
               let end = matchAutolink(characters, from: i),
               isURLStart(characters, at: i + 1)
            {
                runs.append(i..<(end + 1))
                i = end + 1
                continue
            }
            // Test a bare URL only at the start of a word. This keeps the scheme scan off every
            // character of a long identifier.
            if c.isLetter, isWordStart(characters, at: i), isURLStart(characters, at: i) {
                let end = endOfBareURL(characters, from: i)
                runs.append(i..<end)
                i = end
                continue
            }
            i += 1
        }
        return runs
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
