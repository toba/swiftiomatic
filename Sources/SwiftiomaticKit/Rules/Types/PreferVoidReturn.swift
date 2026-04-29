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

/// Return `Void`, not `()`, in signatures.
///
/// Note that this rule does *not* apply to function declaration signatures in order to avoid
/// conflicting with `NoVoidReturnOnFunctionSignature`.
///
/// Lint: Returning `()` in a signature yields a lint error.
///
/// Rewrite: `-> ()` is replaced with `-> Void`
final class PreferVoidReturn: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .types }

  // MARK: - Compact pipeline (willEnter diagnoses on the pre-traversal node so
  // finding source locations come from the original tree, not the post-rewrite
  // detached subtree). The merged `rewriteFunctionType` /
  // `rewriteClosureSignature` only performs the rewrite — they no longer
  // diagnose.

  static func willEnter(_ node: FunctionTypeSyntax, context: Context) {
    guard let returnType = node.returnClause.type.as(TupleTypeSyntax.self),
      returnType.elements.isEmpty
    else { return }
    Self.diagnose(.returnVoid, on: returnType, context: context)
  }

  static func willEnter(_ node: ClosureSignatureSyntax, context: Context) {
    guard let returnClause = node.returnClause,
      let returnType = returnClause.type.as(TupleTypeSyntax.self),
      returnType.elements.isEmpty
    else { return }
    Self.diagnose(.returnVoid, on: returnType, context: context)
  }
}

extension Finding.Message {
  fileprivate static let returnVoid: Finding.Message = "replace '()' with 'Void'"
}
