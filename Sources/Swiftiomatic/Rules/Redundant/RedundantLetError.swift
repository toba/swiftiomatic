//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Remove `let error` from `catch` clauses where `error` is implicitly bound.
///
/// In a `catch` clause without a pattern, the caught error is implicitly available as `error`.
/// Writing `catch let error` is therefore redundant.
///
/// This rule only fires when the catch item is exactly `let error` (no type cast, no where clause,
/// and no other catch items in the same clause).
///
/// Lint: If `catch let error` is found, a lint warning is raised.
///
/// Format: The redundant `let error` pattern is removed.
final class RedundantLetError: SyntaxFormatRule {
  static let group: ConfigGroup? = .redundancies

  override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
    // Must have exactly one catch item.
    guard node.catchItems.count == 1, let catchItem = node.catchItems.first else {
      return super.visit(node)
    }

    // Must have no where clause.
    guard catchItem.whereClause == nil else {
      return super.visit(node)
    }

    // Pattern must be `let error`.
    guard let pattern = catchItem.pattern,
      let valueBinding = pattern.as(ValueBindingPatternSyntax.self),
      valueBinding.bindingSpecifier.tokenKind == .keyword(.let),
      let identifier = valueBinding.pattern.as(IdentifierPatternSyntax.self),
      identifier.identifier.text == "error"
    else {
      return super.visit(node)
    }

    diagnose(.removeRedundantLetError, on: pattern)

    // Remove the catch items, leaving a bare `catch { ... }`.
    var newNode = node
    newNode.catchItems = CatchItemListSyntax([])
    // The catch keyword already has trailing trivia (space), so `catch {` is correct.
    return newNode
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantLetError: Finding.Message =
    "remove redundant 'let error' from catch clause; 'error' is implicitly available"
}
