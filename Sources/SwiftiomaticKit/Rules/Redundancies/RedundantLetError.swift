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
/// In a `catch` clause without a pattern, the caught error is implicitly available as `error` .
/// Writing `catch let error` is therefore redundant.
///
/// This rule only fires when the catch item is exactly `let error` (no type cast, no where clause,
/// and no other catch items in the same clause).
///
/// Lint: If `catch let error` is found, a lint warning is raised.
///
/// Rewrite: The redundant `let error` pattern is removed.
final class RedundantLetError: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    static func transform(
        _ node: CatchClauseSyntax,
        original _: CatchClauseSyntax,
        parent _: Syntax?,
        context: Context
    ) -> CatchClauseSyntax {
        // Must have exactly one catch item.
        guard node.catchItems.count == 1, let catchItem = node.catchItems.first else { return node }

        // Must have no where clause.
        guard catchItem.whereClause == nil else { return node }

        // Pattern must be `let error` .
        guard let pattern = catchItem.pattern,
              let valueBinding = pattern.as(ValueBindingPatternSyntax.self),
              valueBinding.bindingSpecifier.tokenKind == .keyword(.let),
              let identifier = valueBinding.pattern.as(IdentifierPatternSyntax.self),
              identifier.identifier.text == "error" else { return node }

        Self.diagnose(.removeRedundantLetError, on: pattern, context: context)

        // Remove the catch items, leaving a bare `catch { ... }` .
        var newNode = node
        newNode.catchItems = CatchItemListSyntax([])
        // The catch keyword already has trailing trivia (space), so `catch {` is correct.
        return newNode
    }
}

fileprivate extension Finding.Message {
    static let removeRedundantLetError: Finding.Message =
        "remove redundant 'let error' from catch clause; 'error' is implicitly available"
}
