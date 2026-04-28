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

/// Remove `= nil` from optional `var` declarations where `nil` is the default.
///
/// Optional `var` properties and local variables default to `nil` without an explicit initializer.
/// Writing `= nil` is redundant.
///
/// This rule only applies to `var` declarations with an explicit optional type annotation
/// (e.g. `T?`, `Optional<T>`). It does not apply to `let` declarations, or to `var`
/// declarations inside protocols (where there is no stored property).
///
/// Lint: If `= nil` is found on an eligible optional `var`, a lint warning is raised.
///
/// Rewrite: The redundant `= nil` initializer is removed.
final class RedundantNilInit: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
  override class var group: ConfigurationGroup? { .redundancies }

  override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    Self.transform(node, parent: Syntax(node).parent, context: context)
  }

  static func transform(
    _ node: VariableDeclSyntax,
    parent: Syntax?,
    context: Context
  ) -> DeclSyntax {
    // Only applies to `var`, not `let`.
    guard node.bindingSpecifier.tokenKind == .keyword(.var) else {
      return DeclSyntax(node)
    }

    // Don't apply inside protocol declarations — those are requirements, not stored properties.
    // Walk the captured parent chain (post-recursion node.parent is nil).
    if parent?.parent?.is(ProtocolDeclSyntax.self) == true {
      return DeclSyntax(node)
    }

    var bindings = node.bindings
    var didChange = false

    for (index, binding) in bindings.enumerated() {
      guard let initializer = binding.initializer,
        isNilLiteral(initializer.value),
        isOptionalType(binding.typeAnnotation?.type)
      else {
        continue
      }

      Self.diagnose(.removeRedundantNilInit, on: initializer, context: context)

      // Remove the initializer clause and clean up trivia. The type annotation's last token
      // has trailing trivia (typically a space before `=`) that is no longer needed.
      var newBinding = binding
      newBinding.initializer = nil

      if var typeAnnotation = newBinding.typeAnnotation {
        typeAnnotation.trailingTrivia = initializer.value.trailingTrivia
        newBinding.typeAnnotation = typeAnnotation
      }

      bindings = bindings.with(\.[bindings.index(bindings.startIndex, offsetBy: index)], newBinding)
      didChange = true
    }

    guard didChange else { return DeclSyntax(node) }

    var newNode = node
    newNode.bindings = bindings
    return DeclSyntax(newNode)
  }

  /// Returns `true` if the expression is a `nil` literal.
  private static func isNilLiteral(_ expr: ExprSyntax) -> Bool {
    expr.is(NilLiteralExprSyntax.self)
  }

  /// Returns `true` if the type is explicitly optional (`T?` or `Optional<T>`).
  private static func isOptionalType(_ type: TypeSyntax?) -> Bool {
    guard let type else { return false }

    // `T?` syntax
    if type.is(OptionalTypeSyntax.self) {
      return true
    }

    // `T??`, etc.
    if type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
      return true
    }

    // `Optional<T>` syntax
    if let identifierType = type.as(IdentifierTypeSyntax.self),
      identifierType.name.text == "Optional",
      identifierType.genericArgumentClause != nil
    {
      return true
    }

    return false
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantNilInit: Finding.Message =
    "remove redundant '= nil' initializer"
}
