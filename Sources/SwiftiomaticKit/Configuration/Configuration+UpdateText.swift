import Foundation

extension Configuration {
  /// Apply an `UpdateDiff` to a configuration source string with surgical text
  /// edits, preserving original key order, indentation, and JSON5 comments.
  ///
  /// New entries are appended at the end of their destination group (or at
  /// the end of the root object for ungrouped keys); brand-new groups are
  /// appended at the end of the root. Removals delete the key's logical
  /// block and rebalance the trailing comma on the previous sibling when
  /// the removed key was the last child.
  package static func applyUpdateText(
    _ diff: UpdateDiff,
    to source: String,
    defaults: [String: JSONValue]
  ) throws -> String {
    let layout = try JSON5Scanner.parseDocument(source)

    // Edits are accumulated as text replacements over the original `source`,
    // applied in reverse order of `range.lowerBound` so earlier offsets stay
    // valid as later ones shift.
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
    // Group inserts are batched per-group so multi-add into the same target
    // produces deterministic, append-order output.
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
      )
    )

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

  /// Build the text edit needed to delete `qualifiedKey` from the file.
  /// When the deleted member is the last child of its container, the prior
  /// sibling's trailing comma is also removed.
  private static func removalEdit(
    forQualifiedKey qualifiedKey: String,
    in source: String,
    layout: JSON5Scanner.ObjectLayout
  ) -> TextEdit? {
    let parts = qualifiedKey.split(separator: ".", maxSplits: 1).map(String.init)
    if parts.count == 2 {
      guard let group = layout.members.first(where: { $0.key == parts[0] }),
        let nested = group.nested,
        let memberIndex = nested.members.firstIndex(where: { $0.key == parts[1] })
      else { return nil }
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
    source: String
  ) -> TextEdit {
    let member = container.members[memberIndex]
    let isLast = memberIndex == container.members.count - 1
    let hasPrev = memberIndex > 0

    // If we're removing the last child and there's a previous sibling with a
    // trailing comma, also remove that comma so the file stays valid.
    if isLast, hasPrev, let prevComma = container.members[memberIndex - 1].trailingComma {
      let lower = prevComma.lowerBound
      let upper = member.fullRange.upperBound
      return TextEdit(range: lower..<upper, replacement: "")
    }

    return TextEdit(range: member.fullRange, replacement: "")
  }

  // MARK: - Insertion

  private static func insertTarget(forQualifiedKey key: String) -> InsertTarget {
    let parts = key.split(separator: ".", maxSplits: 1).map(String.init)
    return parts.count == 2 ? .group(parts[0]) : .root
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
          insertion(into: layout, source: source, items: items, indent: rootChildIndent(layout))
        )

      case .group(let groupName):
        if let groupMember = layout.members.first(where: { $0.key == groupName }),
          let nested = groupMember.nested
        {
          edits.append(
            insertion(
              into: nested,
              source: source,
              items: items,
              indent: groupChildIndent(nested, fallbackParentIndent: groupMember.indent)
            )
          )
        } else {
          // Group does not yet exist — create it as a new root member with
          // these items as its children.
          edits.append(
            createGroupEdit(
              groupName: groupName,
              items: items,
              source: source,
              layout: layout
            )
          )
        }
      }
    }

    return edits
  }

  /// Insertion edit for adding `items` at the end of an existing object.
  private static func insertion(
    into container: JSON5Scanner.ObjectLayout,
    source: String,
    items: [(qualifiedKey: String, value: JSONValue)],
    indent: String
  ) -> TextEdit {
    var insert = ""

    if container.members.isEmpty {
      // Open and close braces are on the same logical site; emit children
      // on their own lines using `indent`, with the closing brace de-indented.
      let closeIndent = indentBeforeBrace(closeBrace: container.closeBrace, source: source)
      insert += "\n"
      for (i, item) in items.enumerated() {
        let key = shortKey(forQualifiedKey: item.qualifiedKey)
        insert += "\(indent)\"\(key)\": \(prettyValue(item.value, indent: indent))"
        if i < items.count - 1 { insert += "," }
        insert += "\n"
      }
      insert += closeIndent
      return TextEdit(range: container.closeBrace..<container.closeBrace, replacement: insert)
    }

    // Append after the existing last member's `fullRange`. The last member
    // may or may not already have a trailing comma; we add one if missing.
    let lastIndex = container.members.count - 1
    let last = container.members[lastIndex]
    let needsLeadingComma = last.trailingComma == nil

    if needsLeadingComma {
      // The previous last child has no trailing comma; we need to add one
      // before our new entries. A single text edit covers the splice: it
      // spans from just-after-the-value to just-before-the-close-brace,
      // replacing the original whitespace between them with `,` + the
      // original whitespace + the new items.
      var itemsText = ""
      for item in items {
        let key = shortKey(forQualifiedKey: item.qualifiedKey)
        itemsText += "\(indent)\"\(key)\": \(prettyValue(item.value, indent: indent)),\n"
      }
      // Drop the trailing `,\n` on the very last item so the file ends up
      // without a trailing comma — matching the pre-existing style.
      if itemsText.hasSuffix(",\n") {
        itemsText.removeLast(2)
        itemsText += "\n"
      }
      let from = last.valueRange.upperBound
      let to = container.closeBrace
      let between = String(source[from..<to])
      return TextEdit(range: from..<to, replacement: "," + between + itemsText)
    }

    var itemsText = ""
    for item in items {
      let key = shortKey(forQualifiedKey: item.qualifiedKey)
      itemsText += "\(indent)\"\(key)\": \(prettyValue(item.value, indent: indent)),\n"
    }
    // Last item should not carry a trailing `,` if the original last child
    // also had no trailing comma. But here we know `last.trailingComma != nil`,
    // i.e. the existing last child already ends in `,`. So the new last item
    // also ends without trailing comma to match the original style of the
    // previous last child... Actually, the existing last child's comma is
    // *what we're appending after*, so our items are now interior; trailing
    // comma policy for the new very-last item: drop it.
    if itemsText.hasSuffix(",\n") {
      itemsText.removeLast(2)
      itemsText += "\n"
    }
    return TextEdit(
      range: container.closeBrace..<container.closeBrace,
      replacement: itemsText
    )
  }

  /// Edit that creates a brand-new group at the end of root and seeds it
  /// with `items` as its children.
  private static func createGroupEdit(
    groupName: String,
    items: [(qualifiedKey: String, value: JSONValue)],
    source: String,
    layout: JSON5Scanner.ObjectLayout
  ) -> TextEdit {
    let childIndent = rootChildIndent(layout)
    let groupIndent = childIndent
    let innerIndent = childIndent + childIndent  // one extra step for nested

    var body = ""
    body += "\"\(groupName)\": {\n"
    for (i, item) in items.enumerated() {
      let key = shortKey(forQualifiedKey: item.qualifiedKey)
      body += "\(innerIndent)\"\(key)\": \(prettyValue(item.value, indent: innerIndent))"
      if i < items.count - 1 { body += "," }
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

  /// Indent used by direct children of the root object. Inferred from the
  /// first existing child; falls back to two spaces when the file is empty.
  private static func rootChildIndent(_ layout: JSON5Scanner.ObjectLayout) -> String {
    if let first = layout.members.first { return String(first.indent) }
    return "  "
  }

  /// Indent used by children of a group object. Inferred from the first
  /// existing child; falls back to the parent group's indent + 2 spaces.
  private static func groupChildIndent(
    _ container: JSON5Scanner.ObjectLayout,
    fallbackParentIndent: Substring
  ) -> String {
    if let first = container.members.first { return String(first.indent) }
    return String(fallbackParentIndent) + "  "
  }

  /// The leading whitespace on the line containing the closing brace.
  /// Used when inserting the first child into an empty `{}` so the close
  /// brace lines up.
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

  /// Pretty-print a JSON value at the given indentation. Uses the same
  /// length-sorted, compact-small-objects style as `Configuration+Dump`, so
  /// inserted entries match the rest of the file visually.
  private static func prettyValue(_ value: JSONValue, indent: String) -> String {
    let raw = value.serialize(sortBy: .length)
    // Re-indent every line after the first by `indent`.
    var lines = raw.components(separatedBy: "\n")
    for i in 1..<lines.count {
      lines[i] = indent + lines[i]
    }
    let reindented = lines.joined(separator: "\n")
    return compactSmallObjectsForInsertion(reindented)
  }

  /// Mirrors `Configuration+Dump.compactSmallObjects` for a single inserted
  /// value: collapse small scalar-only objects onto a single line when they
  /// fit within 100 columns.
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
        while j < lines.count && depth > 0 {
          let inner = lines[j].trimmingCharacters(in: .whitespaces)
          if inner.contains("{") { depth += 1; hasNested = true }
          if inner.contains("}") { depth -= 1 }
          objectLines.append(lines[j])
          j += 1
        }
        if !hasNested && depth == 0 {
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
      let clean = trimmed.hasSuffix(",") ? String(trimmed.dropLast()) : trimmed
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
    let parts = key.split(separator: ".", maxSplits: 1).map(String.init)
    if parts.count == 2 {
      if case .object(let groupDict) = defaults[parts[0]] {
        return groupDict[parts[1]] ?? .object([:])
      }
    } else if let value = defaults[key] {
      return value
    }
    return .object([:])
  }

  private static func shortKey(forQualifiedKey key: String) -> String {
    let parts = key.split(separator: ".", maxSplits: 1).map(String.init)
    return parts.count == 2 ? parts[1] : key
  }
}
