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

/// Remove `let` from `let _ = expr` since `_ = expr` is equivalent and shorter.
///
/// When a variable binding uses the wildcard pattern `_`, the `let` keyword is unnecessary.
/// The assignment `_ = expr` discards the result identically.
///
/// This rule only applies to top-level `let _ = expr` bindings, not to wildcard patterns
/// inside `switch` cases, `if case`, or tuple destructuring where other bindings are present.
///
/// Lint: If `let _ = expr` is found at statement level, a lint warning is raised.
///
/// Format: The `let` keyword is removed, producing `_ = expr`.
@_spi(Rules)
public final class RedundantLet: SyntaxLintRule {

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    // Only `let`, not `var`.
    guard node.bindingSpecifier.tokenKind == .keyword(.let) else {
      return .visitChildren
    }

    // Must have exactly one binding.
    guard node.bindings.count == 1, let binding = node.bindings.first else {
      return .visitChildren
    }

    // The pattern must be the wildcard `_`.
    guard binding.pattern.is(WildcardPatternSyntax.self) else {
      return .visitChildren
    }

    // Must have an initializer (otherwise it's `let _` with no value, which is invalid anyway).
    guard binding.initializer != nil else {
      return .visitChildren
    }

    diagnose(.removeRedundantLet, on: node.bindingSpecifier)
    return .visitChildren
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantLet: Finding.Message =
    "remove 'let' from 'let _ = ...'; use '_ = ...' instead"
}
