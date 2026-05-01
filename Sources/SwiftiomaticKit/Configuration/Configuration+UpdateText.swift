import Foundation

extension Configuration {
    // Not narrowed to `throws(JSON5Scanner.Error)` because the surrounding scanner type is
    // file-internal; a `package` API may not advertise an internal-typed error. Promoting the
    // scanner to `package` for one error type is too much surface area for the win.

    /// Apply an `UpdateDiff` to a configuration source string with surgical text edits, preserving
    /// original key order, indentation, and JSON5 comments.
    ///
    /// New entries are appended at the end of their destination group (or at the end of the root
    /// object for ungrouped keys); brand-new groups are appended at the end of the root. Removals
    /// delete the key's logical block and rebalance the trailing comma on the previous sibling when
    /// the removed key was the last child.
    package static func applyUpdateText(
        _ diff: UpdateDiff,
        to source: String,
        defaults: [String: JSONValue]
    ) throws -> String {
        let layout = try JSON5Scanner.parseDocument(source)

        // Edits are accumulated as text replacements over the original `source` , applied in
        // reverse order of `range.lowerBound` so earlier offsets stay valid as later ones shift.
        var edits: [TextEdit] = []

        // 1. Removals (unknown rules).
        for qualifiedKey in diff.toRemove {
            if let edit = removalEdit(forQualifiedKey: qualifiedKey, in: source, layout: layout) {
                edits.append(edit)
            }
        }

        // 2. Misplaced — remove from foundAt; insert (with original value) at correctAt.
        for entry in diff.misplaced {
            if let edit = removalEdit(forQualifiedKey: entry.foundAt, in: source, layout: layout) {
                edits.append(edit)
            }
        }

        // 3. Additions — insert each new key at its destination group / root.
        // Group inserts are batched per-group so multi-add into the same target produces
        // deterministic, append-order output.
        var insertionsByTarget: [InsertTarget: [(qualifiedKey: String, value: JSONValue)]] = [:]

        for qualifiedKey in diff.toAdd {
            let value = defaultValue(forQualifiedKey: qualifiedKey, defaults: defaults)
            let target = insertTarget(forQualifiedKey: qualifiedKey)
            insertionsByTarget[target, default: []].append((qualifiedKey, value))
        }
        for entry in diff.misplaced {
            let target = insertTarget(forQualifiedKey: entry.correctAt)
            insertionsByTarget[target, default: []].append((entry.correctAt, entry.value))
        }

        edits.append(
            contentsOf: insertionEdits(
                insertionsByTarget: insertionsByTarget,
                source: source,
                layout: layout
            ))

        // Apply right-to-left.
        var result = source

        for edit in edits.sorted(by: { $0.range.lowerBound > $1.range.lowerBound }) {
            result.replaceSubrange(edit.range, with: edit.replacement)
        }
        return result
    }

    // MARK: - Edit model

    private struct TextEdit {
        var range: Range<String.Index>
        var replacement: String
    }

    private enum InsertTarget: Hashable {
        case root
        case group(String)
    }

    // MARK: - Removal

    /// Build the text edit needed to delete `qualifiedKey` from the file. When the deleted member
    /// is the last child of its container, the prior sibling's trailing comma is also removed.
    private static func removalEdit(
        forQualifiedKey qualifiedKey: String,
        in source: String,
        layout: JSON5Scanner.ObjectLayout
    ) -> TextEdit? {
        let (groupName, name) = qualifiedKey.qualifiedKeyParts

        if let groupName {
            guard let group = layout.members.first(where: { $0.key == groupName }),
                  let nested = group.nested,
                  let memberIndex = nested.members.firstIndex(where: { $0.key == name }) else {
                return nil
            }
            return removalEdit(memberIndex: memberIndex, container: nested, source: source)
        } else {
            guard let memberIndex = layout.members.firstIndex(where: { $0.key == qualifiedKey })
            else { return nil }
            return removalEdit(memberIndex: memberIndex, container: layout, source: source)
        }
    }

    private static func removalEdit(
        memberIndex: Int,
        container: JSON5Scanner.ObjectLayout,
        source _: String
    ) -> TextEdit {
        let member = container.members[memberIndex]
        let isLast = memberIndex == container.members.count - 1
        let hasPrev = memberIndex > 0

        // If we're removing the last child and there's a previous sibling with a trailing comma,
        // also remove that comma so the file stays valid.
        if isLast, hasPrev, let prevComma = container.members[memberIndex - 1].trailingComma {
            let lower = prevComma.lowerBound
            let upper = member.fullRange.upperBound
            return TextEdit(range: lower..<upper, replacement: "")
        }

        return .init(range: member.fullRange, replacement: "")
    }

    // MARK: - Insertion

    private static func insertTarget(forQualifiedKey key: String) -> InsertTarget {
        if let group = key.qualifiedKeyParts.group { .group(group) } else { .root }
    }

    private static func insertionEdits(
        insertionsByTarget: [InsertTarget: [(qualifiedKey: String, value: JSONValue)]],
        source: String,
        layout: JSON5Scanner.ObjectLayout
    ) -> [TextEdit] {
        var edits: [TextEdit] = []

        for (target, items) in insertionsByTarget {
            switch target {
                case .root:
                    edits.append(
                        contentsOf: insertion(
                            into: layout,
                            source: source,
                            items: items,
                            indent: rootChildIndent(layout)
                        ))

                case let .group(groupName):
                    if let groupMember = layout.members.first(where: { $0.key == groupName }),
                       let nested = groupMember.nested
                    {
                        edits.append(
                            contentsOf: insertion(
                                into: nested,
                                source: source,
                                items: items,
                                indent: groupChildIndent(
                                    nested, fallbackParentIndent: groupMember.indent)
                            ))
                    } else {
                        // Group does not yet exist — create it as a new root member with these
                        // items as its children.
                        edits.append(
                            createGroupEdit(
                                groupName: groupName,
                                items: items,
                                source: source,
                                layout: layout
                            ))
                    }
            }
        }

        return edits
    }

    /// Insertion edits for adding `items` to an existing object, placing each new key in
    /// length-sorted (length asc, alpha tiebreak) position relative to the existing siblings —
    /// matching the file's canonical key order.
    private static func insertion(
        into container: JSON5Scanner.ObjectLayout,
        source: String,
        items: [(qualifiedKey: String, value: JSONValue)],
        indent: String
    ) -> [TextEdit] {
        if container.members.isEmpty {
            // Empty container: emit all items on their own lines; sort by length+alpha.
            let sorted = items.sorted {
                lengthLess(
                    shortKey(forQualifiedKey: $0.qualifiedKey),
                    shortKey(forQualifiedKey: $1.qualifiedKey))
            }
            let closeIndent = indentBeforeBrace(closeBrace: container.closeBrace, source: source)
            var insert = "\n"

            for (i, item) in sorted.enumerated() {
                let key = shortKey(forQualifiedKey: item.qualifiedKey)
                insert += "\(indent)\"\(key)\": \(prettyValue(item.value, indent: indent))"
                if i < sorted.count - 1 { insert += "," }
                insert += "\n"
            }
            insert += closeIndent
            return [
                TextEdit(range: container.closeBrace..<container.closeBrace, replacement: insert)
            ]
        }

        // Bucket each new item by the existing member it should sit after, using length+alpha sort.
        // `predIndex == -1` means "before the first member".
        var buckets: [Int: [(qualifiedKey: String, value: JSONValue)]] = [:]
        let existingKeys = container.members.map(\.key)

        for item in items {
            let predIndex = predecessorIndex(
                for: shortKey(forQualifiedKey: item.qualifiedKey),
                among: existingKeys
            )
            buckets[predIndex, default: []].append(item)
        }
        // Sort within each bucket by length+alpha so multiple inserts at the same point land in
        // canonical order.
        for k in buckets.keys {
            buckets[k]!.sort {
                lengthLess(
                    shortKey(forQualifiedKey: $0.qualifiedKey),
                    shortKey(forQualifiedKey: $1.qualifiedKey))
            }
        }

        let lastIndex = container.members.count - 1
        var edits: [TextEdit] = []

        for (predIndex, bucket) in buckets {
            // Does this bucket become the new tail of the container? Only if its predecessor is the
            // existing last member AND no new last existed before.
            let becomesTail = predIndex == lastIndex

            if predIndex == -1 {
                // Insert before the first existing member, at its line start.
                let first = container.members[0]
                var text = ""

                for item in bucket {
                    let key = shortKey(forQualifiedKey: item.qualifiedKey)
                    text += "\(indent)\"\(key)\": \(prettyValue(item.value, indent: indent)),\n"
                }
                edits.append(
                    TextEdit(
                        range: first.fullRange.lowerBound..<first.fullRange.lowerBound,
                        replacement: text
                    ))
            } else {
                // Insert after `members[predIndex]` . Ensure that member ends in a comma.
                let pred = container.members[predIndex]
                let needsLeadingComma = pred.trailingComma == nil

                var text = ""

                for item in bucket {
                    let key = shortKey(forQualifiedKey: item.qualifiedKey)
                    text += "\(indent)\"\(key)\": \(prettyValue(item.value, indent: indent)),\n"
                }
                if becomesTail, text.hasSuffix(",\n") {
                    // New tail of the container — strip the very last trailing comma to match the
                    // existing "no trailing comma on last member" style.
                    text.removeLast(2)
                    text += "\n"
                }

                if needsLeadingComma {
                    let from = pred.valueRange.upperBound
                    let to: String.Index = (predIndex == lastIndex)
                        ? container.closeBrace
                        : container.members[predIndex + 1].fullRange.lowerBound
                    let between = String(source[from..<to])
                    edits.append(TextEdit(range: from..<to, replacement: "," + between + text))
                } else {
                    edits.append(
                        TextEdit(
                            range: pred.fullRange.upperBound..<pred.fullRange.upperBound,
                            replacement: text
                        ))
                }
            }
        }

        return edits
    }

    /// Returns the largest index `i` in `keys` such that `keys[i]` precedes `newKey` in
    /// length+alpha order. Returns `-1` if `newKey` should sort before every existing key.
    private static func predecessorIndex(for newKey: String, among keys: [String]) -> Int {
        var pred = -1
        for (i, k) in keys.enumerated() where lengthLess(k, newKey) { pred = i }
        return pred
    }

    /// Length-then-alpha key comparator. Mirrors `JSONValue.serialize(sortBy: .length)` .
    private static func lengthLess(_ a: String, _ b: String) -> Bool {
        a.count < b.count || (a.count == b.count && a < b)
    }

    /// Edit that creates a brand-new group at the end of root and seeds it with `items` as its
    /// children.
    private static func createGroupEdit(
        groupName: String,
        items: [(qualifiedKey: String, value: JSONValue)],
        source: String,
        layout: JSON5Scanner.ObjectLayout
    ) -> TextEdit {
        let childIndent = rootChildIndent(layout)
        let groupIndent = childIndent
        let innerIndent = childIndent + childIndent  // one extra step for nested

        let sortedItems = items.sorted {
            lengthLess(
                shortKey(forQualifiedKey: $0.qualifiedKey),
                shortKey(forQualifiedKey: $1.qualifiedKey))
        }
        var body = ""
        body += "\"\(groupName)\": {\n"

        for (i, item) in sortedItems.enumerated() {
            let key = shortKey(forQualifiedKey: item.qualifiedKey)
            body += "\(innerIndent)\"\(key)\": \(prettyValue(item.value, indent: innerIndent))"
            if i < sortedItems.count - 1 { body += "," }
            body += "\n"
        }
        body += "\(groupIndent)}"

        if layout.members.isEmpty {
            let closeIndent = indentBeforeBrace(closeBrace: layout.closeBrace, source: source)
            let insertion = "\n\(groupIndent)\(body)\n\(closeIndent)"
            return TextEdit(range: layout.closeBrace..<layout.closeBrace, replacement: insertion)
        }

        let last = layout.members[layout.members.count - 1]

        if last.trailingComma == nil {
            // Need to add a comma after previous last member, then add our group.
            let from = last.valueRange.upperBound
            let to = layout.closeBrace
            let between = String(source[from..<to])
            let newText = "," + between + "\(groupIndent)\(body)\n"
            return TextEdit(range: from..<to, replacement: newText)
        } else {
            let insertion = "\(groupIndent)\(body)\n"
            return TextEdit(
                range: layout.closeBrace..<layout.closeBrace,
                replacement: insertion
            )
        }
    }

    // MARK: - Indentation helpers

    /// Indent used by direct children of the root object. Inferred from the first existing child;
    /// falls back to two spaces when the file is empty.
    private static func rootChildIndent(_ layout: JSON5Scanner.ObjectLayout) -> String {
        if let first = layout.members.first { return String(first.indent) }
        return "  "
    }

    /// Indent used by children of a group object. Inferred from the first existing child; falls
    /// back to the parent group's indent + 2 spaces.
    private static func groupChildIndent(
        _ container: JSON5Scanner.ObjectLayout,
        fallbackParentIndent: Substring
    ) -> String {
        if let first = container.members.first { return String(first.indent) }
        return String(fallbackParentIndent) + "  "
    }

    /// The leading whitespace on the line containing the closing brace. Used when inserting the
    /// first child into an empty `{}` so the close brace lines up.
    private static func indentBeforeBrace(closeBrace: String.Index, source: String) -> String {
        var p = closeBrace
        var ws = ""

        while p > source.startIndex {
            let prev = source.index(before: p)
            let c = source[prev]
            if c == "\n" { break }

            if c == " " || c == "\t" {
                ws = String(c) + ws
                p = prev
            } else {
                // Non-whitespace before brace on the same line — give up and use empty.
                return ""
            }
        }
        return ws
    }

    // MARK: - Value rendering

    /// Pretty-print a JSON value at the given indentation. Uses the same length-sorted,
    /// compact-small-objects style as `Configuration+Dump` , so inserted entries match the rest of
    /// the file visually.
    private static func prettyValue(_ value: JSONValue, indent: String) -> String {
        let raw = value.serialize(sortBy: .length)
        // Re-indent every line after the first by `indent` .
        var lines = raw.components(separatedBy: "\n")
        for i in 1..<lines.count { lines[i] = indent + lines[i] }
        let reindented = lines.joined(separator: "\n")
        return compactSmallObjectsForInsertion(reindented)
    }

    /// Mirrors `Configuration+Dump.compactSmallObjects` for a single inserted value: collapse small
    /// scalar-only objects onto a single line when they fit within 100 columns.
    private static func compactSmallObjectsForInsertion(_ json: String) -> String {
        let maxWidth = 100
        let lines = json.components(separatedBy: "\n")
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasSuffix("{") {
                var objectLines = [line]
                var depth = 1
                var j = i + 1
                var hasNested = false

                while j < lines.count, depth > 0 {
                    let inner = lines[j].trimmingCharacters(in: .whitespaces)

                    if inner.contains("{") {
                        depth += 1
                        hasNested = true
                    }
                    if inner.contains("}") { depth -= 1 }
                    objectLines.append(lines[j])
                    j += 1
                }
                if !hasNested, depth == 0 {
                    let compact = compactObject(objectLines)

                    if compact.count <= maxWidth {
                        result.append(compact)
                        i = j
                        continue
                    }
                }
            }
            result.append(line)
            i += 1
        }
        return result.joined(separator: "\n")
    }

    private static func compactObject(_ lines: [String]) -> String {
        guard let first = lines.first else { return "" }

        let indent = first.prefix(while: { $0 == " " })
        let firstTrimmed = first.trimmingCharacters(in: .whitespaces)
        let keyPrefix = String(firstTrimmed.dropLast()).trimmingCharacters(in: .whitespaces)
        var pairs: [String] = []

        for line in lines.dropFirst().dropLast() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let clean = trimmed.hasSuffix(",")
                ? String(trimmed.dropLast())
                : trimmed
            if !clean.isEmpty { pairs.append(clean) }
        }
        let lastLine = lines.last!.trimmingCharacters(in: .whitespaces)
        let trailing = lastLine.hasSuffix(",") ? "," : ""

        return "\(indent)\(keyPrefix) { \(pairs.joined(separator: ", ")) }\(trailing)"
    }

    // MARK: - Default value lookup (mirrors apply path)

    private static func defaultValue(
        forQualifiedKey key: String,
        defaults: [String: JSONValue]
    ) -> JSONValue {
        let (group, name) = key.qualifiedKeyParts
        if let group, case let .object(groupDict) = defaults[group] {
            return groupDict[name] ?? .object([:])
        }
        if group == nil, let value = defaults[key] { return value }

        return .object([:])
    }

    private static func shortKey(forQualifiedKey key: String) -> String {
        key.qualifiedKeyParts.name
    }
}
