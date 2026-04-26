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

/// Use shorthand optional binding `if let x` instead of `if let x = x` (SE-0345).
///
/// When an optional binding's initializer is a bare identifier matching the pattern name,
/// the initializer is redundant and can be removed using Swift 5.7+ shorthand syntax.
///
/// This applies to `if let`, `guard let`, and `while let` bindings.
///
/// Lint: If a redundant optional binding initializer is found, a lint warning is raised.
///
/// Rewrite: The redundant initializer is removed.
final class RedundantOptionalBinding: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
  override class var group: ConfigurationGroup? { .redundancies }

  override func visit(_ node: OptionalBindingConditionSyntax) -> OptionalBindingConditionSyntax {
    guard let initializer = node.initializer,
      let identifierPattern = node.pattern.as(IdentifierPatternSyntax.self),
      let declRef = initializer.value.as(DeclReferenceExprSyntax.self),
      declRef.argumentNames == nil,
      identifierPattern.identifier.text == declRef.baseName.text,
      node.typeAnnotation == nil
    else {
      return node
    }

    diagnose(.removeRedundantOptionalBinding(name: identifierPattern.identifier.text), on: initializer)

    var result = node
    result.initializer = nil
    // Clean up trailing trivia: the pattern identifier had trailing trivia (space before `=`).
    // Replace with the initializer value's trailing trivia.
    result.pattern = PatternSyntax(
      identifierPattern.with(\.identifier.trailingTrivia, initializer.value.trailingTrivia)
    )

    return result
  }
}

extension Finding.Message {
  fileprivate static func removeRedundantOptionalBinding(name: String) -> Finding.Message {
    "use shorthand syntax 'let \(name)' instead of 'let \(name) = \(name)'"
  }
}
