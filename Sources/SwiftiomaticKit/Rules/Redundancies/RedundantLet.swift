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

/// Remove redundant `let`/`var` from wildcard patterns.
///
/// At statement level, `let _ = expr` can be simplified to `_ = expr` since the `let` keyword
/// is unnecessary when the result is discarded.
///
/// In case patterns, `if case .foo(let _)` can be simplified to `if case .foo(_)` since the
/// `let` binding of a wildcard is redundant.
///
/// The rule skips result builder contexts (SwiftUI view builders, `#Preview`, etc.) where
/// `let _ = expr` is required because `_ = expr` is not valid in a result builder body.
///
/// The rule also skips declarations with attributes (`@MainActor let _ = ...`) since the
/// attribute requires a declaration to attach to.
///
/// Lint: A finding is emitted when a redundant `let` or `var` is found.
///
/// Rewrite: The redundant `let`/`var` keyword is removed.
final class RedundantLet: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
  override class var group: ConfigurationGroup? { .redundancies }

  // MARK: - Statement-level: let _ = expr → _ = expr

  static func transform(
    _ visited: CodeBlockItemListSyntax,
    parent: Syntax?,
    context: Context
  ) -> CodeBlockItemListSyntax {
    guard !isLikelyResultBuilderContext(parent: parent) else { return visited }

    var newItems = [CodeBlockItemSyntax]()
    var changed = false

    for item in visited {
      guard let varDecl = item.item.as(VariableDeclSyntax.self),
            isRedundantLetDecl(varDecl),
            let binding = varDecl.bindings.first,
            let initializer = binding.initializer
      else {
        newItems.append(item)
        continue
      }

      Self.diagnose(.removeRedundantLet, on: varDecl.bindingSpecifier, context: context)
      changed = true

      // Build: _ = expr
      let discardExpr = DiscardAssignmentExprSyntax(
        wildcard: .wildcardToken(
          leadingTrivia: varDecl.leadingTrivia,
          trailingTrivia: binding.pattern.trailingTrivia
        )
      )
      let infixExpr = InfixOperatorExprSyntax(
        leftOperand: ExprSyntax(discardExpr),
        operator: ExprSyntax(AssignmentExprSyntax(equal: initializer.equal)),
        rightOperand: initializer.value
      )
      var newItem = CodeBlockItemSyntax(item: .expr(ExprSyntax(infixExpr)))
      newItem.trailingTrivia = item.trailingTrivia
      newItems.append(newItem)
    }

    guard changed else { return visited }
    return CodeBlockItemListSyntax(newItems)
  }

  /// Whether a `VariableDeclSyntax` is a redundant `let _ = expr`.
  private static func isRedundantLetDecl(_ node: VariableDeclSyntax) -> Bool {
    // Only `let`, not `var`.
    guard node.bindingSpecifier.tokenKind == .keyword(.let) else { return false }

    // Not `async let`.
    guard !node.modifiers.contains(.async) else {
      return false
    }

    // Not when attributes are present (`@MainActor let _ = ...`, `@Sendable let _ = ...`).
    // Attributes require a declaration to attach to; removing `let` would leave `_ = expr`
    // which cannot carry attributes.
    guard node.attributes.isEmpty else { return false }

    // Must have exactly one binding.
    guard node.bindings.count == 1, let binding = node.bindings.first else { return false }

    // The pattern must be the wildcard `_`.
    guard binding.pattern.is(WildcardPatternSyntax.self) else { return false }

    // Must not have a type annotation (e.g., `let _: String = ...` is intentional).
    guard binding.typeAnnotation == nil else { return false }

    // Must have an initializer.
    guard binding.initializer != nil else { return false }

    return true
  }

  // MARK: - Result builder detection

  /// Crude heuristic: returns true if the code block is likely inside a result builder context.
  /// Walks up the captured pre-recursion parent chain looking for closures whose call site
  /// suggests a result builder (uppercase function name like `HStack { }`, macro expansions like
  /// `#Preview { }`).
  private static func isLikelyResultBuilderContext(parent: Syntax?) -> Bool {
    var current = parent

    while let p = current {
      // Closure body → check the call site
      if let closure = p.as(ClosureExprSyntax.self) {
        return isResultBuilderClosure(closure)
      }
      // Accessor body on a property → check for @ViewBuilder or `some View` return type
      if let accessor = p.as(AccessorDeclSyntax.self),
         isResultBuilderAccessor(accessor)
      {
        return true
      }
      // Stop at type/extension boundaries — not a result builder context
      if p.is(ClassDeclSyntax.self) || p.is(StructDeclSyntax.self)
        || p.is(EnumDeclSyntax.self) || p.is(ActorDeclSyntax.self)
        || p.is(ExtensionDeclSyntax.self) || p.is(ProtocolDeclSyntax.self)
      {
        return false
      }
      // Stop at function declarations (non-accessor)
      if p.is(FunctionDeclSyntax.self) {
        return false
      }
      current = p.parent
    }
    return false
  }

  /// Whether a closure appears to be a result builder argument (e.g., `HStack { ... }`,
  /// `#Preview { ... }`).
  private static func isResultBuilderClosure(_ closure: ClosureExprSyntax) -> Bool {
    guard let parent = closure.parent else { return false }

    // Trailing closure on a function call: `SomeName { ... }`
    if let call = parent.as(FunctionCallExprSyntax.self) {
      if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
        return memberAccess.declName.baseName.text.first?.isUppercase == true
      }
      if let ident = call.calledExpression.as(DeclReferenceExprSyntax.self) {
        return ident.baseName.text.first?.isUppercase == true
      }
    }

    // Labeled trailing closure argument: `VStack { }.overlay { ... }`
    if parent.is(MultipleTrailingClosureElementSyntax.self) {
      return true
    }

    // Labeled argument: `.overlay(content: { ... })`
    if let arg = parent.as(LabeledExprSyntax.self),
       arg.parent?.parent?.is(FunctionCallExprSyntax.self) == true
    {
      // Conservative: any closure passed as argument could be a result builder
      if let call = arg.parent?.parent?.as(FunctionCallExprSyntax.self),
         let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self),
         memberAccess.declName.baseName.text.first?.isUppercase == true
      {
        return true
      }
    }

    // Macro expansion: `#Preview { ... }`
    if parent.is(MacroExpansionExprSyntax.self) || parent.is(MacroExpansionDeclSyntax.self) {
      return true
    }

    return false
  }

  /// Whether an accessor is in a result builder context (e.g., `@ViewBuilder var body: some View`).
  private static func isResultBuilderAccessor(_ accessor: AccessorDeclSyntax) -> Bool {
    guard let accessorBlock = accessor.parent?.as(AccessorBlockSyntax.self),
          let property = accessorBlock.parent?.as(VariableDeclSyntax.self)
    else { return false }

    // Check for @ViewBuilder or other result builder attributes on the property
    for attribute in property.attributes {
      if let attr = attribute.as(AttributeSyntax.self),
         let name = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
         name.hasSuffix("Builder") || name == "ViewBuilder"
      {
        return true
      }
    }

    // Check for `some View` return type
    if let binding = property.bindings.first,
       let typeAnnotation = binding.typeAnnotation,
       let someType = typeAnnotation.type.as(SomeOrAnyTypeSyntax.self),
       someType.constraint.description.contains("View")
    {
      return true
    }

    return false
  }

  // MARK: - Case patterns: if case .foo(let _) → if case .foo(_)

  static func transform(
    _ node: LabeledExprSyntax,
    parent: Syntax?,
    context: Context
  ) -> LabeledExprSyntax {
    // In case patterns like `case .foo(let _)`, the AST has:
    //   LabeledExprSyntax → PatternExprSyntax → ValueBindingPatternSyntax(let, WildcardPatternSyntax)
    // The `let`/`var` is redundant when the inner pattern is just `_`.
    //
    // Note: after child-first rewriter traversal, `WildcardPatternSyntax` type checks can fail
    // on the reconstructed node. Use `trimmedDescription == "_"` as a robust check.
    guard let patExpr = node.expression.as(PatternExprSyntax.self),
          let binding = patExpr.pattern.as(ValueBindingPatternSyntax.self),
          binding.pattern.trimmedDescription == "_"
    else {
      return node
    }

    Self.diagnose(.removeRedundantLetInCasePattern, on: binding.bindingSpecifier, context: context)

    // Replace the pattern inside PatternExprSyntax with just the wildcard.
    var wildcard = binding.pattern
    let specifierTrivia = binding.bindingSpecifier.leadingTrivia
    let commentTrivia = binding.bindingSpecifier.trailingTrivia.withoutLeadingSpaces()
    wildcard.leadingTrivia = specifierTrivia + commentTrivia + wildcard.leadingTrivia
    var newPatExpr = patExpr
    newPatExpr.pattern = wildcard
    var result = node
    result.expression = ExprSyntax(newPatExpr)
    return result
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantLet: Finding.Message =
    "remove 'let' from 'let _ = ...'; use '_ = ...' instead"

  fileprivate static let removeRedundantLetInCasePattern: Finding.Message =
    "remove redundant 'let' from wildcard pattern; use '_' instead"
}
