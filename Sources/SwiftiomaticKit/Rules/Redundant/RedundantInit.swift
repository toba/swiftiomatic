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

/// Remove explicit `.init` when calling a type initializer directly.
///
/// `Foo.init(args)` can be written as `Foo(args)` when the type is explicit.
/// The `.init` is only necessary when the type is inferred (e.g. `.init(args)`).
///
/// This rule only fires when `init` is called on a named base expression (not on `.init()`
/// shorthand, method chains, or subscripts).
///
/// Lint: If an explicit `.init` is found on a direct type reference, a lint warning is raised.
///
/// Format: The `.init` member access is removed, leaving the type called directly.
final class RedundantInit: SyntaxFormatRule {
  static let group: ConfigGroup? = .redundancies

  override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
      memberAccess.declName.baseName.tokenKind == .keyword(.`init`),
      memberAccess.declName.argumentNames == nil,
      let base = memberAccess.base
    else {
      return super.visit(node)
    }

    // Only fire when the base is a simple type reference or another member access (e.g. `Module.Type`),
    // not when it's `.init()` (no base) which is shorthand inference syntax.
    // Also skip if the base is a function call (e.g. `foo().init()`) — unusual but not redundant.
    guard !base.is(FunctionCallExprSyntax.self) else {
      return super.visit(node)
    }

    diagnose(.removeRedundantInit, on: memberAccess.period)

    // Replace `Foo.init(args)` with `Foo(args)`.
    // Transfer the trailing trivia from `init` (typically empty) and preserve the base's trivia.
    var newNode = node
    var newBase = base
    newBase.trailingTrivia = memberAccess.declName.baseName.trailingTrivia
    newNode.calledExpression = ExprSyntax(newBase)
    return ExprSyntax(newNode)
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantInit: Finding.Message =
    "remove explicit '.init'; call the type directly"
}
