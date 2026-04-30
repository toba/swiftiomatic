// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors Licensed under Apache License
// v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information See https://swift.org/CONTRIBUTORS.txt
// for the list of Swift project authors
//
// ===----------------------------------------------------------------------===//

// sm:ignore-file: fileLength, typeBodyLength, functionBodyLength

import SwiftSyntax

/// The combined node-local rewrite stage that dispatches every `StaticFormatRule` in a single
/// tree walk. Each `visit(_:)` override defers to `super.visit` to recurse children, then applies
/// every rule that opted into `static func transform(_:context:)` for that node type.
///
/// Rules are dispatched in alphabetical order by type name; same-node-type interactions should be
/// expressed via `MustRunAfter` (future) or by composing transforms inside a single rule.
final class RewritePipeline: SyntaxRewriter {
    let context: Context

    init(context: Context) {
        self.context = context
        super.init()
    }

    // MARK: - Helpers

    /// Apply a rule whose `transform` returns the same concrete type as
    /// `concrete` (or a wider type that still represents the same node kind).
    /// If the result widens to a different kind, the rewrite is silently
    /// dropped — matching the legacy `if let next = … .as(N.self) { … }`
    /// behaviour at every call site this replaces.
    @inline(__always)
    private func apply<N: SyntaxProtocol, R: SyntaxRule>(
        _ rule: R.Type,
        to concrete: inout N,
        gate: Context.Gate,
        _ body: (N, Context) -> some SyntaxProtocol
    ) {
        guard context.shouldRewrite(R.self, gate: gate) else { return }
        if let next = body(concrete, context).as(N.self) { concrete = next }
    }

    /// Apply a rule whose `transform` may widen `concrete` to a different
    /// node kind. Returns the widened value when the kind changed (caller
    /// should propagate / early-return); returns `nil` otherwise (caller
    /// continues the chain).
    @inline(__always)
    private func applyWidening<N: SyntaxProtocol, R: SyntaxRule, W: SyntaxProtocol>(
        _ rule: R.Type,
        to concrete: inout N,
        gate: Context.Gate,
        _ body: (N, Context) -> W
    ) -> W? {
        guard context.shouldRewrite(R.self, gate: gate) else { return nil }
        let widened = body(concrete, context)
        if let still = widened.as(N.self) {
            concrete = still
            return nil
        }
        return widened
    }

    /// Apply a rule whose `transform` returns the same wider supertype, with
    /// an `assertionFailure` if a preceding rule has already widened
    /// `current` away from the expected concrete kind. Mirrors the legacy
    /// `if let concrete = current.as(N.self) { … } else { assertionFailure(…) }`
    /// idiom used for `TypeAliasDecl`, `EnumCaseDecl`, etc.
    @inline(__always)
    private func applyAsserting<N: SyntaxProtocol, R: SyntaxRule, W: SyntaxProtocol>(
        _ rule: R.Type,
        to current: inout W,
        as concreteType: N.Type,
        gate: Context.Gate,
        _ body: (N, Context) -> W
    ) {
        guard let concrete = current.as(N.self) else {
            assertionFailure(
                "\(R.self): preceding rule widened \(N.self) to \(type(of: current)); all subsequent rules in this chain are skipped"
            )
            return
        }
        guard context.shouldRewrite(R.self, gate: gate) else { return }
        current = body(concrete, context)
    }

    // MARK: - visit overrides

    override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
        defer { if runRedundantSelf { RedundantSelf.didExit(node, context: context) } }
        var result = super.visit(node)
        apply(ProtocolAccessorOrder.self, to: &result, gate: gate) {
            ProtocolAccessorOrder.transform($0, parent: parent, context: $1)
        }
        return result
    }

    override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
        defer { if runRedundantSelf { RedundantSelf.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard var concrete = visited.as(AccessorDeclSyntax.self) else { return visited }
        apply(WrapSingleLineBodies.self, to: &concrete, gate: gate) {
            WrapSingleLineBodies.transform($0, parent: parent, context: $1)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runPreferSelfType = context.shouldRewrite(PreferSelfType.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)
        if runPreferSelfType { PreferSelfType.willEnter(node, context: context) }
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
        defer {
            if runPreferSelfType { PreferSelfType.didExit(node, context: context) }
            if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(ActorDeclSyntax.self) else { return visited }
        apply(DocCommentsPrecedeModifiers.self, to: &concrete, gate: gate) {
            DocCommentsPrecedeModifiers.transform($0, parent: parent, context: $1)
        }
        apply(ModifierOrder.self, to: &concrete, gate: gate) {
            ModifierOrder.transform($0, parent: parent, context: $1)
        }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(RedundantAccessControl.self, to: &concrete, gate: gate) {
            RedundantAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(SimplifyGenericConstraints.self, to: &concrete, gate: gate) {
            SimplifyGenericConstraints.transform($0, parent: parent, context: $1)
        }
        if context.shouldRewrite(RedundantSwiftTestingSuite.self, gate: gate) {
            concrete = RedundantSwiftTestingSuite.removeSuite(
                from: concrete, keyword: \.actorKeyword, context: context
            )
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: AsExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        defer { if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard let concrete = visited.as(AsExprSyntax.self) else { return visited }
        if context.shouldRewrite(NoForceCast.self, gate: gate),
           concrete.questionOrExclamationMark?.tokenKind == .exclamationMark
        {
            NoForceCast.diagnose(
                .doNotForceCast(name: concrete.type.trimmedDescription),
                on: concrete.asKeyword, context: context
            )
        }
        if context.shouldRewrite(NoForceUnwrap.self, gate: gate),
           concrete.questionOrExclamationMark?.tokenKind == .exclamationMark
        {
            return NoForceUnwrap.rewriteAsExpr(concrete, context: context)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: AssociatedTypeDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current: DeclSyntax = super.visit(node)
        applyAsserting(
            ModifiersOnSameLine.self,
            to: &current,
            as: AssociatedTypeDeclSyntax.self,
            gate: gate
        ) { ModifiersOnSameLine.transform($0, parent: parent, context: $1) }
        return current
    }

    override func visit(_ node: AttributeSyntax) -> AttributeSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        apply(PreferMainAttribute.self, to: &node, gate: gate) {
            PreferMainAttribute.transform($0, parent: parent, context: $1)
        }
        return node
    }

    override func visit(_ node: AttributedTypeSyntax) -> TypeSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current: TypeSyntax = super.visit(node)
        applyAsserting(
            NoExplicitOwnership.self,
            to: &current,
            as: AttributedTypeSyntax.self,
            gate: gate
        ) { NoExplicitOwnership.transform($0, parent: parent, context: $1) }
        return current
    }

    override func visit(_ node: AwaitExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runHoistTry = context.shouldRewrite(HoistTry.self, gate: gate)
        if runHoistTry { HoistTry.willEnter(node, context: context) }
        defer { if runHoistTry { HoistTry.didExit(node, context: context) } }
        var current: ExprSyntax = super.visit(node)
        applyAsserting(HoistTry.self, to: &current, as: AwaitExprSyntax.self, gate: gate) {
            HoistTry.transform($0, parent: parent, context: $1)
        }
        return current
    }

    override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        apply(RedundantLetError.self, to: &node, gate: gate) {
            RedundantLetError.transform($0, parent: parent, context: $1)
        }
        return node
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runNoForceTry = context.shouldRewrite(NoForceTry.self, gate: gate)
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        let runNoGuardInTests = context.shouldRewrite(NoGuardInTests.self, gate: gate)
        let runPreferSelfType = context.shouldRewrite(PreferSelfType.self, gate: gate)
        let runPreferSwiftTesting = context.shouldRewrite(PreferSwiftTesting.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)
        if runNoForceTry { NoForceTry.willEnter(node, context: context) }
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        if runNoGuardInTests { NoGuardInTests.willEnter(node, context: context) }
        if runPreferSelfType { PreferSelfType.willEnter(node, context: context) }
        if runPreferSwiftTesting { PreferSwiftTesting.willEnter(node, context: context) }
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
        defer {
            if runNoForceTry { NoForceTry.didExit(node, context: context) }
            if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
            if runNoGuardInTests { NoGuardInTests.didExit(node, context: context) }
            if runPreferSelfType { PreferSelfType.didExit(node, context: context) }
            if runPreferSwiftTesting { PreferSwiftTesting.didExit(node, context: context) }
            if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(ClassDeclSyntax.self) else { return visited }
        apply(DocCommentsPrecedeModifiers.self, to: &concrete, gate: gate) {
            DocCommentsPrecedeModifiers.transform($0, parent: parent, context: $1)
        }
        apply(ModifierOrder.self, to: &concrete, gate: gate) {
            ModifierOrder.transform($0, parent: parent, context: $1)
        }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(PreferFinalClasses.self, to: &concrete, gate: gate) {
            PreferFinalClasses.transform($0, parent: parent, context: $1)
        }
        apply(PreferStaticOverClassFunc.self, to: &concrete, gate: gate) {
            PreferStaticOverClassFunc.transform($0, parent: parent, context: $1)
        }
        apply(PreferSwiftTesting.self, to: &concrete, gate: gate) {
            PreferSwiftTesting.transform($0, parent: parent, context: $1)
        }
        apply(RedundantAccessControl.self, to: &concrete, gate: gate) {
            RedundantAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(RedundantObjc.self, to: &concrete, gate: gate) {
            RedundantObjc.transform($0, parent: parent, context: $1)
        }
        apply(SimplifyGenericConstraints.self, to: &concrete, gate: gate) {
            SimplifyGenericConstraints.transform($0, parent: parent, context: $1)
        }
        apply(TestSuiteAccessControl.self, to: &concrete, gate: gate) {
            TestSuiteAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(TripleSlashDocComments.self, to: &concrete, gate: gate) {
            TripleSlashDocComments.transform($0, parent: parent, context: $1)
        }
        apply(ValidateTestCases.self, to: &concrete, gate: gate) {
            ValidateTestCases.transform($0, parent: parent, context: $1)
        }
        if context.shouldRewrite(RedundantFinal.self, gate: gate) {
            concrete = RedundantFinal.apply(concrete, context: context)
        }
        if context.shouldRewrite(RedundantSwiftTestingSuite.self, gate: gate) {
            concrete = RedundantSwiftTestingSuite.removeSuite(
                from: concrete, keyword: \.classKeyword, context: context
            )
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        // StaticStructShouldBeEnum runs last because it can widen the class to an `EnumDeclSyntax` .
        if context.shouldRewrite(StaticStructShouldBeEnum.self, gate: gate) {
            return StaticStructShouldBeEnum.transform(concrete, parent: parent, context: context)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runNamedClosureParams = context.shouldRewrite(NamedClosureParams.self, gate: gate)
        let runNoForceTry = context.shouldRewrite(NoForceTry.self, gate: gate)
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        let runNoGuardInTests = context.shouldRewrite(NoGuardInTests.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)
        if runNamedClosureParams { NamedClosureParams.willEnter(node, context: context) }
        if runNoForceTry { NoForceTry.willEnter(node, context: context) }
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        if runNoGuardInTests { NoGuardInTests.willEnter(node, context: context) }
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
        defer {
            if runNamedClosureParams { NamedClosureParams.didExit(node, context: context) }
            if runNoForceTry { NoForceTry.didExit(node, context: context) }
            if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
            if runNoGuardInTests { NoGuardInTests.didExit(node, context: context) }
            if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(ClosureExprSyntax.self) else { return visited }
        apply(RedundantReturn.self, to: &concrete, gate: gate) {
            RedundantReturn.transform($0, parent: parent, context: $1)
        }
        apply(UnusedArguments.self, to: &concrete, gate: gate) {
            UnusedArguments.transform($0, parent: parent, context: $1)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(PreferVoidReturn.self, gate: gate) {
            PreferVoidReturn.willEnter(node, context: context)
        }
        var result = super.visit(node)
        if context.shouldRewrite(NoParensInClosureParams.self, gate: gate) {
            result = NoParensInClosureParams.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(PreferVoidReturn.self, gate: gate) {
            result = PreferVoidReturn.apply(result, context: context)
        }
        return result
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(NoSemicolons.self, gate: gate) {
            NoSemicolons.willEnter(node, context: context)
        }
        if context.shouldRewrite(OneDeclarationPerLine.self, gate: gate) {
            OneDeclarationPerLine.willEnter(node, context: context)
        }
        if context.shouldRewrite(PreferEarlyExits.self, gate: gate) {
            PreferEarlyExits.willEnter(node, context: context)
        }
        var result = super.visit(node)
        if context.shouldRewrite(EmptyExtensions.self, gate: gate) {
            result = EmptyExtensions.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(NoAssignmentInExpressions.self, gate: gate) {
            result = NoAssignmentInExpressions.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(NoSemicolons.self, gate: gate) {
            result = NoSemicolons.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(OneDeclarationPerLine.self, gate: gate) {
            result = OneDeclarationPerLine.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(PreferConditionalExpression.self, gate: gate) {
            result = PreferConditionalExpression.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(PreferIfElseChain.self, gate: gate) {
            result = PreferIfElseChain.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(PreferTernary.self, gate: gate) {
            result = PreferTernary.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(RedundantLet.self, gate: gate) {
            result = RedundantLet.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(RedundantProperty.self, gate: gate) {
            result = RedundantProperty.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(PreferEarlyExits.self, gate: gate) {
            result = PreferEarlyExits.apply(result, context: context)
        }
        if context.shouldRewrite(NoGuardInTests.self, gate: gate) {
            result = NoGuardInTests.transform(result, parent: parent, context: context)
        }
        return result
    }

    override func visit(_ node: CodeBlockItemSyntax) -> CodeBlockItemSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(ConvertRegularCommentToDocC.self, gate: gate) {
            node = ConvertRegularCommentToDocC.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        if context.shouldRewrite(BlankLinesBeforeControlFlowBlocks.self, gate: gate) {
            BlankLinesBeforeControlFlowBlocks.willEnter(node, context: context)
        }
        var result = super.visit(node)
        if context.shouldRewrite(BlankLinesAfterGuardStatements.self, gate: gate) {
            result = BlankLinesAfterGuardStatements.apply(result, context: context)
        }
        if context.shouldRewrite(BlankLinesBeforeControlFlowBlocks.self, gate: gate),
           let updated = BlankLinesBeforeControlFlowBlocks.insertBlankLines(
               in: Array(result.statements), context: context
           )
        {
            result.statements = CodeBlockItemListSyntax(updated)
        }
        return result
    }

    override func visit(_ node: ConditionElementListSyntax) -> ConditionElementListSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(PreferCommaConditions.self, gate: gate) {
            node = PreferCommaConditions.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: ConditionElementSyntax) -> ConditionElementSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.willEnter(node, context: context)
        }
        var result = super.visit(node)
        if context.shouldRewrite(ExplicitNilCheck.self, gate: gate) {
            result = ExplicitNilCheck.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate),
           case let .expression(condition) = result.condition,
           let stripped = NoParensAroundConditions.minimalSingleExpression(
               condition, context: context)
        {
            result.condition = .expression(stripped)
        }
        return result
    }

    override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(ACLConsistency.self, gate: gate) {
            node = ACLConsistency.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let visited = super.visit(node)
        if let concrete = visited.as(DeclReferenceExprSyntax.self),
           context.shouldRewrite(NamedClosureParams.self, gate: gate)
        {
            NamedClosureParams.rewriteDeclReference(concrete, context: context)
        }
        return visited
    }

    override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard var concrete = visited.as(DeinitializerDeclSyntax.self) else { return visited }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(TripleSlashDocComments.self, to: &concrete, gate: gate) {
            TripleSlashDocComments.transform($0, parent: parent, context: $1)
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard var concrete = visited.as(DoStmtSyntax.self) else { return visited }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        return StmtSyntax(concrete)
    }

    override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current: DeclSyntax = super.visit(node)
        applyAsserting(
            ModifiersOnSameLine.self, to: &current, as: EnumCaseDeclSyntax.self, gate: gate
        ) { ModifiersOnSameLine.transform($0, parent: parent, context: $1) }
        applyAsserting(
            RedundantRawValues.self, to: &current, as: EnumCaseDeclSyntax.self, gate: gate
        ) { RedundantRawValues.transform($0, parent: parent, context: $1) }
        return current
    }

    override func visit(_ node: EnumCaseElementSyntax) -> EnumCaseElementSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(AvoidNoneName.self, gate: gate) {
            node = AvoidNoneName.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runPreferSelfType = context.shouldRewrite(PreferSelfType.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)

        if context.shouldRewrite(OneDeclarationPerLine.self, gate: gate) {
            OneDeclarationPerLine.willEnter(node, context: context)
        }
        if runPreferSelfType { PreferSelfType.willEnter(node, context: context) }
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }

        defer {
            if runPreferSelfType { PreferSelfType.didExit(node, context: context) }
            if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)

        guard var concrete = visited.as(EnumDeclSyntax.self) else { return visited }

        apply(CollapseSimpleEnums.self, to: &concrete, gate: gate) {
            CollapseSimpleEnums.transform($0, parent: parent, context: $1)
        }
        apply(DocCommentsPrecedeModifiers.self, to: &concrete, gate: gate) {
            DocCommentsPrecedeModifiers.transform($0, parent: parent, context: $1)
        }
        apply(IndirectEnum.self, to: &concrete, gate: gate) {
            IndirectEnum.transform($0, parent: parent, context: $1)
        }
        apply(ModifierOrder.self, to: &concrete, gate: gate) {
            ModifierOrder.transform($0, parent: parent, context: $1)
        }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(OneDeclarationPerLine.self, to: &concrete, gate: gate) {
            OneDeclarationPerLine.transform($0, parent: parent, context: $1)
        }
        apply(RedundantAccessControl.self, to: &concrete, gate: gate) {
            RedundantAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(RedundantObjc.self, to: &concrete, gate: gate) {
            RedundantObjc.transform($0, parent: parent, context: $1)
        }
        apply(RedundantSendable.self, to: &concrete, gate: gate) {
            RedundantSendable.transform($0, parent: parent, context: $1)
        }
        apply(SimplifyGenericConstraints.self, to: &concrete, gate: gate) {
            SimplifyGenericConstraints.transform($0, parent: parent, context: $1)
        }
        apply(TripleSlashDocComments.self, to: &concrete, gate: gate) {
            TripleSlashDocComments.transform($0, parent: parent, context: $1)
        }
        apply(ValidateTestCases.self, to: &concrete, gate: gate) {
            ValidateTestCases.transform($0, parent: parent, context: $1)
        }
        if context.shouldRewrite(RedundantSwiftTestingSuite.self, gate: gate) {
            concrete = RedundantSwiftTestingSuite.removeSuite(
                from: concrete, keyword: \.enumKeyword, context: context
            )
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runPreferSelfType = context.shouldRewrite(PreferSelfType.self, gate: gate)
        let runPreferSwiftTesting = context.shouldRewrite(PreferSwiftTesting.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)

        if runPreferSelfType { PreferSelfType.willEnter(node, context: context) }
        if runPreferSwiftTesting { PreferSwiftTesting.willEnter(node, context: context) }
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }

        defer {
            if runPreferSelfType { PreferSelfType.didExit(node, context: context) }
            if runPreferSwiftTesting { PreferSwiftTesting.didExit(node, context: context) }
            if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)

        guard var concrete = visited.as(ExtensionDeclSyntax.self) else { return visited }

        apply(DocCommentsPrecedeModifiers.self, to: &concrete, gate: gate) {
            DocCommentsPrecedeModifiers.transform($0, parent: parent, context: $1)
        }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(PreferAngleBracketExtensions.self, to: &concrete, gate: gate) {
            PreferAngleBracketExtensions.transform($0, parent: parent, context: $1)
        }
        apply(RedundantAccessControl.self, to: &concrete, gate: gate) {
            RedundantAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(TripleSlashDocComments.self, to: &concrete, gate: gate) {
            TripleSlashDocComments.transform($0, parent: parent, context: $1)
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runWrapSingleLineBodies = context.shouldRewrite(WrapSingleLineBodies.self, gate: gate)
        if runWrapSingleLineBodies { WrapSingleLineBodies.willEnter(node, context: context) }
        defer {
            if runWrapSingleLineBodies { WrapSingleLineBodies.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(ForStmtSyntax.self) else { return visited }
        apply(CaseLet.self, to: &concrete, gate: gate) {
            CaseLet.transform($0, parent: parent, context: $1)
        }
        apply(PreferWhereClausesInForLoops.self, to: &concrete, gate: gate) {
            PreferWhereClausesInForLoops.transform($0, parent: parent, context: $1)
        }
        apply(RedundantEnumerated.self, to: &concrete, gate: gate) {
            RedundantEnumerated.transform($0, parent: parent, context: $1)
        }
        apply(UnusedArguments.self, to: &concrete, gate: gate) {
            UnusedArguments.transform($0, parent: parent, context: $1)
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        apply(WrapSingleLineBodies.self, to: &concrete, gate: gate) {
            WrapSingleLineBodies.transform($0, parent: parent, context: $1)
        }
        return StmtSyntax(concrete)
    }

    override func visit(_ node: ForceUnwrapExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)

        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        defer { if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) } }

        let visited = super.visit(node)
        guard var concrete = visited.as(ForceUnwrapExprSyntax.self) else { return visited }

        if context.shouldRewrite(URLMacro.self, gate: gate) {
            let widened = URLMacro.transform(concrete, parent: parent, context: context)
            if let stillForce = widened.as(ForceUnwrapExprSyntax.self) {
                concrete = stillForce
            } else {
                return widened
            }
        }
        if context.shouldRewrite(NoForceUnwrap.self, gate: gate) {
            return NoForceUnwrap.rewriteForceUnwrap(concrete, context: context)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        let runPreferSwiftTesting = context.shouldRewrite(PreferSwiftTesting.self, gate: gate)
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        if context.shouldRewrite(NoTrailingClosureParens.self, gate: gate) {
            NoTrailingClosureParens.willEnter(node, context: context)
        }
        if runPreferSwiftTesting { PreferSwiftTesting.willEnter(node, context: context) }
        defer {
            if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
            if runPreferSwiftTesting { PreferSwiftTesting.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(FunctionCallExprSyntax.self) else { return visited }
        // HoistAwait may widen `foo(await x)` to `await foo(x)` .
        if let widened = applyWidening(HoistAwait.self, to: &concrete, gate: gate, {
            HoistAwait.transform($0, parent: parent, context: $1)
        }) { return widened }
        // HoistTry may widen `foo(try x)` to `try foo(x)` .
        if let widened = applyWidening(HoistTry.self, to: &concrete, gate: gate, {
            HoistTry.transform($0, parent: parent, context: $1)
        }) { return widened }
        apply(PreferAssertionFailure.self, to: &concrete, gate: gate) {
            PreferAssertionFailure.transform($0, parent: parent, context: $1)
        }
        // PreferSwiftTesting may widen `FunctionCallExpr` to `MacroExpansionExpr` .
        if let widened = applyWidening(PreferSwiftTesting.self, to: &concrete, gate: gate, {
            PreferSwiftTesting.transform($0, parent: parent, context: $1)
        }) { return widened }
        // PreferDotZero may widen the call to a `MemberAccessExpr` .
        if let widened = applyWidening(PreferDotZero.self, to: &concrete, gate: gate, {
            PreferDotZero.transform($0, parent: parent, context: $1)
        }) { return widened }
        apply(PreferKeyPath.self, to: &concrete, gate: gate) {
            PreferKeyPath.transform($0, parent: parent, context: $1)
        }
        // RedundantClosure may unwrap `{ x }()` to `x` (any `ExprSyntax` ).
        if let widened = applyWidening(RedundantClosure.self, to: &concrete, gate: gate, {
            RedundantClosure.transform($0, parent: parent, context: $1)
        }) { return widened }
        apply(RedundantInit.self, to: &concrete, gate: gate) {
            RedundantInit.transform($0, parent: parent, context: $1)
        }
        apply(RequireFatalErrorMessage.self, to: &concrete, gate: gate) {
            RequireFatalErrorMessage.transform($0, parent: parent, context: $1)
        }
        if context.shouldRewrite(NoTrailingClosureParens.self, gate: gate) {
            concrete = NoTrailingClosureParens.apply(concrete, context: context)
        }
        if context.shouldRewrite(PreferTrailingClosures.self, gate: gate) {
            concrete = PreferTrailingClosures.apply(concrete, context: context)
        }
        if context.shouldRewrite(WrapMultilineFunctionChains.self, gate: gate) {
            concrete = WrapMultilineFunctionChains.apply(concrete, context: context)
        }
        // NestedCallLayout may produce a different ExprSyntax kind.
        var resultExpr = ExprSyntax(concrete)
        if context.shouldRewrite(NestedCallLayout.self, gate: gate) {
            resultExpr = NestedCallLayout.transform(concrete, parent: parent, context: context)
            if let typed = resultExpr.as(FunctionCallExprSyntax.self) { concrete = typed }
        }
        // NoForceUnwrap chain-top wrapping at this call.
        if context.shouldRewrite(NoForceUnwrap.self, gate: gate) {
            return NoForceUnwrap.rewriteFunctionCallTop(concrete, context: context)
        }
        return resultExpr
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runNoForceTry = context.shouldRewrite(NoForceTry.self, gate: gate)
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        let runNoGuardInTests = context.shouldRewrite(NoGuardInTests.self, gate: gate)
        let runPreferSwiftTesting = context.shouldRewrite(PreferSwiftTesting.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)
        if runNoForceTry { NoForceTry.willEnter(node, context: context) }
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        if runNoGuardInTests { NoGuardInTests.willEnter(node, context: context) }
        if runPreferSwiftTesting { PreferSwiftTesting.willEnter(node, context: context) }
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
        defer {
            if runNoForceTry { NoForceTry.didExit(node, context: context) }
            if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
            if runNoGuardInTests { NoGuardInTests.didExit(node, context: context) }
            if runPreferSwiftTesting { PreferSwiftTesting.didExit(node, context: context) }
            if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(FunctionDeclSyntax.self) else { return visited }
        apply(DocCommentsPrecedeModifiers.self, to: &concrete, gate: gate) {
            DocCommentsPrecedeModifiers.transform($0, parent: parent, context: $1)
        }
        apply(ModifierOrder.self, to: &concrete, gate: gate) {
            ModifierOrder.transform($0, parent: parent, context: $1)
        }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(NoExplicitOwnership.self, to: &concrete, gate: gate) {
            NoExplicitOwnership.transform($0, parent: parent, context: $1)
        }
        apply(NoGuardInTests.self, to: &concrete, gate: gate) {
            NoGuardInTests.transform($0, parent: parent, context: $1)
        }
        apply(OpaqueGenericParameters.self, to: &concrete, gate: gate) {
            OpaqueGenericParameters.transform($0, parent: parent, context: $1)
        }
        apply(RedundantAccessControl.self, to: &concrete, gate: gate) {
            RedundantAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(RedundantAsync.self, to: &concrete, gate: gate) {
            RedundantAsync.transform($0, parent: parent, context: $1)
        }
        apply(RedundantObjc.self, to: &concrete, gate: gate) {
            RedundantObjc.transform($0, parent: parent, context: $1)
        }
        apply(RedundantReturn.self, to: &concrete, gate: gate) {
            RedundantReturn.transform($0, parent: parent, context: $1)
        }
        apply(RedundantThrows.self, to: &concrete, gate: gate) {
            RedundantThrows.transform($0, parent: parent, context: $1)
        }
        apply(RedundantViewBuilder.self, to: &concrete, gate: gate) {
            RedundantViewBuilder.transform($0, parent: parent, context: $1)
        }
        apply(SimplifyGenericConstraints.self, to: &concrete, gate: gate) {
            SimplifyGenericConstraints.transform($0, parent: parent, context: $1)
        }
        apply(SwiftTestingTestCaseNames.self, to: &concrete, gate: gate) {
            SwiftTestingTestCaseNames.transform($0, parent: parent, context: $1)
        }
        apply(TripleSlashDocComments.self, to: &concrete, gate: gate) {
            TripleSlashDocComments.transform($0, parent: parent, context: $1)
        }
        apply(UnusedArguments.self, to: &concrete, gate: gate) {
            UnusedArguments.transform($0, parent: parent, context: $1)
        }
        apply(UseImplicitInit.self, to: &concrete, gate: gate) {
            UseImplicitInit.transform($0, parent: parent, context: $1)
        }
        // NoForceTry — after children visit, add a `throws` clause if any inner `try!` was converted.
        if context.shouldRewrite(NoForceTry.self, gate: gate) {
            concrete = NoForceTry.afterFunctionDecl(concrete, context: context)
        }
        // NoForceUnwrap — same pattern.
        if context.shouldRewrite(NoForceUnwrap.self, gate: gate) {
            concrete = NoForceUnwrap.afterFunctionDecl(concrete, context: context)
        }
        apply(RedundantEscaping.self, to: &concrete, gate: gate) {
            RedundantEscaping.transform($0, parent: parent, context: $1)
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        apply(WrapSingleLineBodies.self, to: &concrete, gate: gate) {
            WrapSingleLineBodies.transform($0, parent: parent, context: $1)
        }
        // PreferSwiftTesting may widen `FunctionDecl` to `InitializerDecl` /
        // `DeinitializerDecl` ; early-return on kind change.
        if let widened = applyWidening(PreferSwiftTesting.self, to: &concrete, gate: gate, {
            PreferSwiftTesting.transform($0, parent: parent, context: $1)
        }) { return widened }
        // RedundantOverride may delete `override` declarations entirely.
        if context.shouldRewrite(RedundantOverride.self, gate: gate) {
            return RedundantOverride.transform(concrete, parent: parent, context: context)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: FunctionEffectSpecifiersSyntax) -> FunctionEffectSpecifiersSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(RedundantTypedThrows.self, gate: gate) {
            node = RedundantTypedThrows.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(EmptyCollectionLiteral.self, gate: gate) {
            node = EmptyCollectionLiteral.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: FunctionSignatureSyntax) -> FunctionSignatureSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        var result = super.visit(node)
        if context.shouldRewrite(NoVoidReturnOnFunctionSignature.self, gate: gate) {
            result = NoVoidReturnOnFunctionSignature.apply(result, context: context)
        }
        return result
    }

    override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(PreferVoidReturn.self, gate: gate) {
            PreferVoidReturn.willEnter(node, context: context)
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(FunctionTypeSyntax.self) else { return visited }
        apply(RedundantTypedThrows.self, to: &concrete, gate: gate) {
            RedundantTypedThrows.transform($0, parent: parent, context: $1)
        }
        if context.shouldRewrite(PreferVoidReturn.self, gate: gate) {
            concrete = PreferVoidReturn.apply(concrete, context: context)
        }
        return TypeSyntax(concrete)
    }

    override func visit(_ node: GenericSpecializationExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(PreferShorthandTypeNames.self, gate: gate) {
            PreferShorthandTypeNames.willEnter(node, context: context)
        }
        var result: ExprSyntax = super.visit(node)
        if context.shouldRewrite(PreferShorthandTypeNames.self, gate: gate),
           let typed = result.as(GenericSpecializationExprSyntax.self)
        {
            result = PreferShorthandTypeNames.transform(typed, parent: parent, context: context)
        }
        return result
    }

    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runWrapSingleLineBodies = context.shouldRewrite(WrapSingleLineBodies.self, gate: gate)
        if runWrapSingleLineBodies { WrapSingleLineBodies.willEnter(node, context: context) }
        defer {
            if runWrapSingleLineBodies { WrapSingleLineBodies.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(GuardStmtSyntax.self) else { return visited }
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.guardKeyword.trailingTrivia)
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        apply(WrapSingleLineBodies.self, to: &concrete, gate: gate) {
            WrapSingleLineBodies.transform($0, parent: parent, context: $1)
        }
        return StmtSyntax(concrete)
    }

    override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(PreferShorthandTypeNames.self, gate: gate) {
            PreferShorthandTypeNames.willEnter(node, context: context)
        }
        var result: TypeSyntax = super.visit(node)
        if context.shouldRewrite(PreferShorthandTypeNames.self, gate: gate),
           let typed = result.as(IdentifierTypeSyntax.self)
        {
            result = PreferShorthandTypeNames.transform(typed, parent: parent, context: context)
        }
        return result
    }

    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runWrapSingleLineBodies = context.shouldRewrite(WrapSingleLineBodies.self, gate: gate)
        if runWrapSingleLineBodies { WrapSingleLineBodies.willEnter(node, context: context) }
        defer {
            if runWrapSingleLineBodies { WrapSingleLineBodies.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(IfExprSyntax.self) else { return visited }
        apply(CollapseSimpleIfElse.self, to: &concrete, gate: gate) {
            CollapseSimpleIfElse.transform($0, parent: parent, context: $1)
        }
        apply(PreferUnavailable.self, to: &concrete, gate: gate) {
            PreferUnavailable.transform($0, parent: parent, context: $1)
        }
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.ifKeyword.trailingTrivia)
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        apply(WrapSingleLineBodies.self, to: &concrete, gate: gate) {
            WrapSingleLineBodies.transform($0, parent: parent, context: $1)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(NoForceUnwrap.self, gate: gate) {
            NoForceUnwrap.willEnter(node, context: context)
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(ImportDeclSyntax.self) else { return visited }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(PreferSwiftTesting.self, to: &concrete, gate: gate) {
            PreferSwiftTesting.transform($0, parent: parent, context: $1)
        }
        if context.shouldRewrite(RedundantSwiftTestingSuite.self, gate: gate) {
            RedundantSwiftTestingSuite.visitImport(concrete, context: context)
        }
        if context.shouldRewrite(NoForceTry.self, gate: gate) {
            NoForceTry.visitImport(concrete, context: context)
        }
        if context.shouldRewrite(NoForceUnwrap.self, gate: gate) {
            NoForceUnwrap.visitImport(concrete, context: context)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard var concrete = visited.as(InfixOperatorExprSyntax.self) else { return visited }
        apply(NoAssignmentInExpressions.self, to: &concrete, gate: gate) {
            NoAssignmentInExpressions.transform($0, parent: parent, context: $1)
        }
        apply(NoYodaConditions.self, to: &concrete, gate: gate) {
            NoYodaConditions.transform($0, parent: parent, context: $1)
        }
        apply(PreferCompoundAssignment.self, to: &concrete, gate: gate) {
            PreferCompoundAssignment.transform($0, parent: parent, context: $1)
        }
        if let widened = applyWidening(PreferIsEmpty.self, to: &concrete, gate: gate, {
            PreferIsEmpty.transform($0, parent: parent, context: $1)
        }) { return widened }
        if let widened = applyWidening(PreferToggle.self, to: &concrete, gate: gate, {
            PreferToggle.transform($0, parent: parent, context: $1)
        }) { return widened }
        if let widened = applyWidening(RedundantNilCoalescing.self, to: &concrete, gate: gate, {
            RedundantNilCoalescing.transform($0, parent: parent, context: $1)
        }) { return widened }
        apply(WrapConditionalAssignment.self, to: &concrete, gate: gate) {
            WrapConditionalAssignment.transform($0, parent: parent, context: $1)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: InitializerClauseSyntax) -> InitializerClauseSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.willEnter(node, context: context)
        }
        var result = super.visit(node)
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate),
           let stripped = NoParensAroundConditions.minimalSingleExpression(
               result.value, context: context)
        {
            result.value = stripped
        }
        return result
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
        defer { if runRedundantSelf { RedundantSelf.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard var concrete = visited.as(InitializerDeclSyntax.self) else { return visited }
        apply(DocCommentsPrecedeModifiers.self, to: &concrete, gate: gate) {
            DocCommentsPrecedeModifiers.transform($0, parent: parent, context: $1)
        }
        apply(InitCoderUnavailable.self, to: &concrete, gate: gate) {
            InitCoderUnavailable.transform($0, parent: parent, context: $1)
        }
        apply(ModifierOrder.self, to: &concrete, gate: gate) {
            ModifierOrder.transform($0, parent: parent, context: $1)
        }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(OpaqueGenericParameters.self, to: &concrete, gate: gate) {
            OpaqueGenericParameters.transform($0, parent: parent, context: $1)
        }
        apply(RedundantAccessControl.self, to: &concrete, gate: gate) {
            RedundantAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(RedundantObjc.self, to: &concrete, gate: gate) {
            RedundantObjc.transform($0, parent: parent, context: $1)
        }
        apply(TripleSlashDocComments.self, to: &concrete, gate: gate) {
            TripleSlashDocComments.transform($0, parent: parent, context: $1)
        }
        apply(UnusedArguments.self, to: &concrete, gate: gate) {
            UnusedArguments.transform($0, parent: parent, context: $1)
        }
        apply(UseImplicitInit.self, to: &concrete, gate: gate) {
            UseImplicitInit.transform($0, parent: parent, context: $1)
        }
        apply(RedundantEscaping.self, to: &concrete, gate: gate) {
            RedundantEscaping.transform($0, parent: parent, context: $1)
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        apply(WrapSingleLineBodies.self, to: &concrete, gate: gate) {
            WrapSingleLineBodies.transform($0, parent: parent, context: $1)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: IntegerLiteralExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current: ExprSyntax = super.visit(node)
        applyAsserting(
            GroupNumericLiterals.self,
            to: &current,
            as: IntegerLiteralExprSyntax.self,
            gate: gate
        ) { GroupNumericLiterals.transform($0, parent: parent, context: $1) }
        return current
    }

    override func visit(_ node: LabeledExprSyntax) -> LabeledExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(RedundantLet.self, gate: gate) {
            node = RedundantLet.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current: ExprSyntax = super.visit(node)
        applyAsserting(
            PreferFileID.self,
            to: &current,
            as: MacroExpansionExprSyntax.self,
            gate: gate
        ) { PreferFileID.transform($0, parent: parent, context: $1) }
        return current
    }

    override func visit(_ node: MatchingPatternConditionSyntax) -> MatchingPatternConditionSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(CaseLet.self, gate: gate) {
            node = CaseLet.transform(node, parent: parent, context: context)
        }
        if context.shouldRewrite(RedundantPattern.self, gate: gate) {
            node = RedundantPattern.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        defer { if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard var concrete = visited.as(MemberAccessExprSyntax.self) else { return visited }
        if let widened = applyWidening(PreferCountWhere.self, to: &concrete, gate: gate, {
            PreferCountWhere.transform($0, parent: parent, context: $1)
        }) { return widened }
        apply(PreferIsDisjoint.self, to: &concrete, gate: gate) {
            PreferIsDisjoint.transform($0, parent: parent, context: $1)
        }
        apply(PreferSelfType.self, to: &concrete, gate: gate) {
            PreferSelfType.transform($0, parent: parent, context: $1)
        }
        if let widened = applyWidening(RedundantSelf.self, to: &concrete, gate: gate, {
            RedundantSelf.transform($0, parent: parent, context: $1)
        }) { return widened }
        if let widened = applyWidening(RedundantStaticSelf.self, to: &concrete, gate: gate, {
            RedundantStaticSelf.transform($0, parent: parent, context: $1)
        }) { return widened }
        if context.shouldRewrite(NoForceUnwrap.self, gate: gate) {
            return NoForceUnwrap.rewriteMemberAccess(concrete, context: context)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(NoSemicolons.self, gate: gate) {
            NoSemicolons.willEnter(node, context: context)
        }
        var node = super.visit(node)
        if context.shouldRewrite(NoSemicolons.self, gate: gate) {
            node = NoSemicolons.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: MemberBlockItemSyntax) -> MemberBlockItemSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(ConvertRegularCommentToDocC.self, gate: gate) {
            node = ConvertRegularCommentToDocC.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: OptionalBindingConditionSyntax) -> OptionalBindingConditionSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(NoBacktickedSelf.self, gate: gate) {
            node = NoBacktickedSelf.transform(node, parent: parent, context: context)
        }
        if context.shouldRewrite(RedundantOptionalBinding.self, gate: gate) {
            node = RedundantOptionalBinding.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(EmptyCollectionLiteral.self, gate: gate) {
            node = EmptyCollectionLiteral.transform(node, parent: parent, context: context)
        }
        if context.shouldRewrite(PreferSingleLinePropertyGetter.self, gate: gate) {
            node = PreferSingleLinePropertyGetter.transform(node, parent: parent, context: context)
        }
        if context.shouldRewrite(RedundantReturn.self, gate: gate) {
            node = RedundantReturn.transform(node, parent: parent, context: context)
        }
        if context.shouldRewrite(UseImplicitInit.self, gate: gate) {
            node = UseImplicitInit.transform(node, parent: parent, context: context)
        }
        if context.shouldRewrite(WrapConditionalAssignment.self, gate: gate) {
            node = WrapConditionalAssignment.transform(node, parent: parent, context: context)
        }
        if context.shouldRewrite(WrapSingleLineBodies.self, gate: gate) {
            node = WrapSingleLineBodies.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: PrefixOperatorExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var result: ExprSyntax = super.visit(node)
        if context.shouldRewrite(PreferExplicitFalse.self, gate: gate),
           let prefix = result.as(PrefixOperatorExprSyntax.self)
        {
            result = PreferExplicitFalse.transform(prefix, parent: parent, context: context)
        }
        return result
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard var concrete = visited.as(ProtocolDeclSyntax.self) else { return visited }
        apply(DocCommentsPrecedeModifiers.self, to: &concrete, gate: gate) {
            DocCommentsPrecedeModifiers.transform($0, parent: parent, context: $1)
        }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(RedundantAccessControl.self, to: &concrete, gate: gate) {
            RedundantAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(TripleSlashDocComments.self, to: &concrete, gate: gate) {
            TripleSlashDocComments.transform($0, parent: parent, context: $1)
        }
        if context.shouldRewrite(PreferAnyObject.self, gate: gate) {
            concrete = PreferAnyObject.apply(concrete, context: context)
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runWrapSingleLineBodies = context.shouldRewrite(WrapSingleLineBodies.self, gate: gate)
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.willEnter(node, context: context)
        }
        if runWrapSingleLineBodies { WrapSingleLineBodies.willEnter(node, context: context) }
        defer {
            if runWrapSingleLineBodies { WrapSingleLineBodies.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(RepeatStmtSyntax.self) else { return visited }
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate),
           let stripped = NoParensAroundConditions.minimalSingleExpression(
               concrete.condition, context: context)
        {
            concrete.condition = stripped
            NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.whileKeyword.trailingTrivia)
        }
        apply(WrapSingleLineBodies.self, to: &concrete, gate: gate) {
            WrapSingleLineBodies.transform($0, parent: parent, context: $1)
        }
        return StmtSyntax(concrete)
    }

    override func visit(_ node: ReturnStmtSyntax) -> StmtSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.willEnter(node, context: context)
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(ReturnStmtSyntax.self) else { return visited }
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate),
           let expression = concrete.expression,
           let stripped = NoParensAroundConditions.minimalSingleExpression(
               expression, context: context)
        {
            concrete.expression = stripped
            NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.returnKeyword.trailingTrivia)
        }
        return StmtSyntax(concrete)
    }

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(NoForceTry.self, gate: gate) {
            NoForceTry.willEnter(node, context: context)
        }
        if context.shouldRewrite(NoForceUnwrap.self, gate: gate) {
            NoForceUnwrap.willEnter(node, context: context)
        }
        if context.shouldRewrite(NoGuardInTests.self, gate: gate) {
            NoGuardInTests.willEnter(node, context: context)
        }
        if context.shouldRewrite(PreferEnvironmentEntry.self, gate: gate) {
            PreferEnvironmentEntry.willEnter(node, context: context)
        }
        if context.shouldRewrite(PreferFinalClasses.self, gate: gate) {
            PreferFinalClasses.willEnter(node, context: context)
        }
        if context.shouldRewrite(PreferSwiftTesting.self, gate: gate) {
            PreferSwiftTesting.willEnter(node, context: context)
        }
        if context.shouldRewrite(RedundantAccessControl.self, gate: gate) {
            RedundantAccessControl.willEnter(node, context: context)
        }
        if context.shouldRewrite(SwiftTestingTestCaseNames.self, gate: gate) {
            SwiftTestingTestCaseNames.willEnter(node, context: context)
        }
        if context.shouldRewrite(TestSuiteAccessControl.self, gate: gate) {
            TestSuiteAccessControl.willEnter(node, context: context)
        }
        if context.shouldRewrite(URLMacro.self, gate: gate) {
            URLMacro.willEnter(node, context: context)
        }
        if context.shouldRewrite(ValidateTestCases.self, gate: gate) {
            ValidateTestCases.willEnter(node, context: context)
        }
        let visited = super.visit(node)
        return rewriteSourceFile(visited, parent: parent, context: context)
    }

    override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        defer { if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) } }
        return super.visit(node)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runPreferSelfType = context.shouldRewrite(PreferSelfType.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)
        if runPreferSelfType { PreferSelfType.willEnter(node, context: context) }
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
        defer {
            if runPreferSelfType { PreferSelfType.didExit(node, context: context) }
            if runRedundantSelf { RedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(StructDeclSyntax.self) else { return visited }
        apply(DocCommentsPrecedeModifiers.self, to: &concrete, gate: gate) {
            DocCommentsPrecedeModifiers.transform($0, parent: parent, context: $1)
        }
        apply(ModifierOrder.self, to: &concrete, gate: gate) {
            ModifierOrder.transform($0, parent: parent, context: $1)
        }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(RedundantAccessControl.self, to: &concrete, gate: gate) {
            RedundantAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(RedundantEquatable.self, to: &concrete, gate: gate) {
            RedundantEquatable.transform($0, parent: parent, context: $1)
        }
        apply(RedundantObjc.self, to: &concrete, gate: gate) {
            RedundantObjc.transform($0, parent: parent, context: $1)
        }
        apply(RedundantSendable.self, to: &concrete, gate: gate) {
            RedundantSendable.transform($0, parent: parent, context: $1)
        }
        apply(SimplifyGenericConstraints.self, to: &concrete, gate: gate) {
            SimplifyGenericConstraints.transform($0, parent: parent, context: $1)
        }
        apply(TestSuiteAccessControl.self, to: &concrete, gate: gate) {
            TestSuiteAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(TripleSlashDocComments.self, to: &concrete, gate: gate) {
            TripleSlashDocComments.transform($0, parent: parent, context: $1)
        }
        apply(ValidateTestCases.self, to: &concrete, gate: gate) {
            ValidateTestCases.transform($0, parent: parent, context: $1)
        }
        if context.shouldRewrite(RedundantSwiftTestingSuite.self, gate: gate) {
            concrete = RedundantSwiftTestingSuite.removeSuite(
                from: concrete, keyword: \.structKeyword, context: context
            )
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        // StaticStructShouldBeEnum runs last because it can widen `StructDeclSyntax` to
        // `EnumDeclSyntax` .
        if context.shouldRewrite(StaticStructShouldBeEnum.self, gate: gate) {
            return StaticStructShouldBeEnum.transform(concrete, parent: parent, context: context)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: SubscriptCallExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        defer { if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard let concrete = visited.as(SubscriptCallExprSyntax.self) else { return visited }
        if context.shouldRewrite(NoForceUnwrap.self, gate: gate) {
            return NoForceUnwrap.rewriteSubscriptCallTop(concrete, context: context)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
        defer { if runRedundantSelf { RedundantSelf.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard var concrete = visited.as(SubscriptDeclSyntax.self) else { return visited }
        apply(DocCommentsPrecedeModifiers.self, to: &concrete, gate: gate) {
            DocCommentsPrecedeModifiers.transform($0, parent: parent, context: $1)
        }
        apply(ModifierOrder.self, to: &concrete, gate: gate) {
            ModifierOrder.transform($0, parent: parent, context: $1)
        }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(OpaqueGenericParameters.self, to: &concrete, gate: gate) {
            OpaqueGenericParameters.transform($0, parent: parent, context: $1)
        }
        apply(RedundantAccessControl.self, to: &concrete, gate: gate) {
            RedundantAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(RedundantObjc.self, to: &concrete, gate: gate) {
            RedundantObjc.transform($0, parent: parent, context: $1)
        }
        apply(RedundantReturn.self, to: &concrete, gate: gate) {
            RedundantReturn.transform($0, parent: parent, context: $1)
        }
        apply(TripleSlashDocComments.self, to: &concrete, gate: gate) {
            TripleSlashDocComments.transform($0, parent: parent, context: $1)
        }
        apply(UnusedArguments.self, to: &concrete, gate: gate) {
            UnusedArguments.transform($0, parent: parent, context: $1)
        }
        apply(UseImplicitInit.self, to: &concrete, gate: gate) {
            UseImplicitInit.transform($0, parent: parent, context: $1)
        }
        apply(WrapSingleLineBodies.self, to: &concrete, gate: gate) {
            WrapSingleLineBodies.transform($0, parent: parent, context: $1)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(CaseLet.self, gate: gate) {
            node = CaseLet.transform(node, parent: parent, context: context)
        }
        if context.shouldRewrite(RedundantPattern.self, gate: gate) {
            node = RedundantPattern.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: SwitchCaseLabelSyntax) -> SwitchCaseLabelSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var node = super.visit(node)
        if context.shouldRewrite(NoLabelsInCasePatterns.self, gate: gate) {
            node = NoLabelsInCasePatterns.transform(node, parent: parent, context: context)
        }
        if context.shouldRewrite(WrapCompoundCaseItems.self, gate: gate) {
            node = WrapCompoundCaseItems.transform(node, parent: parent, context: context)
        }
        return node
    }

    override func visit(_ node: SwitchCaseListSyntax) -> SwitchCaseListSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        if context.shouldRewrite(NoFallThroughOnlyCases.self, gate: gate) {
            NoFallThroughOnlyCases.willEnter(node, context: context)
        }
        var result = super.visit(node)
        if context.shouldRewrite(NoFallThroughOnlyCases.self, gate: gate) {
            result = NoFallThroughOnlyCases.apply(result, context: context)
        }
        return result
    }

    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(BlankLinesBeforeControlFlowBlocks.self, gate: gate) {
            BlankLinesBeforeControlFlowBlocks.willEnter(node, context: context)
        }
        var result = super.visit(node)
        if context.shouldRewrite(RedundantBreak.self, gate: gate) {
            result = RedundantBreak.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(WrapSwitchCaseBodies.self, gate: gate) {
            result = WrapSwitchCaseBodies.transform(result, parent: parent, context: context)
        }
        if context.shouldRewrite(BlankLinesBeforeControlFlowBlocks.self, gate: gate),
           let updated = BlankLinesBeforeControlFlowBlocks.insertBlankLines(
               in: Array(result.statements), context: context
           )
        {
            result.statements = CodeBlockItemListSyntax(updated)
        }
        return result
    }

    override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.willEnter(node, context: context)
        }
        if context.shouldRewrite(SwitchCaseIndentation.self, gate: gate) {
            SwitchCaseIndentation.willEnter(node, context: context)
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(SwitchExprSyntax.self) else { return visited }
        if context.shouldRewrite(BlankLinesAfterSwitchCase.self, gate: gate) {
            concrete = BlankLinesAfterSwitchCase.apply(concrete, context: context)
        }
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate),
           let stripped = NoParensAroundConditions.minimalSingleExpression(
               concrete.subject, context: context)
        {
            concrete.subject = stripped
            NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.switchKeyword.trailingTrivia)
        }
        if context.shouldRewrite(SwitchCaseIndentation.self, gate: gate) {
            concrete = SwitchCaseIndentation.apply(concrete, context: context)
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        if context.shouldRewrite(ConsistentSwitchCaseSpacing.self, gate: gate) {
            concrete = ConsistentSwitchCaseSpacing.apply(concrete, context: context)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: TernaryExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard var concrete = visited.as(TernaryExprSyntax.self) else { return visited }
        apply(NoVoidTernary.self, to: &concrete, gate: gate) {
            NoVoidTernary.transform($0, parent: parent, context: $1)
        }
        apply(WrapTernary.self, to: &concrete, gate: gate) {
            WrapTernary.transform($0, parent: parent, context: $1)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: TokenSyntax) -> TokenSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        return rewriteToken(visited, parent: parent, context: context)
    }

    override func visit(_ node: TryExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let visited = super.visit(node)
        guard var concrete = visited.as(TryExprSyntax.self) else { return visited }
        if context.shouldRewrite(NoForceTry.self, gate: gate) {
            concrete = NoForceTry.rewriteTryExpr(concrete, context: context)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current: DeclSyntax = super.visit(node)
        applyAsserting(
            DocCommentsPrecedeModifiers.self, to: &current,
            as: TypeAliasDeclSyntax.self, gate: gate
        ) { DocCommentsPrecedeModifiers.transform($0, parent: parent, context: $1) }
        applyAsserting(
            ModifierOrder.self, to: &current, as: TypeAliasDeclSyntax.self, gate: gate
        ) { ModifierOrder.transform($0, parent: parent, context: $1) }
        applyAsserting(
            ModifiersOnSameLine.self, to: &current, as: TypeAliasDeclSyntax.self, gate: gate
        ) { ModifiersOnSameLine.transform($0, parent: parent, context: $1) }
        applyAsserting(
            RedundantAccessControl.self, to: &current, as: TypeAliasDeclSyntax.self, gate: gate
        ) { RedundantAccessControl.transform($0, parent: parent, context: $1) }
        applyAsserting(
            TripleSlashDocComments.self, to: &current, as: TypeAliasDeclSyntax.self, gate: gate
        ) { TripleSlashDocComments.transform($0, parent: parent, context: $1) }
        return current
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, gate: gate)
        if runRedundantSelf { RedundantSelf.willEnter(node, context: context) }
        defer { if runRedundantSelf { RedundantSelf.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard var concrete = visited.as(VariableDeclSyntax.self) else { return visited }
        apply(AvoidNoneName.self, to: &concrete, gate: gate) {
            AvoidNoneName.transform($0, parent: parent, context: $1)
        }
        apply(DocCommentsPrecedeModifiers.self, to: &concrete, gate: gate) {
            DocCommentsPrecedeModifiers.transform($0, parent: parent, context: $1)
        }
        apply(ModifierOrder.self, to: &concrete, gate: gate) {
            ModifierOrder.transform($0, parent: parent, context: $1)
        }
        apply(ModifiersOnSameLine.self, to: &concrete, gate: gate) {
            ModifiersOnSameLine.transform($0, parent: parent, context: $1)
        }
        apply(PrivateStateVariables.self, to: &concrete, gate: gate) {
            PrivateStateVariables.transform($0, parent: parent, context: $1)
        }
        apply(RedundantAccessControl.self, to: &concrete, gate: gate) {
            RedundantAccessControl.transform($0, parent: parent, context: $1)
        }
        apply(RedundantNilInit.self, to: &concrete, gate: gate) {
            RedundantNilInit.transform($0, parent: parent, context: $1)
        }
        apply(RedundantObjc.self, to: &concrete, gate: gate) {
            RedundantObjc.transform($0, parent: parent, context: $1)
        }
        apply(RedundantPattern.self, to: &concrete, gate: gate) {
            RedundantPattern.transform($0, parent: parent, context: $1)
        }
        apply(RedundantSetterACL.self, to: &concrete, gate: gate) {
            RedundantSetterACL.transform($0, parent: parent, context: $1)
        }
        apply(RedundantType.self, to: &concrete, gate: gate) {
            RedundantType.transform($0, parent: parent, context: $1)
        }
        apply(RedundantViewBuilder.self, to: &concrete, gate: gate) {
            RedundantViewBuilder.transform($0, parent: parent, context: $1)
        }
        apply(TripleSlashDocComments.self, to: &concrete, gate: gate) {
            TripleSlashDocComments.transform($0, parent: parent, context: $1)
        }
        if context.shouldRewrite(StrongOutlets.self, gate: gate) {
            concrete = StrongOutlets.apply(concrete, context: context)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runWrapSingleLineBodies = context.shouldRewrite(WrapSingleLineBodies.self, gate: gate)
        if runWrapSingleLineBodies { WrapSingleLineBodies.willEnter(node, context: context) }
        defer {
            if runWrapSingleLineBodies { WrapSingleLineBodies.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(WhileStmtSyntax.self) else { return visited }
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.whileKeyword.trailingTrivia)
        }
        apply(WrapMultilineStatementBraces.self, to: &concrete, gate: gate) {
            WrapMultilineStatementBraces.transform($0, parent: parent, context: $1)
        }
        apply(WrapSingleLineBodies.self, to: &concrete, gate: gate) {
            WrapSingleLineBodies.transform($0, parent: parent, context: $1)
        }
        return StmtSyntax(concrete)
    }
}
