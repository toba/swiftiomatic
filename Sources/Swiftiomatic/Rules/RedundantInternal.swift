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

/// Remove explicit `internal` access modifier since it is the default.
///
/// The `internal` access level is the default for all declarations in Swift.
/// Writing it explicitly is redundant noise.
///
/// This rule does NOT remove `internal(set)`, which is meaningful on properties with a higher
/// getter access level (e.g. `public internal(set) var`).
///
/// Lint: If an explicit `internal` modifier is found, a lint warning is raised.
///
/// Format: The redundant `internal` modifier is removed.
@_spi(Rules)
public final class RedundantInternal: SyntaxFormatRule {

  public override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ActorDeclSyntax.self)
    return DeclSyntax(removeRedundantInternal(from: visited, keywordKeyPath: \.actorKeyword))
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ClassDeclSyntax.self)
    return DeclSyntax(removeRedundantInternal(from: visited, keywordKeyPath: \.classKeyword))
  }

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(EnumDeclSyntax.self)
    return DeclSyntax(removeRedundantInternal(from: visited, keywordKeyPath: \.enumKeyword))
  }

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    return DeclSyntax(removeRedundantInternal(from: node, keywordKeyPath: \.funcKeyword))
  }

  public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    return DeclSyntax(removeRedundantInternal(from: node, keywordKeyPath: \.initKeyword))
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ProtocolDeclSyntax.self)
    return DeclSyntax(removeRedundantInternal(from: visited, keywordKeyPath: \.protocolKeyword))
  }

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(StructDeclSyntax.self)
    return DeclSyntax(removeRedundantInternal(from: visited, keywordKeyPath: \.structKeyword))
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    return DeclSyntax(removeRedundantInternal(from: node, keywordKeyPath: \.subscriptKeyword))
  }

  public override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
    return DeclSyntax(removeRedundantInternal(from: node, keywordKeyPath: \.typealiasKeyword))
  }

  public override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    return DeclSyntax(removeRedundantInternal(from: node, keywordKeyPath: \.bindingSpecifier))
  }

  /// Removes a redundant `internal` modifier from the given declaration, if present.
  ///
  /// `internal(set)` is preserved because it is meaningful as a setter access restriction.
  private func removeRedundantInternal<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    from decl: Decl,
    keywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
  ) -> Decl {
    guard let internalModifier = decl.modifiers.accessLevelModifier,
      internalModifier.name.tokenKind == .keyword(.internal),
      internalModifier.detail == nil  // skip `internal(set)`
    else {
      return decl
    }

    diagnose(.removeRedundantInternal, on: internalModifier.name)

    var result = decl
    result.modifiers.remove(anyOf: [.internal])

    // Transfer the leading trivia from the removed modifier to the next token
    // (either the next modifier or the declaration keyword).
    if result.modifiers.first != nil {
      result.modifiers[result.modifiers.startIndex].leadingTrivia =
        internalModifier.leadingTrivia
    } else {
      result[keyPath: keywordKeyPath].leadingTrivia = internalModifier.leadingTrivia
    }

    return result
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantInternal: Finding.Message =
    "remove redundant 'internal' access modifier"
}
