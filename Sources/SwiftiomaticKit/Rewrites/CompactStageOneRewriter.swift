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

// sm:ignore-file: fileLength, typeBodyLength, functionBodyLength

import SwiftSyntax

/// The combined node-local rewrite stage for the `compact` style. Each `visit(_:)`
/// override defers to `super.visit` to recurse children, then applies every rule
/// that opted into `static func transform(_:context:)` for that node type.
///
/// Rules are dispatched in alphabetical order by type name; same-node-type
/// interactions should be expressed via `MustRunAfter` (future) or by composing
/// transforms inside a single rule.
final class CompactStageOneRewriter: SyntaxRewriter {

    let context: Context

    init(context: Context) {
        self.context = context
        super.init()
    }

  override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result = rewriteAccessorBlock(visited, parent: parent, context: context)
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(AccessorDeclSyntax.self) {
      result = DeclSyntax(rewriteAccessorDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(PreferSelfType.self, node: Syntax(node)) {
      PreferSelfType.willEnter(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(ActorDeclSyntax.self) {
      result = DeclSyntax(rewriteActorDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(PreferSelfType.self, node: Syntax(node)) {
      PreferSelfType.didExit(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: AsExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(AsExprSyntax.self) {
      result = ExprSyntax(rewriteAsExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: AssociatedTypeDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    var current: DeclSyntax = super.visit(node)
    if let concrete = current.as(AssociatedTypeDeclSyntax.self) {
      if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(concrete)) {
        current = ModifiersOnSameLine.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "ModifiersOnSameLine: preceding rule widened AssociatedTypeDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    return current
  }

  override func visit(_ node: AttributeSyntax) -> AttributeSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(PreferMainAttribute.self, node: Syntax(node)) {
      node = PreferMainAttribute.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: AttributedTypeSyntax) -> TypeSyntax {
    let parent = Syntax(node).parent
    var current: TypeSyntax = super.visit(node)
    if let concrete = current.as(AttributedTypeSyntax.self) {
      if context.shouldFormat(NoExplicitOwnership.self, node: Syntax(concrete)) {
        current = NoExplicitOwnership.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "NoExplicitOwnership: preceding rule widened AttributedTypeSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    return current
  }

  override func visit(_ node: AwaitExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(HoistTry.self, node: Syntax(node)) {
      HoistTry.willEnter(node, context: context)
    }
    var current: ExprSyntax = super.visit(node)
    if let concrete = current.as(AwaitExprSyntax.self) {
      if context.shouldFormat(HoistTry.self, node: Syntax(concrete)) {
        current = HoistTry.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "HoistTry: preceding rule widened AwaitExprSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if context.shouldFormat(HoistTry.self, node: Syntax(node)) {
      HoistTry.didExit(node, context: context)
    }
    return current
  }

  override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(RedundantLetError.self, node: Syntax(node)) {
      node = RedundantLetError.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoForceTry.self, node: Syntax(node)) {
      NoForceTry.willEnter(node, context: context)
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    if context.shouldFormat(NoGuardInTests.self, node: Syntax(node)) {
      NoGuardInTests.willEnter(node, context: context)
    }
    if context.shouldFormat(PreferSelfType.self, node: Syntax(node)) {
      PreferSelfType.willEnter(node, context: context)
    }
    if context.shouldFormat(PreferSwiftTesting.self, node: Syntax(node)) {
      PreferSwiftTesting.willEnter(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(ClassDeclSyntax.self) {
      result = DeclSyntax(rewriteClassDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(NoForceTry.self, node: Syntax(node)) {
      NoForceTry.didExit(node, context: context)
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.didExit(node, context: context)
    }
    if context.shouldFormat(NoGuardInTests.self, node: Syntax(node)) {
      NoGuardInTests.didExit(node, context: context)
    }
    if context.shouldFormat(PreferSelfType.self, node: Syntax(node)) {
      PreferSelfType.didExit(node, context: context)
    }
    if context.shouldFormat(PreferSwiftTesting.self, node: Syntax(node)) {
      PreferSwiftTesting.didExit(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NamedClosureParams.self, node: Syntax(node)) {
      NamedClosureParams.willEnter(node, context: context)
    }
    if context.shouldFormat(NoForceTry.self, node: Syntax(node)) {
      NoForceTry.willEnter(node, context: context)
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    if context.shouldFormat(NoGuardInTests.self, node: Syntax(node)) {
      NoGuardInTests.willEnter(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(ClosureExprSyntax.self) {
      result = ExprSyntax(rewriteClosureExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(NamedClosureParams.self, node: Syntax(node)) {
      NamedClosureParams.didExit(node, context: context)
    }
    if context.shouldFormat(NoForceTry.self, node: Syntax(node)) {
      NoForceTry.didExit(node, context: context)
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.didExit(node, context: context)
    }
    if context.shouldFormat(NoGuardInTests.self, node: Syntax(node)) {
      NoGuardInTests.didExit(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(PreferVoidReturn.self, node: Syntax(node)) {
      PreferVoidReturn.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result = rewriteClosureSignature(visited, parent: parent, context: context)
    return result
  }

  override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoSemicolons.self, node: Syntax(node)) {
      NoSemicolons.willEnter(node, context: context)
    }
    if context.shouldFormat(OneDeclarationPerLine.self, node: Syntax(node)) {
      OneDeclarationPerLine.willEnter(node, context: context)
    }
    if context.shouldFormat(PreferEarlyExits.self, node: Syntax(node)) {
      PreferEarlyExits.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result = rewriteCodeBlockItemList(visited, parent: parent, context: context)
    return result
  }

  override func visit(_ node: CodeBlockItemSyntax) -> CodeBlockItemSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(ConvertRegularCommentToDocC.self, node: Syntax(node)) {
      node = ConvertRegularCommentToDocC.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(BlankLinesBeforeControlFlowBlocks.self, node: Syntax(node)) {
      BlankLinesBeforeControlFlowBlocks.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result = rewriteCodeBlock(visited, parent: parent, context: context)
    return result
  }

  override func visit(_ node: ConditionElementListSyntax) -> ConditionElementListSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(PreferCommaConditions.self, node: Syntax(node)) {
      node = PreferCommaConditions.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: ConditionElementSyntax) -> ConditionElementSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(node)) {
      NoParensAroundConditions.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result = rewriteConditionElement(visited, parent: parent, context: context)
    return result
  }

  override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(ACLConsistency.self, node: Syntax(node)) {
      node = ACLConsistency.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(DeclReferenceExprSyntax.self) {
      result = ExprSyntax(rewriteDeclReferenceExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(DeinitializerDeclSyntax.self) {
      result = DeclSyntax(rewriteDeinitializerDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: StmtSyntax
    if let concrete = visited.as(DoStmtSyntax.self) {
      result = StmtSyntax(rewriteDoStmt(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    var current: DeclSyntax = super.visit(node)
    if let concrete = current.as(EnumCaseDeclSyntax.self) {
      if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(concrete)) {
        current = ModifiersOnSameLine.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "ModifiersOnSameLine: preceding rule widened EnumCaseDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if let concrete = current.as(EnumCaseDeclSyntax.self) {
      if context.shouldFormat(RedundantRawValues.self, node: Syntax(concrete)) {
        current = RedundantRawValues.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "RedundantRawValues: preceding rule widened EnumCaseDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    return current
  }

  override func visit(_ node: EnumCaseElementSyntax) -> EnumCaseElementSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(AvoidNoneName.self, node: Syntax(node)) {
      node = AvoidNoneName.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(OneDeclarationPerLine.self, node: Syntax(node)) {
      OneDeclarationPerLine.willEnter(node, context: context)
    }
    if context.shouldFormat(PreferSelfType.self, node: Syntax(node)) {
      PreferSelfType.willEnter(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(EnumDeclSyntax.self) {
      result = DeclSyntax(rewriteEnumDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(PreferSelfType.self, node: Syntax(node)) {
      PreferSelfType.didExit(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(PreferSelfType.self, node: Syntax(node)) {
      PreferSelfType.willEnter(node, context: context)
    }
    if context.shouldFormat(PreferSwiftTesting.self, node: Syntax(node)) {
      PreferSwiftTesting.willEnter(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(ExtensionDeclSyntax.self) {
      result = DeclSyntax(rewriteExtensionDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(PreferSelfType.self, node: Syntax(node)) {
      PreferSelfType.didExit(node, context: context)
    }
    if context.shouldFormat(PreferSwiftTesting.self, node: Syntax(node)) {
      PreferSwiftTesting.didExit(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(WrapSingleLineBodies.self, node: Syntax(node)) {
      WrapSingleLineBodies.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: StmtSyntax
    if let concrete = visited.as(ForStmtSyntax.self) {
      result = StmtSyntax(rewriteForStmt(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(WrapSingleLineBodies.self, node: Syntax(node)) {
      WrapSingleLineBodies.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: ForceUnwrapExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(ForceUnwrapExprSyntax.self) {
      result = ExprSyntax(rewriteForceUnwrapExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    if context.shouldFormat(NoTrailingClosureParens.self, node: Syntax(node)) {
      NoTrailingClosureParens.willEnter(node, context: context)
    }
    if context.shouldFormat(PreferSwiftTesting.self, node: Syntax(node)) {
      PreferSwiftTesting.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(FunctionCallExprSyntax.self) {
      result = ExprSyntax(rewriteFunctionCallExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.didExit(node, context: context)
    }
    if context.shouldFormat(PreferSwiftTesting.self, node: Syntax(node)) {
      PreferSwiftTesting.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoForceTry.self, node: Syntax(node)) {
      NoForceTry.willEnter(node, context: context)
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    if context.shouldFormat(NoGuardInTests.self, node: Syntax(node)) {
      NoGuardInTests.willEnter(node, context: context)
    }
    if context.shouldFormat(PreferSwiftTesting.self, node: Syntax(node)) {
      PreferSwiftTesting.willEnter(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(FunctionDeclSyntax.self) {
      result = DeclSyntax(rewriteFunctionDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(NoForceTry.self, node: Syntax(node)) {
      NoForceTry.didExit(node, context: context)
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.didExit(node, context: context)
    }
    if context.shouldFormat(NoGuardInTests.self, node: Syntax(node)) {
      NoGuardInTests.didExit(node, context: context)
    }
    if context.shouldFormat(PreferSwiftTesting.self, node: Syntax(node)) {
      PreferSwiftTesting.didExit(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: FunctionEffectSpecifiersSyntax) -> FunctionEffectSpecifiersSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(RedundantTypedThrows.self, node: Syntax(node)) {
      node = RedundantTypedThrows.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(EmptyCollectionLiteral.self, node: Syntax(node)) {
      node = EmptyCollectionLiteral.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: FunctionSignatureSyntax) -> FunctionSignatureSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result = rewriteFunctionSignature(visited, parent: parent, context: context)
    return result
  }

  override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(PreferVoidReturn.self, node: Syntax(node)) {
      PreferVoidReturn.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: TypeSyntax
    if let concrete = visited.as(FunctionTypeSyntax.self) {
      result = TypeSyntax(rewriteFunctionType(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: GenericSpecializationExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(PreferShorthandTypeNames.self, node: Syntax(node)) {
      PreferShorthandTypeNames.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(GenericSpecializationExprSyntax.self) {
      result = ExprSyntax(rewriteGenericSpecializationExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(WrapSingleLineBodies.self, node: Syntax(node)) {
      WrapSingleLineBodies.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: StmtSyntax
    if let concrete = visited.as(GuardStmtSyntax.self) {
      result = StmtSyntax(rewriteGuardStmt(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(WrapSingleLineBodies.self, node: Syntax(node)) {
      WrapSingleLineBodies.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(PreferShorthandTypeNames.self, node: Syntax(node)) {
      PreferShorthandTypeNames.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: TypeSyntax
    if let concrete = visited.as(IdentifierTypeSyntax.self) {
      result = TypeSyntax(rewriteIdentifierType(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: IfExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(WrapSingleLineBodies.self, node: Syntax(node)) {
      WrapSingleLineBodies.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(IfExprSyntax.self) {
      result = ExprSyntax(rewriteIfExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(WrapSingleLineBodies.self, node: Syntax(node)) {
      WrapSingleLineBodies.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(ImportDeclSyntax.self) {
      result = DeclSyntax(rewriteImportDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(InfixOperatorExprSyntax.self) {
      result = ExprSyntax(rewriteInfixOperatorExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: InitializerClauseSyntax) -> InitializerClauseSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(node)) {
      NoParensAroundConditions.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result = rewriteInitializerClause(visited, parent: parent, context: context)
    return result
  }

  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(InitializerDeclSyntax.self) {
      result = DeclSyntax(rewriteInitializerDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: IntegerLiteralExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    var current: ExprSyntax = super.visit(node)
    if let concrete = current.as(IntegerLiteralExprSyntax.self) {
      if context.shouldFormat(GroupNumericLiterals.self, node: Syntax(concrete)) {
        current = GroupNumericLiterals.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "GroupNumericLiterals: preceding rule widened IntegerLiteralExprSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    return current
  }

  override func visit(_ node: IsExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(IsExprSyntax.self) {
      result = ExprSyntax(rewriteIsExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: LabeledExprSyntax) -> LabeledExprSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(RedundantLet.self, node: Syntax(node)) {
      node = RedundantLet.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    var current: ExprSyntax = super.visit(node)
    if let concrete = current.as(MacroExpansionExprSyntax.self) {
      if context.shouldFormat(PreferFileID.self, node: Syntax(concrete)) {
        current = PreferFileID.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "PreferFileID: preceding rule widened MacroExpansionExprSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    return current
  }

  override func visit(_ node: MatchingPatternConditionSyntax) -> MatchingPatternConditionSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(CaseLet.self, node: Syntax(node)) {
      node = CaseLet.transform(node, parent: parent, context: context)
    }
    if context.shouldFormat(RedundantPattern.self, node: Syntax(node)) {
      node = RedundantPattern.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(MemberAccessExprSyntax.self) {
      result = ExprSyntax(rewriteMemberAccessExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoSemicolons.self, node: Syntax(node)) {
      NoSemicolons.willEnter(node, context: context)
    }
    var node = super.visit(node)
    if context.shouldFormat(NoSemicolons.self, node: Syntax(node)) {
      node = NoSemicolons.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: MemberBlockItemSyntax) -> MemberBlockItemSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(ConvertRegularCommentToDocC.self, node: Syntax(node)) {
      node = ConvertRegularCommentToDocC.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: OptionalBindingConditionSyntax) -> OptionalBindingConditionSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(NoBacktickedSelf.self, node: Syntax(node)) {
      node = NoBacktickedSelf.transform(node, parent: parent, context: context)
    }
    if context.shouldFormat(RedundantOptionalBinding.self, node: Syntax(node)) {
      node = RedundantOptionalBinding.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(EmptyCollectionLiteral.self, node: Syntax(node)) {
      node = EmptyCollectionLiteral.transform(node, parent: parent, context: context)
    }
    if context.shouldFormat(PreferSingleLinePropertyGetter.self, node: Syntax(node)) {
      node = PreferSingleLinePropertyGetter.transform(node, parent: parent, context: context)
    }
    if context.shouldFormat(RedundantReturn.self, node: Syntax(node)) {
      node = RedundantReturn.transform(node, parent: parent, context: context)
    }
    if context.shouldFormat(UseImplicitInit.self, node: Syntax(node)) {
      node = UseImplicitInit.transform(node, parent: parent, context: context)
    }
    if context.shouldFormat(WrapConditionalAssignment.self, node: Syntax(node)) {
      node = WrapConditionalAssignment.transform(node, parent: parent, context: context)
    }
    if context.shouldFormat(WrapSingleLineBodies.self, node: Syntax(node)) {
      node = WrapSingleLineBodies.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: PrefixOperatorExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(PrefixOperatorExprSyntax.self) {
      result = ExprSyntax(rewritePrefixOperatorExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(ProtocolDeclSyntax.self) {
      result = DeclSyntax(rewriteProtocolDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(node)) {
      NoParensAroundConditions.willEnter(node, context: context)
    }
    if context.shouldFormat(WrapSingleLineBodies.self, node: Syntax(node)) {
      WrapSingleLineBodies.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: StmtSyntax
    if let concrete = visited.as(RepeatStmtSyntax.self) {
      result = StmtSyntax(rewriteRepeatStmt(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(WrapSingleLineBodies.self, node: Syntax(node)) {
      WrapSingleLineBodies.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: ReturnStmtSyntax) -> StmtSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(node)) {
      NoParensAroundConditions.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: StmtSyntax
    if let concrete = visited.as(ReturnStmtSyntax.self) {
      result = StmtSyntax(rewriteReturnStmt(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoForceTry.self, node: Syntax(node)) {
      NoForceTry.willEnter(node, context: context)
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    if context.shouldFormat(NoGuardInTests.self, node: Syntax(node)) {
      NoGuardInTests.willEnter(node, context: context)
    }
    if context.shouldFormat(PreferEnvironmentEntry.self, node: Syntax(node)) {
      PreferEnvironmentEntry.willEnter(node, context: context)
    }
    if context.shouldFormat(PreferFinalClasses.self, node: Syntax(node)) {
      PreferFinalClasses.willEnter(node, context: context)
    }
    if context.shouldFormat(PreferSwiftTesting.self, node: Syntax(node)) {
      PreferSwiftTesting.willEnter(node, context: context)
    }
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(node)) {
      RedundantAccessControl.willEnter(node, context: context)
    }
    if context.shouldFormat(SwiftTestingTestCaseNames.self, node: Syntax(node)) {
      SwiftTestingTestCaseNames.willEnter(node, context: context)
    }
    if context.shouldFormat(TestSuiteAccessControl.self, node: Syntax(node)) {
      TestSuiteAccessControl.willEnter(node, context: context)
    }
    if context.shouldFormat(URLMacro.self, node: Syntax(node)) {
      URLMacro.willEnter(node, context: context)
    }
    if context.shouldFormat(ValidateTestCases.self, node: Syntax(node)) {
      ValidateTestCases.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result = rewriteSourceFile(visited, parent: parent, context: context)
    return result
  }

  override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(StringLiteralExprSyntax.self) {
      result = ExprSyntax(rewriteStringLiteralExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(PreferSelfType.self, node: Syntax(node)) {
      PreferSelfType.willEnter(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(StructDeclSyntax.self) {
      result = DeclSyntax(rewriteStructDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(PreferSelfType.self, node: Syntax(node)) {
      PreferSelfType.didExit(node, context: context)
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: SubscriptCallExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(SubscriptCallExprSyntax.self) {
      result = ExprSyntax(rewriteSubscriptCallExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(node)) {
      NoForceUnwrap.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(SubscriptDeclSyntax.self) {
      result = DeclSyntax(rewriteSubscriptDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(CaseLet.self, node: Syntax(node)) {
      node = CaseLet.transform(node, parent: parent, context: context)
    }
    if context.shouldFormat(RedundantPattern.self, node: Syntax(node)) {
      node = RedundantPattern.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: SwitchCaseLabelSyntax) -> SwitchCaseLabelSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldFormat(NoLabelsInCasePatterns.self, node: Syntax(node)) {
      node = NoLabelsInCasePatterns.transform(node, parent: parent, context: context)
    }
    if context.shouldFormat(WrapCompoundCaseItems.self, node: Syntax(node)) {
      node = WrapCompoundCaseItems.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: SwitchCaseListSyntax) -> SwitchCaseListSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoFallThroughOnlyCases.self, node: Syntax(node)) {
      NoFallThroughOnlyCases.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result = rewriteSwitchCaseList(visited, parent: parent, context: context)
    return result
  }

  override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(BlankLinesBeforeControlFlowBlocks.self, node: Syntax(node)) {
      BlankLinesBeforeControlFlowBlocks.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result = rewriteSwitchCase(visited, parent: parent, context: context)
    return result
  }

  override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(node)) {
      NoParensAroundConditions.willEnter(node, context: context)
    }
    if context.shouldFormat(SwitchCaseIndentation.self, node: Syntax(node)) {
      SwitchCaseIndentation.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(SwitchExprSyntax.self) {
      result = ExprSyntax(rewriteSwitchExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: TernaryExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(TernaryExprSyntax.self) {
      result = ExprSyntax(rewriteTernaryExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: TokenSyntax) -> TokenSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result = rewriteToken(visited, parent: parent, context: context)
    return result
  }

  override func visit(_ node: TryExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(TryExprSyntax.self) {
      result = ExprSyntax(rewriteTryExpr(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    var current: DeclSyntax = super.visit(node)
    if let concrete = current.as(TypeAliasDeclSyntax.self) {
      if context.shouldFormat(DocCommentsPrecedeModifiers.self, node: Syntax(concrete)) {
        current = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "DocCommentsPrecedeModifiers: preceding rule widened TypeAliasDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if let concrete = current.as(TypeAliasDeclSyntax.self) {
      if context.shouldFormat(ModifierOrder.self, node: Syntax(concrete)) {
        current = ModifierOrder.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "ModifierOrder: preceding rule widened TypeAliasDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if let concrete = current.as(TypeAliasDeclSyntax.self) {
      if context.shouldFormat(ModifiersOnSameLine.self, node: Syntax(concrete)) {
        current = ModifiersOnSameLine.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "ModifiersOnSameLine: preceding rule widened TypeAliasDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if let concrete = current.as(TypeAliasDeclSyntax.self) {
      if context.shouldFormat(RedundantAccessControl.self, node: Syntax(concrete)) {
        current = RedundantAccessControl.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "RedundantAccessControl: preceding rule widened TypeAliasDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if let concrete = current.as(TypeAliasDeclSyntax.self) {
      if context.shouldFormat(TripleSlashDocComments.self, node: Syntax(concrete)) {
        current = TripleSlashDocComments.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "TripleSlashDocComments: preceding rule widened TypeAliasDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    return current
  }

  override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if let concrete = visited.as(VariableDeclSyntax.self) {
      result = DeclSyntax(rewriteVariableDecl(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(RedundantSelf.self, node: Syntax(node)) {
      RedundantSelf.didExit(node, context: context)
    }
    return result
  }

  override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
    let parent = Syntax(node).parent
    if context.shouldFormat(WrapSingleLineBodies.self, node: Syntax(node)) {
      WrapSingleLineBodies.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: StmtSyntax
    if let concrete = visited.as(WhileStmtSyntax.self) {
      result = StmtSyntax(rewriteWhileStmt(concrete, parent: parent, context: context))
    } else {
      result = visited
    }
    if context.shouldFormat(WrapSingleLineBodies.self, node: Syntax(node)) {
      WrapSingleLineBodies.didExit(node, context: context)
    }
    return result
  }
}
