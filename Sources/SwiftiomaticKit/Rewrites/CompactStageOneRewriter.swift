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
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    var result = super.visit(node)
    if context.shouldRewrite(ProtocolAccessorOrder.self, at: Syntax(result)) {
      result = ProtocolAccessorOrder.transform(result, parent: parent, context: context)
    }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(AccessorDeclSyntax.self) {
      if context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(concrete)),
         let next = WrapSingleLineBodies.transform(concrete, parent: parent, context: context).as(AccessorDeclSyntax.self)
      {
        concrete = next
      }
      result = DeclSyntax(concrete)
    } else {
      result = visited
    }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let runPreferSelfType = context.shouldRewrite(PreferSelfType.self, at: Syntax(node))
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if runPreferSelfType { PreferSelfType.willEnter(node, context: context) }
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(ActorDeclSyntax.self) {
      if context.shouldRewrite(DocCommentsPrecedeModifiers.self, at: Syntax(concrete)),
         let next = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context).as(ActorDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifierOrder.self, at: Syntax(concrete)),
         let next = ModifierOrder.transform(concrete, parent: parent, context: context).as(ActorDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(ActorDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(concrete)),
         let next = RedundantAccessControl.transform(concrete, parent: parent, context: context).as(ActorDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(SimplifyGenericConstraints.self, at: Syntax(concrete)),
         let next = SimplifyGenericConstraints.transform(concrete, parent: parent, context: context).as(ActorDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantSwiftTestingSuite.self, at: Syntax(concrete)) {
        concrete = RedundantSwiftTestingSuite.removeSuite(
          from: concrete, keyword: \.actorKeyword, context: context
        )
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(ActorDeclSyntax.self)
      {
        concrete = next
      }
      result = DeclSyntax(concrete)
    } else {
      result = visited
    }
    if runPreferSelfType { PreferSelfType.didExit(node, context: context) }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: AsExprSyntax) -> ExprSyntax {
    let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, at: Syntax(node))
    if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(AsExprSyntax.self) {
      if context.shouldRewrite(NoForceCast.self, at: Syntax(concrete)),
         concrete.questionOrExclamationMark?.tokenKind == .exclamationMark
      {
        NoForceCast.diagnose(
          .doNotForceCast(name: concrete.type.trimmedDescription),
          on: concrete.asKeyword, context: context
        )
      }
      if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(concrete)),
         concrete.questionOrExclamationMark?.tokenKind == .exclamationMark
      {
        let widened = NoForceUnwrap.rewriteAsExpr(concrete, context: context)
        if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
        return widened
      }
      result = ExprSyntax(concrete)
    } else {
      result = visited
    }
    if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: AssociatedTypeDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    var current: DeclSyntax = super.visit(node)
    if let concrete = current.as(AssociatedTypeDeclSyntax.self) {
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)) {
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
    if context.shouldRewrite(PreferMainAttribute.self, at: Syntax(node)) {
      node = PreferMainAttribute.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: AttributedTypeSyntax) -> TypeSyntax {
    let parent = Syntax(node).parent
    var current: TypeSyntax = super.visit(node)
    if let concrete = current.as(AttributedTypeSyntax.self) {
      if context.shouldRewrite(NoExplicitOwnership.self, at: Syntax(concrete)) {
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
    let runHoistTry = context.shouldRewrite(HoistTry.self, at: Syntax(node))
    if runHoistTry { HoistTry.willEnter(node, context: context) }
    var current: ExprSyntax = super.visit(node)
    if let concrete = current.as(AwaitExprSyntax.self) {
      if context.shouldRewrite(HoistTry.self, at: Syntax(concrete)) {
        current = HoistTry.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "HoistTry: preceding rule widened AwaitExprSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if runHoistTry { HoistTry.didExit(node, context: context) }
    return current
  }

  override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(RedundantLetError.self, at: Syntax(node)) {
      node = RedundantLetError.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let runNoForceTry = context.shouldRewrite(NoForceTry.self, at: Syntax(node))
    let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, at: Syntax(node))
    let runNoGuardInTests = context.shouldRewrite(NoGuardInTests.self, at: Syntax(node))
    let runPreferSelfType = context.shouldRewrite(PreferSelfType.self, at: Syntax(node))
    let runPreferSwiftTesting = context.shouldRewrite(PreferSwiftTesting.self, at: Syntax(node))
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if runNoForceTry { NoForceTry.willEnter(node, context: context) }
    if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
    if runNoGuardInTests { NoGuardInTests.willEnter(node, context: context) }
    if runPreferSelfType { PreferSelfType.willEnter(node, context: context) }
    if runPreferSwiftTesting { PreferSwiftTesting.willEnter(node, context: context) }
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(ClassDeclSyntax.self) {
      if context.shouldRewrite(DocCommentsPrecedeModifiers.self, at: Syntax(concrete)),
         let next = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifierOrder.self, at: Syntax(concrete)),
         let next = ModifierOrder.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(PreferFinalClasses.self, at: Syntax(concrete)),
         let next = PreferFinalClasses.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(PreferStaticOverClassFunc.self, at: Syntax(concrete)),
         let next = PreferStaticOverClassFunc.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(PreferSwiftTesting.self, at: Syntax(concrete)),
         let next = PreferSwiftTesting.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(concrete)),
         let next = RedundantAccessControl.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantObjc.self, at: Syntax(concrete)),
         let next = RedundantObjc.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(SimplifyGenericConstraints.self, at: Syntax(concrete)),
         let next = SimplifyGenericConstraints.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TestSuiteAccessControl.self, at: Syntax(concrete)),
         let next = TestSuiteAccessControl.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TripleSlashDocComments.self, at: Syntax(concrete)),
         let next = TripleSlashDocComments.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ValidateTestCases.self, at: Syntax(concrete)),
         let next = ValidateTestCases.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantFinal.self, at: Syntax(concrete)) {
        concrete = RedundantFinal.apply(concrete, context: context)
      }
      if context.shouldRewrite(RedundantSwiftTestingSuite.self, at: Syntax(concrete)) {
        concrete = RedundantSwiftTestingSuite.removeSuite(
          from: concrete, keyword: \.classKeyword, context: context
        )
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(ClassDeclSyntax.self)
      {
        concrete = next
      }
      // StaticStructShouldBeEnum runs last because it can widen the class
      // to an `EnumDeclSyntax`.
      if context.shouldRewrite(StaticStructShouldBeEnum.self, at: Syntax(concrete)) {
        result = StaticStructShouldBeEnum.transform(concrete, parent: parent, context: context)
      } else {
        result = DeclSyntax(concrete)
      }
    } else {
      result = visited
    }
    if runNoForceTry { NoForceTry.didExit(node, context: context) }
    if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
    if runNoGuardInTests { NoGuardInTests.didExit(node, context: context) }
    if runPreferSelfType { PreferSelfType.didExit(node, context: context) }
    if runPreferSwiftTesting { PreferSwiftTesting.didExit(node, context: context) }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let runNamedClosureParams = context.shouldRewrite(NamedClosureParams.self, at: Syntax(node))
    let runNoForceTry = context.shouldRewrite(NoForceTry.self, at: Syntax(node))
    let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, at: Syntax(node))
    let runNoGuardInTests = context.shouldRewrite(NoGuardInTests.self, at: Syntax(node))
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if runNamedClosureParams { NamedClosureParams.willEnter(node, context: context) }
    if runNoForceTry { NoForceTry.willEnter(node, context: context) }
    if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
    if runNoGuardInTests { NoGuardInTests.willEnter(node, context: context) }
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: ExprSyntax
    if var concrete = visited.as(ClosureExprSyntax.self) {
      if context.shouldRewrite(RedundantReturn.self, at: Syntax(concrete)),
         let next = RedundantReturn.transform(concrete, parent: parent, context: context).as(ClosureExprSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(UnusedArguments.self, at: Syntax(concrete)),
         let next = UnusedArguments.transform(concrete, parent: parent, context: context).as(ClosureExprSyntax.self)
      {
        concrete = next
      }
      result = ExprSyntax(concrete)
    } else {
      result = visited
    }
    if runNamedClosureParams { NamedClosureParams.didExit(node, context: context) }
    if runNoForceTry { NoForceTry.didExit(node, context: context) }
    if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
    if runNoGuardInTests { NoGuardInTests.didExit(node, context: context) }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
    let parent = Syntax(node).parent
    if context.shouldRewrite(PreferVoidReturn.self, at: Syntax(node)) {
      PreferVoidReturn.willEnter(node, context: context)
    }
    var result = super.visit(node)
    if context.shouldRewrite(NoParensInClosureParams.self, at: Syntax(result)) {
      result = NoParensInClosureParams.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(PreferVoidReturn.self, at: Syntax(result)) {
      result = PreferVoidReturn.apply(result, context: context)
    }
    return result
  }

  override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    let parent = Syntax(node).parent
    if context.shouldRewrite(NoSemicolons.self, at: Syntax(node)) {
      NoSemicolons.willEnter(node, context: context)
    }
    if context.shouldRewrite(OneDeclarationPerLine.self, at: Syntax(node)) {
      OneDeclarationPerLine.willEnter(node, context: context)
    }
    if context.shouldRewrite(PreferEarlyExits.self, at: Syntax(node)) {
      PreferEarlyExits.willEnter(node, context: context)
    }
    var result = super.visit(node)
    if context.shouldRewrite(EmptyExtensions.self, at: Syntax(result)) {
      result = EmptyExtensions.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(NoAssignmentInExpressions.self, at: Syntax(result)) {
      result = NoAssignmentInExpressions.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(NoSemicolons.self, at: Syntax(result)) {
      result = NoSemicolons.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(OneDeclarationPerLine.self, at: Syntax(result)) {
      result = OneDeclarationPerLine.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(PreferConditionalExpression.self, at: Syntax(result)) {
      result = PreferConditionalExpression.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(PreferIfElseChain.self, at: Syntax(result)) {
      result = PreferIfElseChain.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(PreferTernary.self, at: Syntax(result)) {
      result = PreferTernary.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(RedundantLet.self, at: Syntax(result)) {
      result = RedundantLet.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(RedundantProperty.self, at: Syntax(result)) {
      result = RedundantProperty.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(PreferEarlyExits.self, at: Syntax(result)) {
      result = PreferEarlyExits.apply(result, context: context)
    }
    if context.shouldRewrite(NoGuardInTests.self, at: Syntax(result)) {
      result = NoGuardInTests.transform(result, parent: parent, context: context)
    }
    return result
  }

  override func visit(_ node: CodeBlockItemSyntax) -> CodeBlockItemSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(ConvertRegularCommentToDocC.self, at: Syntax(node)) {
      node = ConvertRegularCommentToDocC.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
    if context.shouldRewrite(BlankLinesBeforeControlFlowBlocks.self, at: Syntax(node)) {
      BlankLinesBeforeControlFlowBlocks.willEnter(node, context: context)
    }
    var result = super.visit(node)
    if context.shouldRewrite(BlankLinesAfterGuardStatements.self, at: Syntax(result)) {
      result = BlankLinesAfterGuardStatements.apply(result, context: context)
    }
    if context.shouldRewrite(BlankLinesBeforeControlFlowBlocks.self, at: Syntax(result)),
       let updated = BlankLinesBeforeControlFlowBlocks.insertBlankLines(
         in: Array(result.statements), context: context
       )
    {
      result.statements = CodeBlockItemListSyntax(updated)
    }
    return result
  }

  override func visit(_ node: ConditionElementListSyntax) -> ConditionElementListSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(PreferCommaConditions.self, at: Syntax(node)) {
      node = PreferCommaConditions.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: ConditionElementSyntax) -> ConditionElementSyntax {
    let parent = Syntax(node).parent
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(node)) {
      NoParensAroundConditions.willEnter(node, context: context)
    }
    var result = super.visit(node)
    if context.shouldRewrite(ExplicitNilCheck.self, at: Syntax(result)) {
      result = ExplicitNilCheck.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(result)),
       case .expression(let condition) = result.condition,
       let stripped = NoParensAroundConditions.minimalSingleExpression(condition, context: context)
    {
      result.condition = .expression(stripped)
    }
    return result
  }

  override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(ACLConsistency.self, at: Syntax(node)) {
      node = ACLConsistency.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
    let visited = super.visit(node)
    if let concrete = visited.as(DeclReferenceExprSyntax.self),
       context.shouldRewrite(NamedClosureParams.self, at: Syntax(concrete))
    {
      NamedClosureParams.rewriteDeclReference(concrete, context: context)
    }
    return visited
  }

  override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(DeinitializerDeclSyntax.self) {
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(DeinitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TripleSlashDocComments.self, at: Syntax(concrete)),
         let next = TripleSlashDocComments.transform(concrete, parent: parent, context: context).as(DeinitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(DeinitializerDeclSyntax.self)
      {
        concrete = next
      }
      result = DeclSyntax(concrete)
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: StmtSyntax
    if var concrete = visited.as(DoStmtSyntax.self) {
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(DoStmtSyntax.self)
      {
        concrete = next
      }
      result = StmtSyntax(concrete)
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    var current: DeclSyntax = super.visit(node)
    if let concrete = current.as(EnumCaseDeclSyntax.self) {
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)) {
        current = ModifiersOnSameLine.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "ModifiersOnSameLine: preceding rule widened EnumCaseDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if let concrete = current.as(EnumCaseDeclSyntax.self) {
      if context.shouldRewrite(RedundantRawValues.self, at: Syntax(concrete)) {
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
    if context.shouldRewrite(AvoidNoneName.self, at: Syntax(node)) {
      node = AvoidNoneName.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let runPreferSelfType = context.shouldRewrite(PreferSelfType.self, at: Syntax(node))
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if context.shouldRewrite(OneDeclarationPerLine.self, at: Syntax(node)) {
      OneDeclarationPerLine.willEnter(node, context: context)
    }
    if runPreferSelfType { PreferSelfType.willEnter(node, context: context) }
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(EnumDeclSyntax.self) {
      if context.shouldRewrite(CollapseSimpleEnums.self, at: Syntax(concrete)),
         let next = CollapseSimpleEnums.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(DocCommentsPrecedeModifiers.self, at: Syntax(concrete)),
         let next = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(IndirectEnum.self, at: Syntax(concrete)),
         let next = IndirectEnum.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifierOrder.self, at: Syntax(concrete)),
         let next = ModifierOrder.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(OneDeclarationPerLine.self, at: Syntax(concrete)),
         let next = OneDeclarationPerLine.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(concrete)),
         let next = RedundantAccessControl.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantObjc.self, at: Syntax(concrete)),
         let next = RedundantObjc.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantSendable.self, at: Syntax(concrete)),
         let next = RedundantSendable.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(SimplifyGenericConstraints.self, at: Syntax(concrete)),
         let next = SimplifyGenericConstraints.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TripleSlashDocComments.self, at: Syntax(concrete)),
         let next = TripleSlashDocComments.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ValidateTestCases.self, at: Syntax(concrete)),
         let next = ValidateTestCases.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantSwiftTestingSuite.self, at: Syntax(concrete)) {
        concrete = RedundantSwiftTestingSuite.removeSuite(
          from: concrete, keyword: \.enumKeyword, context: context
        )
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(EnumDeclSyntax.self)
      {
        concrete = next
      }
      result = DeclSyntax(concrete)
    } else {
      result = visited
    }
    if runPreferSelfType { PreferSelfType.didExit(node, context: context) }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let runPreferSelfType = context.shouldRewrite(PreferSelfType.self, at: Syntax(node))
    let runPreferSwiftTesting = context.shouldRewrite(PreferSwiftTesting.self, at: Syntax(node))
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if runPreferSelfType { PreferSelfType.willEnter(node, context: context) }
    if runPreferSwiftTesting { PreferSwiftTesting.willEnter(node, context: context) }
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(ExtensionDeclSyntax.self) {
      if context.shouldRewrite(DocCommentsPrecedeModifiers.self, at: Syntax(concrete)),
         let next = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context).as(ExtensionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(ExtensionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(PreferAngleBracketExtensions.self, at: Syntax(concrete)),
         let next = PreferAngleBracketExtensions.transform(concrete, parent: parent, context: context).as(ExtensionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(concrete)),
         let next = RedundantAccessControl.transform(concrete, parent: parent, context: context).as(ExtensionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TripleSlashDocComments.self, at: Syntax(concrete)),
         let next = TripleSlashDocComments.transform(concrete, parent: parent, context: context).as(ExtensionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(ExtensionDeclSyntax.self)
      {
        concrete = next
      }
      result = DeclSyntax(concrete)
    } else {
      result = visited
    }
    if runPreferSelfType { PreferSelfType.didExit(node, context: context) }
    if runPreferSwiftTesting { PreferSwiftTesting.didExit(node, context: context) }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
    let parent = Syntax(node).parent
    let runWrapSingleLineBodies = context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(node))
    if runWrapSingleLineBodies { WrapSingleLineBodies.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: StmtSyntax
    if var concrete = visited.as(ForStmtSyntax.self) {
      if context.shouldRewrite(CaseLet.self, at: Syntax(concrete)),
         let next = CaseLet.transform(concrete, parent: parent, context: context).as(ForStmtSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(PreferWhereClausesInForLoops.self, at: Syntax(concrete)),
         let next = PreferWhereClausesInForLoops.transform(concrete, parent: parent, context: context).as(ForStmtSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantEnumerated.self, at: Syntax(concrete)),
         let next = RedundantEnumerated.transform(concrete, parent: parent, context: context).as(ForStmtSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(UnusedArguments.self, at: Syntax(concrete)),
         let next = UnusedArguments.transform(concrete, parent: parent, context: context).as(ForStmtSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(ForStmtSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(concrete)),
         let next = WrapSingleLineBodies.transform(concrete, parent: parent, context: context).as(ForStmtSyntax.self)
      {
        concrete = next
      }
      result = StmtSyntax(concrete)
    } else {
      result = visited
    }
    if runWrapSingleLineBodies { WrapSingleLineBodies.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: ForceUnwrapExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, at: Syntax(node))
    if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: ExprSyntax
    if var concrete = visited.as(ForceUnwrapExprSyntax.self) {
      if context.shouldRewrite(URLMacro.self, at: Syntax(concrete)) {
        let widened = URLMacro.transform(concrete, parent: parent, context: context)
        if let stillForce = widened.as(ForceUnwrapExprSyntax.self) {
          concrete = stillForce
        } else {
          if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
          return widened
        }
      }
      if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(concrete)) {
        result = NoForceUnwrap.rewriteForceUnwrap(concrete, context: context)
      } else {
        result = ExprSyntax(concrete)
      }
    } else {
      result = visited
    }
    if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, at: Syntax(node))
    let runPreferSwiftTesting = context.shouldRewrite(PreferSwiftTesting.self, at: Syntax(node))
    if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
    if context.shouldRewrite(NoTrailingClosureParens.self, at: Syntax(node)) {
      NoTrailingClosureParens.willEnter(node, context: context)
    }
    if runPreferSwiftTesting { PreferSwiftTesting.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: ExprSyntax
    if var concrete = visited.as(FunctionCallExprSyntax.self) {
      func finishExit(_ value: ExprSyntax) -> ExprSyntax {
        if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
        if runPreferSwiftTesting { PreferSwiftTesting.didExit(node, context: context) }
        return value
      }
      // HoistAwait may widen `foo(await x)` to `await foo(x)`.
      if context.shouldRewrite(HoistAwait.self, at: Syntax(concrete)) {
        let widened = HoistAwait.transform(concrete, parent: parent, context: context)
        if let stillCall = widened.as(FunctionCallExprSyntax.self) {
          concrete = stillCall
        } else {
          return finishExit(widened)
        }
      }
      // HoistTry may widen `foo(try x)` to `try foo(x)`.
      if context.shouldRewrite(HoistTry.self, at: Syntax(concrete)) {
        let widened = HoistTry.transform(concrete, parent: parent, context: context)
        if let stillCall = widened.as(FunctionCallExprSyntax.self) {
          concrete = stillCall
        } else {
          return finishExit(widened)
        }
      }
      if context.shouldRewrite(PreferAssertionFailure.self, at: Syntax(concrete)),
         let next = PreferAssertionFailure.transform(concrete, parent: parent, context: context).as(FunctionCallExprSyntax.self)
      {
        concrete = next
      }
      // PreferSwiftTesting may widen `FunctionCallExpr` to `MacroExpansionExpr`.
      if context.shouldRewrite(PreferSwiftTesting.self, at: Syntax(concrete)) {
        let widened = PreferSwiftTesting.transform(concrete, parent: parent, context: context)
        if let stillCall = widened.as(FunctionCallExprSyntax.self) {
          concrete = stillCall
        } else {
          return finishExit(widened)
        }
      }
      // PreferDotZero may widen the call to a `MemberAccessExpr`.
      if context.shouldRewrite(PreferDotZero.self, at: Syntax(concrete)) {
        let widened = PreferDotZero.transform(concrete, parent: parent, context: context)
        if let stillCall = widened.as(FunctionCallExprSyntax.self) {
          concrete = stillCall
        } else {
          return finishExit(widened)
        }
      }
      if context.shouldRewrite(PreferKeyPath.self, at: Syntax(concrete)),
         let next = PreferKeyPath.transform(concrete, parent: parent, context: context).as(FunctionCallExprSyntax.self)
      {
        concrete = next
      }
      // RedundantClosure may unwrap `{ x }()` to `x` (any `ExprSyntax`).
      if context.shouldRewrite(RedundantClosure.self, at: Syntax(concrete)) {
        let widened = RedundantClosure.transform(concrete, parent: parent, context: context)
        if let stillCall = widened.as(FunctionCallExprSyntax.self) {
          concrete = stillCall
        } else {
          return finishExit(widened)
        }
      }
      if context.shouldRewrite(RedundantInit.self, at: Syntax(concrete)),
         let next = RedundantInit.transform(concrete, parent: parent, context: context).as(FunctionCallExprSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RequireFatalErrorMessage.self, at: Syntax(concrete)),
         let next = RequireFatalErrorMessage.transform(concrete, parent: parent, context: context).as(FunctionCallExprSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(NoTrailingClosureParens.self, at: Syntax(concrete)) {
        concrete = NoTrailingClosureParens.apply(concrete, context: context)
      }
      if context.shouldRewrite(PreferTrailingClosures.self, at: Syntax(concrete)) {
        concrete = PreferTrailingClosures.apply(concrete, context: context)
      }
      if context.shouldRewrite(WrapMultilineFunctionChains.self, at: Syntax(concrete)) {
        concrete = WrapMultilineFunctionChains.apply(concrete, context: context)
      }
      // NestedCallLayout may produce a different ExprSyntax kind.
      var resultExpr: ExprSyntax = ExprSyntax(concrete)
      if context.shouldRewrite(NestedCallLayout.self, at: Syntax(concrete)) {
        resultExpr = NestedCallLayout.transform(concrete, parent: parent, context: context)
        if let typed = resultExpr.as(FunctionCallExprSyntax.self) { concrete = typed }
      }
      // NoForceUnwrap chain-top wrapping at this call.
      if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(concrete)) {
        return finishExit(NoForceUnwrap.rewriteFunctionCallTop(concrete, context: context))
      }
      result = resultExpr
    } else {
      result = visited
    }
    if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
    if runPreferSwiftTesting { PreferSwiftTesting.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let runNoForceTry = context.shouldRewrite(NoForceTry.self, at: Syntax(node))
    let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, at: Syntax(node))
    let runNoGuardInTests = context.shouldRewrite(NoGuardInTests.self, at: Syntax(node))
    let runPreferSwiftTesting = context.shouldRewrite(PreferSwiftTesting.self, at: Syntax(node))
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if runNoForceTry { NoForceTry.willEnter(node, context: context) }
    if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
    if runNoGuardInTests { NoGuardInTests.willEnter(node, context: context) }
    if runPreferSwiftTesting { PreferSwiftTesting.willEnter(node, context: context) }
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(FunctionDeclSyntax.self) {
      if context.shouldRewrite(DocCommentsPrecedeModifiers.self, at: Syntax(concrete)),
         let next = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifierOrder.self, at: Syntax(concrete)),
         let next = ModifierOrder.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(NoExplicitOwnership.self, at: Syntax(concrete)),
         let next = NoExplicitOwnership.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(NoGuardInTests.self, at: Syntax(concrete)),
         let next = NoGuardInTests.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(OpaqueGenericParameters.self, at: Syntax(concrete)),
         let next = OpaqueGenericParameters.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(concrete)),
         let next = RedundantAccessControl.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantAsync.self, at: Syntax(concrete)),
         let next = RedundantAsync.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantObjc.self, at: Syntax(concrete)),
         let next = RedundantObjc.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantReturn.self, at: Syntax(concrete)),
         let next = RedundantReturn.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantThrows.self, at: Syntax(concrete)),
         let next = RedundantThrows.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantViewBuilder.self, at: Syntax(concrete)),
         let next = RedundantViewBuilder.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(SimplifyGenericConstraints.self, at: Syntax(concrete)),
         let next = SimplifyGenericConstraints.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(SwiftTestingTestCaseNames.self, at: Syntax(concrete)),
         let next = SwiftTestingTestCaseNames.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TripleSlashDocComments.self, at: Syntax(concrete)),
         let next = TripleSlashDocComments.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(UnusedArguments.self, at: Syntax(concrete)),
         let next = UnusedArguments.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(UseImplicitInit.self, at: Syntax(concrete)),
         let next = UseImplicitInit.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      // NoForceTry — after children visit, add a `throws` clause if any inner
      // `try!` was converted.
      if context.shouldRewrite(NoForceTry.self, at: Syntax(concrete)) {
        concrete = NoForceTry.afterFunctionDecl(concrete, context: context)
      }
      // NoForceUnwrap — same pattern.
      if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(concrete)) {
        concrete = NoForceUnwrap.afterFunctionDecl(concrete, context: context)
      }
      if context.shouldRewrite(RedundantEscaping.self, at: Syntax(concrete)),
         let next = RedundantEscaping.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(concrete)),
         let next = WrapSingleLineBodies.transform(concrete, parent: parent, context: context).as(FunctionDeclSyntax.self)
      {
        concrete = next
      }
      // PreferSwiftTesting may widen `FunctionDecl` to
      // `InitializerDecl`/`DeinitializerDecl`; early-return on kind change.
      if context.shouldRewrite(PreferSwiftTesting.self, at: Syntax(concrete)) {
        let widened = PreferSwiftTesting.transform(concrete, parent: parent, context: context)
        if let stillFunc = widened.as(FunctionDeclSyntax.self) {
          concrete = stillFunc
        } else {
          if runNoForceTry { NoForceTry.didExit(node, context: context) }
          if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
          if runNoGuardInTests { NoGuardInTests.didExit(node, context: context) }
          if runPreferSwiftTesting { PreferSwiftTesting.didExit(node, context: context) }
          if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
          return widened
        }
      }
      // RedundantOverride may delete `override` declarations entirely.
      if context.shouldRewrite(RedundantOverride.self, at: Syntax(concrete)) {
        let after = RedundantOverride.transform(concrete, parent: parent, context: context)
        if runNoForceTry { NoForceTry.didExit(node, context: context) }
        if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
        if runNoGuardInTests { NoGuardInTests.didExit(node, context: context) }
        if runPreferSwiftTesting { PreferSwiftTesting.didExit(node, context: context) }
        if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
        return after
      }
      result = DeclSyntax(concrete)
    } else {
      result = visited
    }
    if runNoForceTry { NoForceTry.didExit(node, context: context) }
    if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
    if runNoGuardInTests { NoGuardInTests.didExit(node, context: context) }
    if runPreferSwiftTesting { PreferSwiftTesting.didExit(node, context: context) }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: FunctionEffectSpecifiersSyntax) -> FunctionEffectSpecifiersSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(RedundantTypedThrows.self, at: Syntax(node)) {
      node = RedundantTypedThrows.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(EmptyCollectionLiteral.self, at: Syntax(node)) {
      node = EmptyCollectionLiteral.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: FunctionSignatureSyntax) -> FunctionSignatureSyntax {
    var result = super.visit(node)
    if context.shouldRewrite(NoVoidReturnOnFunctionSignature.self, at: Syntax(result)) {
      result = NoVoidReturnOnFunctionSignature.apply(result, context: context)
    }
    return result
  }

  override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
    let parent = Syntax(node).parent
    if context.shouldRewrite(PreferVoidReturn.self, at: Syntax(node)) {
      PreferVoidReturn.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: TypeSyntax
    if var concrete = visited.as(FunctionTypeSyntax.self) {
      if context.shouldRewrite(RedundantTypedThrows.self, at: Syntax(concrete)),
         let next = RedundantTypedThrows.transform(concrete, parent: parent, context: context).as(FunctionTypeSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(PreferVoidReturn.self, at: Syntax(concrete)) {
        concrete = PreferVoidReturn.apply(concrete, context: context)
      }
      result = TypeSyntax(concrete)
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: GenericSpecializationExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldRewrite(PreferShorthandTypeNames.self, at: Syntax(node)) {
      PreferShorthandTypeNames.willEnter(node, context: context)
    }
    var result: ExprSyntax = super.visit(node)
    if context.shouldRewrite(PreferShorthandTypeNames.self, at: Syntax(result)),
       let typed = result.as(GenericSpecializationExprSyntax.self)
    {
      result = PreferShorthandTypeNames.transform(typed, parent: parent, context: context)
    }
    return result
  }

  override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
    let parent = Syntax(node).parent
    let runWrapSingleLineBodies = context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(node))
    if runWrapSingleLineBodies { WrapSingleLineBodies.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: StmtSyntax
    if var concrete = visited.as(GuardStmtSyntax.self) {
      if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(concrete)) {
        NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.guardKeyword.trailingTrivia)
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(GuardStmtSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(concrete)),
         let next = WrapSingleLineBodies.transform(concrete, parent: parent, context: context).as(GuardStmtSyntax.self)
      {
        concrete = next
      }
      result = StmtSyntax(concrete)
    } else {
      result = visited
    }
    if runWrapSingleLineBodies { WrapSingleLineBodies.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
    let parent = Syntax(node).parent
    if context.shouldRewrite(PreferShorthandTypeNames.self, at: Syntax(node)) {
      PreferShorthandTypeNames.willEnter(node, context: context)
    }
    var result: TypeSyntax = super.visit(node)
    if context.shouldRewrite(PreferShorthandTypeNames.self, at: Syntax(result)),
       let typed = result.as(IdentifierTypeSyntax.self)
    {
      result = PreferShorthandTypeNames.transform(typed, parent: parent, context: context)
    }
    return result
  }

  override func visit(_ node: IfExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let runWrapSingleLineBodies = context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(node))
    if runWrapSingleLineBodies { WrapSingleLineBodies.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: ExprSyntax
    if var concrete = visited.as(IfExprSyntax.self) {
      if context.shouldRewrite(CollapseSimpleIfElse.self, at: Syntax(concrete)),
         let next = CollapseSimpleIfElse.transform(concrete, parent: parent, context: context).as(IfExprSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(PreferUnavailable.self, at: Syntax(concrete)),
         let next = PreferUnavailable.transform(concrete, parent: parent, context: context).as(IfExprSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(concrete)) {
        NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.ifKeyword.trailingTrivia)
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(IfExprSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(concrete)),
         let next = WrapSingleLineBodies.transform(concrete, parent: parent, context: context).as(IfExprSyntax.self)
      {
        concrete = next
      }
      result = ExprSyntax(concrete)
    } else {
      result = visited
    }
    if runWrapSingleLineBodies { WrapSingleLineBodies.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(ImportDeclSyntax.self) {
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(ImportDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(PreferSwiftTesting.self, at: Syntax(concrete)),
         let next = PreferSwiftTesting.transform(concrete, parent: parent, context: context).as(ImportDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantSwiftTestingSuite.self, at: Syntax(concrete)) {
        RedundantSwiftTestingSuite.visitImport(concrete, context: context)
      }
      if context.shouldRewrite(NoForceTry.self, at: Syntax(concrete)) {
        NoForceTry.visitImport(concrete, context: context)
      }
      if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(concrete)) {
        NoForceUnwrap.visitImport(concrete, context: context)
      }
      result = DeclSyntax(concrete)
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    guard var concrete = visited.as(InfixOperatorExprSyntax.self) else { return visited }
    if context.shouldRewrite(NoAssignmentInExpressions.self, at: Syntax(concrete)),
       let next = NoAssignmentInExpressions.transform(concrete, parent: parent, context: context).as(InfixOperatorExprSyntax.self)
    {
      concrete = next
    }
    if context.shouldRewrite(NoYodaConditions.self, at: Syntax(concrete)),
       let next = NoYodaConditions.transform(concrete, parent: parent, context: context).as(InfixOperatorExprSyntax.self)
    {
      concrete = next
    }
    if context.shouldRewrite(PreferCompoundAssignment.self, at: Syntax(concrete)),
       let next = PreferCompoundAssignment.transform(concrete, parent: parent, context: context).as(InfixOperatorExprSyntax.self)
    {
      concrete = next
    }
    if context.shouldRewrite(PreferIsEmpty.self, at: Syntax(concrete)) {
      let widened = PreferIsEmpty.transform(concrete, parent: parent, context: context)
      if let stillInfix = widened.as(InfixOperatorExprSyntax.self) {
        concrete = stillInfix
      } else {
        return widened
      }
    }
    if context.shouldRewrite(PreferToggle.self, at: Syntax(concrete)) {
      let widened = PreferToggle.transform(concrete, parent: parent, context: context)
      if let stillInfix = widened.as(InfixOperatorExprSyntax.self) {
        concrete = stillInfix
      } else {
        return widened
      }
    }
    if context.shouldRewrite(RedundantNilCoalescing.self, at: Syntax(concrete)) {
      let widened = RedundantNilCoalescing.transform(concrete, parent: parent, context: context)
      if let stillInfix = widened.as(InfixOperatorExprSyntax.self) {
        concrete = stillInfix
      } else {
        return widened
      }
    }
    if context.shouldRewrite(WrapConditionalAssignment.self, at: Syntax(concrete)),
       let next = WrapConditionalAssignment.transform(concrete, parent: parent, context: context).as(InfixOperatorExprSyntax.self)
    {
      concrete = next
    }
    return ExprSyntax(concrete)
  }

  override func visit(_ node: InitializerClauseSyntax) -> InitializerClauseSyntax {
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(node)) {
      NoParensAroundConditions.willEnter(node, context: context)
    }
    var result = super.visit(node)
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(result)),
       let stripped = NoParensAroundConditions.minimalSingleExpression(result.value, context: context)
    {
      result.value = stripped
    }
    return result
  }

  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(InitializerDeclSyntax.self) {
      if context.shouldRewrite(DocCommentsPrecedeModifiers.self, at: Syntax(concrete)),
         let next = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(InitCoderUnavailable.self, at: Syntax(concrete)),
         let next = InitCoderUnavailable.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifierOrder.self, at: Syntax(concrete)),
         let next = ModifierOrder.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(OpaqueGenericParameters.self, at: Syntax(concrete)),
         let next = OpaqueGenericParameters.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(concrete)),
         let next = RedundantAccessControl.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantObjc.self, at: Syntax(concrete)),
         let next = RedundantObjc.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TripleSlashDocComments.self, at: Syntax(concrete)),
         let next = TripleSlashDocComments.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(UnusedArguments.self, at: Syntax(concrete)),
         let next = UnusedArguments.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(UseImplicitInit.self, at: Syntax(concrete)),
         let next = UseImplicitInit.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantEscaping.self, at: Syntax(concrete)),
         let next = RedundantEscaping.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(concrete)),
         let next = WrapSingleLineBodies.transform(concrete, parent: parent, context: context).as(InitializerDeclSyntax.self)
      {
        concrete = next
      }
      result = DeclSyntax(concrete)
    } else {
      result = visited
    }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: IntegerLiteralExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    var current: ExprSyntax = super.visit(node)
    if let concrete = current.as(IntegerLiteralExprSyntax.self) {
      if context.shouldRewrite(GroupNumericLiterals.self, at: Syntax(concrete)) {
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
    super.visit(node)
  }

  override func visit(_ node: LabeledExprSyntax) -> LabeledExprSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(RedundantLet.self, at: Syntax(node)) {
      node = RedundantLet.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    var current: ExprSyntax = super.visit(node)
    if let concrete = current.as(MacroExpansionExprSyntax.self) {
      if context.shouldRewrite(PreferFileID.self, at: Syntax(concrete)) {
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
    if context.shouldRewrite(CaseLet.self, at: Syntax(node)) {
      node = CaseLet.transform(node, parent: parent, context: context)
    }
    if context.shouldRewrite(RedundantPattern.self, at: Syntax(node)) {
      node = RedundantPattern.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, at: Syntax(node))
    if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
    let visited = super.visit(node)
    func finishExit(_ result: ExprSyntax) -> ExprSyntax {
      if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
      return result
    }
    guard var concrete = visited.as(MemberAccessExprSyntax.self) else {
      return finishExit(visited)
    }
    if context.shouldRewrite(PreferCountWhere.self, at: Syntax(concrete)) {
      let widened = PreferCountWhere.transform(concrete, parent: parent, context: context)
      if let stillMember = widened.as(MemberAccessExprSyntax.self) {
        concrete = stillMember
      } else {
        return finishExit(widened)
      }
    }
    if context.shouldRewrite(PreferIsDisjoint.self, at: Syntax(concrete)),
       let next = PreferIsDisjoint.transform(concrete, parent: parent, context: context).as(MemberAccessExprSyntax.self)
    {
      concrete = next
    }
    if context.shouldRewrite(PreferSelfType.self, at: Syntax(concrete)),
       let next = PreferSelfType.transform(concrete, parent: parent, context: context).as(MemberAccessExprSyntax.self)
    {
      concrete = next
    }
    if context.shouldRewrite(RedundantSelf.self, at: Syntax(concrete)) {
      let widened = RedundantSelf.transform(concrete, parent: parent, context: context)
      if let stillMember = widened.as(MemberAccessExprSyntax.self) {
        concrete = stillMember
      } else {
        return finishExit(widened)
      }
    }
    if context.shouldRewrite(RedundantStaticSelf.self, at: Syntax(concrete)) {
      let widened = RedundantStaticSelf.transform(concrete, parent: parent, context: context)
      if let stillMember = widened.as(MemberAccessExprSyntax.self) {
        concrete = stillMember
      } else {
        return finishExit(widened)
      }
    }
    if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(concrete)) {
      return finishExit(NoForceUnwrap.rewriteMemberAccess(concrete, context: context))
    }
    return finishExit(ExprSyntax(concrete))
  }

  override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
    let parent = Syntax(node).parent
    if context.shouldRewrite(NoSemicolons.self, at: Syntax(node)) {
      NoSemicolons.willEnter(node, context: context)
    }
    var node = super.visit(node)
    if context.shouldRewrite(NoSemicolons.self, at: Syntax(node)) {
      node = NoSemicolons.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: MemberBlockItemSyntax) -> MemberBlockItemSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(ConvertRegularCommentToDocC.self, at: Syntax(node)) {
      node = ConvertRegularCommentToDocC.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: OptionalBindingConditionSyntax) -> OptionalBindingConditionSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(NoBacktickedSelf.self, at: Syntax(node)) {
      node = NoBacktickedSelf.transform(node, parent: parent, context: context)
    }
    if context.shouldRewrite(RedundantOptionalBinding.self, at: Syntax(node)) {
      node = RedundantOptionalBinding.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(EmptyCollectionLiteral.self, at: Syntax(node)) {
      node = EmptyCollectionLiteral.transform(node, parent: parent, context: context)
    }
    if context.shouldRewrite(PreferSingleLinePropertyGetter.self, at: Syntax(node)) {
      node = PreferSingleLinePropertyGetter.transform(node, parent: parent, context: context)
    }
    if context.shouldRewrite(RedundantReturn.self, at: Syntax(node)) {
      node = RedundantReturn.transform(node, parent: parent, context: context)
    }
    if context.shouldRewrite(UseImplicitInit.self, at: Syntax(node)) {
      node = UseImplicitInit.transform(node, parent: parent, context: context)
    }
    if context.shouldRewrite(WrapConditionalAssignment.self, at: Syntax(node)) {
      node = WrapConditionalAssignment.transform(node, parent: parent, context: context)
    }
    if context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(node)) {
      node = WrapSingleLineBodies.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: PrefixOperatorExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    var result: ExprSyntax = super.visit(node)
    if context.shouldRewrite(PreferExplicitFalse.self, at: Syntax(result)),
       let prefix = result.as(PrefixOperatorExprSyntax.self)
    {
      result = PreferExplicitFalse.transform(prefix, parent: parent, context: context)
    }
    return result
  }

  override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(ProtocolDeclSyntax.self) {
      if context.shouldRewrite(DocCommentsPrecedeModifiers.self, at: Syntax(concrete)),
         let next = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context).as(ProtocolDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(ProtocolDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(concrete)),
         let next = RedundantAccessControl.transform(concrete, parent: parent, context: context).as(ProtocolDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TripleSlashDocComments.self, at: Syntax(concrete)),
         let next = TripleSlashDocComments.transform(concrete, parent: parent, context: context).as(ProtocolDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(PreferAnyObject.self, at: Syntax(concrete)) {
        concrete = PreferAnyObject.apply(concrete, context: context)
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(ProtocolDeclSyntax.self)
      {
        concrete = next
      }
      result = DeclSyntax(concrete)
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
    let parent = Syntax(node).parent
    let runWrapSingleLineBodies = context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(node))
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(node)) {
      NoParensAroundConditions.willEnter(node, context: context)
    }
    if runWrapSingleLineBodies { WrapSingleLineBodies.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: StmtSyntax
    if var concrete = visited.as(RepeatStmtSyntax.self) {
      if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(concrete)),
         let stripped = NoParensAroundConditions.minimalSingleExpression(concrete.condition, context: context)
      {
        concrete.condition = stripped
        NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.whileKeyword.trailingTrivia)
      }
      if context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(concrete)),
         let next = WrapSingleLineBodies.transform(concrete, parent: parent, context: context).as(RepeatStmtSyntax.self)
      {
        concrete = next
      }
      result = StmtSyntax(concrete)
    } else {
      result = visited
    }
    if runWrapSingleLineBodies { WrapSingleLineBodies.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: ReturnStmtSyntax) -> StmtSyntax {
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(node)) {
      NoParensAroundConditions.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: StmtSyntax
    if var concrete = visited.as(ReturnStmtSyntax.self) {
      if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(concrete)),
         let expression = concrete.expression,
         let stripped = NoParensAroundConditions.minimalSingleExpression(expression, context: context)
      {
        concrete.expression = stripped
        NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.returnKeyword.trailingTrivia)
      }
      result = StmtSyntax(concrete)
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    let parent = Syntax(node).parent
    if context.shouldRewrite(NoForceTry.self, at: Syntax(node)) {
      NoForceTry.willEnter(node, context: context)
    }
    if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(node)) {
      NoForceUnwrap.willEnter(node, context: context)
    }
    if context.shouldRewrite(NoGuardInTests.self, at: Syntax(node)) {
      NoGuardInTests.willEnter(node, context: context)
    }
    if context.shouldRewrite(PreferEnvironmentEntry.self, at: Syntax(node)) {
      PreferEnvironmentEntry.willEnter(node, context: context)
    }
    if context.shouldRewrite(PreferFinalClasses.self, at: Syntax(node)) {
      PreferFinalClasses.willEnter(node, context: context)
    }
    if context.shouldRewrite(PreferSwiftTesting.self, at: Syntax(node)) {
      PreferSwiftTesting.willEnter(node, context: context)
    }
    if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(node)) {
      RedundantAccessControl.willEnter(node, context: context)
    }
    if context.shouldRewrite(SwiftTestingTestCaseNames.self, at: Syntax(node)) {
      SwiftTestingTestCaseNames.willEnter(node, context: context)
    }
    if context.shouldRewrite(TestSuiteAccessControl.self, at: Syntax(node)) {
      TestSuiteAccessControl.willEnter(node, context: context)
    }
    if context.shouldRewrite(URLMacro.self, at: Syntax(node)) {
      URLMacro.willEnter(node, context: context)
    }
    if context.shouldRewrite(ValidateTestCases.self, at: Syntax(node)) {
      ValidateTestCases.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result = rewriteSourceFile(visited, parent: parent, context: context)
    return result
  }

  override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
    let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, at: Syntax(node))
    if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
    let result = super.visit(node)
    if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let runPreferSelfType = context.shouldRewrite(PreferSelfType.self, at: Syntax(node))
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if runPreferSelfType { PreferSelfType.willEnter(node, context: context) }
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(StructDeclSyntax.self) {
      if context.shouldRewrite(DocCommentsPrecedeModifiers.self, at: Syntax(concrete)),
         let next = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifierOrder.self, at: Syntax(concrete)),
         let next = ModifierOrder.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(concrete)),
         let next = RedundantAccessControl.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantEquatable.self, at: Syntax(concrete)),
         let next = RedundantEquatable.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantObjc.self, at: Syntax(concrete)),
         let next = RedundantObjc.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantSendable.self, at: Syntax(concrete)),
         let next = RedundantSendable.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(SimplifyGenericConstraints.self, at: Syntax(concrete)),
         let next = SimplifyGenericConstraints.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TestSuiteAccessControl.self, at: Syntax(concrete)),
         let next = TestSuiteAccessControl.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TripleSlashDocComments.self, at: Syntax(concrete)),
         let next = TripleSlashDocComments.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ValidateTestCases.self, at: Syntax(concrete)),
         let next = ValidateTestCases.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantSwiftTestingSuite.self, at: Syntax(concrete)) {
        concrete = RedundantSwiftTestingSuite.removeSuite(
          from: concrete, keyword: \.structKeyword, context: context
        )
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(StructDeclSyntax.self)
      {
        concrete = next
      }
      // StaticStructShouldBeEnum runs last because it can widen
      // `StructDeclSyntax` to `EnumDeclSyntax`.
      if context.shouldRewrite(StaticStructShouldBeEnum.self, at: Syntax(concrete)) {
        result = StaticStructShouldBeEnum.transform(concrete, parent: parent, context: context)
      } else {
        result = DeclSyntax(concrete)
      }
    } else {
      result = visited
    }
    if runPreferSelfType { PreferSelfType.didExit(node, context: context) }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: SubscriptCallExprSyntax) -> ExprSyntax {
    let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, at: Syntax(node))
    if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: ExprSyntax
    if let concrete = visited.as(SubscriptCallExprSyntax.self) {
      if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(concrete)) {
        result = NoForceUnwrap.rewriteSubscriptCallTop(concrete, context: context)
      } else {
        result = ExprSyntax(concrete)
      }
    } else {
      result = visited
    }
    if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(SubscriptDeclSyntax.self) {
      if context.shouldRewrite(DocCommentsPrecedeModifiers.self, at: Syntax(concrete)),
         let next = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context).as(SubscriptDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifierOrder.self, at: Syntax(concrete)),
         let next = ModifierOrder.transform(concrete, parent: parent, context: context).as(SubscriptDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(SubscriptDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(OpaqueGenericParameters.self, at: Syntax(concrete)),
         let next = OpaqueGenericParameters.transform(concrete, parent: parent, context: context).as(SubscriptDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(concrete)),
         let next = RedundantAccessControl.transform(concrete, parent: parent, context: context).as(SubscriptDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantObjc.self, at: Syntax(concrete)),
         let next = RedundantObjc.transform(concrete, parent: parent, context: context).as(SubscriptDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantReturn.self, at: Syntax(concrete)),
         let next = RedundantReturn.transform(concrete, parent: parent, context: context).as(SubscriptDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TripleSlashDocComments.self, at: Syntax(concrete)),
         let next = TripleSlashDocComments.transform(concrete, parent: parent, context: context).as(SubscriptDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(UnusedArguments.self, at: Syntax(concrete)),
         let next = UnusedArguments.transform(concrete, parent: parent, context: context).as(SubscriptDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(UseImplicitInit.self, at: Syntax(concrete)),
         let next = UseImplicitInit.transform(concrete, parent: parent, context: context).as(SubscriptDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(concrete)),
         let next = WrapSingleLineBodies.transform(concrete, parent: parent, context: context).as(SubscriptDeclSyntax.self)
      {
        concrete = next
      }
      result = DeclSyntax(concrete)
    } else {
      result = visited
    }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(CaseLet.self, at: Syntax(node)) {
      node = CaseLet.transform(node, parent: parent, context: context)
    }
    if context.shouldRewrite(RedundantPattern.self, at: Syntax(node)) {
      node = RedundantPattern.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: SwitchCaseLabelSyntax) -> SwitchCaseLabelSyntax {
    let parent = Syntax(node).parent
    var node = super.visit(node)
    if context.shouldRewrite(NoLabelsInCasePatterns.self, at: Syntax(node)) {
      node = NoLabelsInCasePatterns.transform(node, parent: parent, context: context)
    }
    if context.shouldRewrite(WrapCompoundCaseItems.self, at: Syntax(node)) {
      node = WrapCompoundCaseItems.transform(node, parent: parent, context: context)
    }
    return node
  }

  override func visit(_ node: SwitchCaseListSyntax) -> SwitchCaseListSyntax {
    if context.shouldRewrite(NoFallThroughOnlyCases.self, at: Syntax(node)) {
      NoFallThroughOnlyCases.willEnter(node, context: context)
    }
    var result = super.visit(node)
    if context.shouldRewrite(NoFallThroughOnlyCases.self, at: Syntax(result)) {
      result = NoFallThroughOnlyCases.apply(result, context: context)
    }
    return result
  }

  override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
    let parent = Syntax(node).parent
    if context.shouldRewrite(BlankLinesBeforeControlFlowBlocks.self, at: Syntax(node)) {
      BlankLinesBeforeControlFlowBlocks.willEnter(node, context: context)
    }
    var result = super.visit(node)
    if context.shouldRewrite(RedundantBreak.self, at: Syntax(result)) {
      result = RedundantBreak.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(WrapSwitchCaseBodies.self, at: Syntax(result)) {
      result = WrapSwitchCaseBodies.transform(result, parent: parent, context: context)
    }
    if context.shouldRewrite(BlankLinesBeforeControlFlowBlocks.self, at: Syntax(result)),
       let updated = BlankLinesBeforeControlFlowBlocks.insertBlankLines(
         in: Array(result.statements), context: context
       )
    {
      result.statements = CodeBlockItemListSyntax(updated)
    }
    return result
  }

  override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(node)) {
      NoParensAroundConditions.willEnter(node, context: context)
    }
    if context.shouldRewrite(SwitchCaseIndentation.self, at: Syntax(node)) {
      SwitchCaseIndentation.willEnter(node, context: context)
    }
    let visited = super.visit(node)
    let result: ExprSyntax
    if var concrete = visited.as(SwitchExprSyntax.self) {
      if context.shouldRewrite(BlankLinesAfterSwitchCase.self, at: Syntax(concrete)) {
        concrete = BlankLinesAfterSwitchCase.apply(concrete, context: context)
      }
      if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(concrete)),
         let stripped = NoParensAroundConditions.minimalSingleExpression(concrete.subject, context: context)
      {
        concrete.subject = stripped
        NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.switchKeyword.trailingTrivia)
      }
      if context.shouldRewrite(SwitchCaseIndentation.self, at: Syntax(concrete)) {
        concrete = SwitchCaseIndentation.apply(concrete, context: context)
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(SwitchExprSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ConsistentSwitchCaseSpacing.self, at: Syntax(concrete)) {
        concrete = ConsistentSwitchCaseSpacing.apply(concrete, context: context)
      }
      result = ExprSyntax(concrete)
    } else {
      result = visited
    }
    return result
  }

  override func visit(_ node: TernaryExprSyntax) -> ExprSyntax {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    let result: ExprSyntax
    if var concrete = visited.as(TernaryExprSyntax.self) {
      if context.shouldRewrite(NoVoidTernary.self, at: Syntax(concrete)),
         let next = NoVoidTernary.transform(concrete, parent: parent, context: context).as(TernaryExprSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapTernary.self, at: Syntax(concrete)),
         let next = WrapTernary.transform(concrete, parent: parent, context: context).as(TernaryExprSyntax.self)
      {
        concrete = next
      }
      result = ExprSyntax(concrete)
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
    let visited = super.visit(node)
    if var concrete = visited.as(TryExprSyntax.self) {
      if context.shouldRewrite(NoForceTry.self, at: Syntax(concrete)) {
        concrete = NoForceTry.rewriteTryExpr(concrete, context: context)
      }
      return ExprSyntax(concrete)
    }
    return visited
  }

  override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
    let parent = Syntax(node).parent
    var current: DeclSyntax = super.visit(node)
    if let concrete = current.as(TypeAliasDeclSyntax.self) {
      if context.shouldRewrite(DocCommentsPrecedeModifiers.self, at: Syntax(concrete)) {
        current = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "DocCommentsPrecedeModifiers: preceding rule widened TypeAliasDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if let concrete = current.as(TypeAliasDeclSyntax.self) {
      if context.shouldRewrite(ModifierOrder.self, at: Syntax(concrete)) {
        current = ModifierOrder.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "ModifierOrder: preceding rule widened TypeAliasDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if let concrete = current.as(TypeAliasDeclSyntax.self) {
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)) {
        current = ModifiersOnSameLine.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "ModifiersOnSameLine: preceding rule widened TypeAliasDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if let concrete = current.as(TypeAliasDeclSyntax.self) {
      if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(concrete)) {
        current = RedundantAccessControl.transform(concrete, parent: parent, context: context)
      }
    } else {
      assertionFailure(
        "RedundantAccessControl: preceding rule widened TypeAliasDeclSyntax to \(type(of: current)); all subsequent rules in this chain are skipped"
      )
    }
    if let concrete = current.as(TypeAliasDeclSyntax.self) {
      if context.shouldRewrite(TripleSlashDocComments.self, at: Syntax(concrete)) {
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
    let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, at: Syntax(node))
    if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: DeclSyntax
    if var concrete = visited.as(VariableDeclSyntax.self) {
      if context.shouldRewrite(AvoidNoneName.self, at: Syntax(concrete)),
         let next = AvoidNoneName.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(DocCommentsPrecedeModifiers.self, at: Syntax(concrete)),
         let next = DocCommentsPrecedeModifiers.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifierOrder.self, at: Syntax(concrete)),
         let next = ModifierOrder.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(ModifiersOnSameLine.self, at: Syntax(concrete)),
         let next = ModifiersOnSameLine.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(PrivateStateVariables.self, at: Syntax(concrete)),
         let next = PrivateStateVariables.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantAccessControl.self, at: Syntax(concrete)),
         let next = RedundantAccessControl.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantNilInit.self, at: Syntax(concrete)),
         let next = RedundantNilInit.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantObjc.self, at: Syntax(concrete)),
         let next = RedundantObjc.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantPattern.self, at: Syntax(concrete)),
         let next = RedundantPattern.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantSetterACL.self, at: Syntax(concrete)),
         let next = RedundantSetterACL.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantType.self, at: Syntax(concrete)),
         let next = RedundantType.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(RedundantViewBuilder.self, at: Syntax(concrete)),
         let next = RedundantViewBuilder.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(TripleSlashDocComments.self, at: Syntax(concrete)),
         let next = TripleSlashDocComments.transform(concrete, parent: parent, context: context).as(VariableDeclSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(StrongOutlets.self, at: Syntax(concrete)) {
        concrete = StrongOutlets.apply(concrete, context: context)
      }
      result = DeclSyntax(concrete)
    } else {
      result = visited
    }
    if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
    return result
  }

  override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
    let parent = Syntax(node).parent
    let runWrapSingleLineBodies = context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(node))
    if runWrapSingleLineBodies { WrapSingleLineBodies.willEnter(node, context: context) }
    let visited = super.visit(node)
    let result: StmtSyntax
    if var concrete = visited.as(WhileStmtSyntax.self) {
      if context.shouldRewrite(NoParensAroundConditions.self, at: Syntax(concrete)) {
        NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.whileKeyword.trailingTrivia)
      }
      if context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(concrete)),
         let next = WrapMultilineStatementBraces.transform(concrete, parent: parent, context: context).as(WhileStmtSyntax.self)
      {
        concrete = next
      }
      if context.shouldRewrite(WrapSingleLineBodies.self, at: Syntax(concrete)),
         let next = WrapSingleLineBodies.transform(concrete, parent: parent, context: context).as(WhileStmtSyntax.self)
      {
        concrete = next
      }
      result = StmtSyntax(concrete)
    } else {
      result = visited
    }
    if runWrapSingleLineBodies { WrapSingleLineBodies.didExit(node, context: context) }
    return result
  }
}
