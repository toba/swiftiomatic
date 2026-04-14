//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Sort switch case items alphabetically within each case.
///
/// When a case matches multiple patterns (e.g. `case .b, .a, .c:`), the patterns are sorted
/// lexicographically. Numeric literals are compared by value (including hex, octal, and binary).
/// Cases with `where` clauses are only sorted if the `where` clause ends up on the last item.
///
/// Lint: If case items are not sorted, a lint warning is raised.
///
/// Format: The case items are reordered alphabetically.
@_spi(Rules)
public final class SortSwitchCases: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
    guard case .case(var caseLabel) = node.label else { return node }
    let items = Array(caseLabel.caseItems)
    guard items.count > 1 else { return node }

    // Sort by pattern sort keys
    let sorted = items.sorted { lhs, rhs in
      let lhsKeys = sortKeys(for: lhs.pattern)
      let rhsKeys = sortKeys(for: rhs.pattern)
      for (l, r) in zip(lhsKeys, rhsKeys) {
        let cmp = l.localizedStandardCompare(r)
        if cmp != .orderedSame { return cmp == .orderedAscending }
      }
      return lhsKeys.count < rhsKeys.count
    }

    // If where clause ended up on non-last item after sorting, bail
    for (i, item) in sorted.enumerated() {
      if item.whereClause != nil, i < sorted.count - 1 {
        return node
      }
    }

    // Check if already sorted
    let originalKeys = items.map { sortKeys(for: $0.pattern) }
    let sortedKeys = sorted.map { sortKeys(for: $0.pattern) }
    guard originalKeys != sortedKeys else { return node }

    diagnose(.sortSwitchCases, on: caseLabel.caseKeyword)

    // Rebuild items preserving positional trivia, moving comments with their patterns
    var newItems = [SwitchCaseItemSyntax]()
    for (i, sortedItem) in sorted.enumerated() {
      var newItem = sortedItem
      // Apply leading trivia from the original position
      newItem.leadingTrivia = items[i].leadingTrivia

      if i < sorted.count - 1 {
        // Non-last: ensure comma, preserve sorted item's trailing comment if it had one
        let trailingTrivia: Trivia
        if let comma = sortedItem.trailingComma {
          trailingTrivia = comma.trailingTrivia
        } else {
          // Item was previously last (no comma) — use trivia from original position's comma
          trailingTrivia = items[i].trailingComma?.trailingTrivia ?? .space
        }
        newItem.trailingComma = .commaToken(trailingTrivia: trailingTrivia)
      } else {
        // Last item: transfer any trailing comment to the colon
        if let comma = sortedItem.trailingComma,
          comma.trailingTrivia.contains(where: { $0.isComment })
        {
          caseLabel.colon = caseLabel.colon.with(\.trailingTrivia, comma.trailingTrivia)
        }
        newItem.trailingComma = nil
      }
      newItems.append(newItem)
    }

    caseLabel.caseItems = SwitchCaseItemListSyntax(newItems)
    var result = node
    result.label = .case(caseLabel)
    return result
  }

  // MARK: - Sort Key Extraction

  /// Extract sortable string keys from a pattern's tokens.
  private func sortKeys(for pattern: PatternSyntax) -> [String] {
    var parts = [String]()
    for token in pattern.tokens(viewMode: .sourceAccurate) {
      switch token.tokenKind {
      case .identifier(let name):
        parts.append(name)
      case .stringSegment(let text):
        parts.append(text)
      case .integerLiteral(let value):
        parts.append(normalizeNumericLiteral(value))
      case .keyword:
        // Include keyword text for tuple/pattern ordering
        parts.append(token.text)
      case .wildcard:
        parts.append("_")
      default:
        break
      }
    }
    return parts
  }

  /// Normalize hex, octal, and binary literals to decimal strings for comparison.
  private func normalizeNumericLiteral(_ value: String) -> String {
    let stripped = value.filter { $0 != "_" }
    if stripped.hasPrefix("0x"), let n = Int(stripped.dropFirst(2), radix: 16) {
      return String(n)
    }
    if stripped.hasPrefix("0o"), let n = Int(stripped.dropFirst(2), radix: 8) {
      return String(n)
    }
    if stripped.hasPrefix("0b"), let n = Int(stripped.dropFirst(2), radix: 2) {
      return String(n)
    }
    return stripped
  }
}

extension Finding.Message {
  fileprivate static let sortSwitchCases: Finding.Message =
    "sort switch case items alphabetically"
}
