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

// sm:ignore fileLength, typeBodyLength, functionBodyLength

import SwiftSyntax

/// The combined node-local rewrite stage that dispatches every `StaticFormatRule` in a single tree
/// walk. Each `visit(_:)` override defers to `super.visit` to recurse children, then applies every
/// rule that opted into `static func transform(_:context:)` for that node type.
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

    /// Apply a rule whose `transform` returns the same concrete type as `concrete` (or a wider type
    /// that still represents the same node kind). If the result widens to a different kind, the
    /// rewrite is silently dropped — matching the legacy `if let next = … .as(N.self) { … }`
    /// behaviour at every call site this replaces.
    @inline(__always)
    private func apply<N: SyntaxProtocol, R: SyntaxRule>(
        _: R.Type,
        to concrete: inout N,
        original: N,
        gate: Context.Gate,
        _ body: (N, N, Context) -> some SyntaxProtocol
    ) {
        guard context.shouldRewrite(R.self, gate: gate) else { return }
        if let next = body(concrete, original, context).as(N.self) { concrete = next }
    }

    /// Apply a rule whose `transform` may widen `concrete` to a different node kind. Returns the
    /// widened value when the kind changed (caller should propagate / early-return); returns `nil`
    /// otherwise (caller continues the chain).
    @inline(__always)
    private func applyWidening<N: SyntaxProtocol, R: SyntaxRule, W: SyntaxProtocol>(
        _: R.Type,
        to concrete: inout N,
        original: N,
        gate: Context.Gate,
        _ body: (N, N, Context) -> W
    ) -> W? {
        guard context.shouldRewrite(R.self, gate: gate) else { return nil }
        let widened = body(concrete, original, context)

        if let still = widened.as(N.self) {
            concrete = still
            return nil
        }
        return widened
    }

    /// Apply a rule whose `transform` returns the same wider supertype, with an `assertionFailure`
    /// if a preceding rule has already widened `current` away from the expected concrete kind.
    /// Mirrors the legacy `if let concrete = current.as(N.self) { … } else { assertionFailure(…) }`
    /// idiom used for `TypeAliasDecl` , `EnumCaseDecl` , etc.
    @inline(__always)
    private func applyAsserting<N: SyntaxProtocol, R: SyntaxRule, W: SyntaxProtocol>(
        _: R.Type,
        to current: inout W,
        original: N,
        as _: N.Type,
        gate: Context.Gate,
        _ body: (N, N, Context) -> W
    ) {
        guard let concrete = current.as(N.self) else {
            assertionFailure(
                "\(R.self): preceding rule widened \(N.self) to \(type(of: current)); all subsequent rules in this chain are skipped"
            )
            return
        }
        guard context.shouldRewrite(R.self, gate: gate) else { return }
        current = body(concrete, original, context)
    }

    // MARK: - visit overrides

    override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }
        defer { if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) } }
        var result = super.visit(node)
        apply(OrderProtocolAccessors.self, to: &result, original: node, gate: gate) {
            OrderProtocolAccessors.transform($0, original: $1, parent: parent, context: $2)
        }
        return result
    }

    override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }
        defer { if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard var concrete = visited.as(AccessorDeclSyntax.self) else { return visited }
        apply(LayoutSingleLineBodies.self, to: &concrete, original: node, gate: gate) {
            LayoutSingleLineBodies.transform($0, original: $1, parent: parent, context: $2)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runPreferSelfType = context.shouldRewrite(UseSelfNotTypeName.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)
        if runPreferSelfType { UseSelfNotTypeName.willEnter(node, context: context) }
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }

        defer {
            if runPreferSelfType { UseSelfNotTypeName.didExit(node, context: context) }
            if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(ActorDeclSyntax.self) else { return visited }
        apply(PlaceDocCommentsBeforeModifiers.self, to: &concrete, original: node, gate: gate) {
            PlaceDocCommentsBeforeModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SortModifiers.self, to: &concrete, original: node, gate: gate) {
            SortModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantAccessControl.self, to: &concrete, original: node, gate: gate) {
            DropRedundantAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SimplifyGenericConstraints.self, to: &concrete, original: node, gate: gate) {
            SimplifyGenericConstraints.transform($0, original: $1, parent: parent, context: $2)
        }
        if context.shouldRewrite(DropRedundantSwiftTestingSuite.self, gate: gate) {
            concrete = DropRedundantSwiftTestingSuite.removeSuite(
                from: concrete, keyword: \.actorKeyword, context: context
            )
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: ArrayExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard var concrete = visited.as(ArrayExprSyntax.self) else { return visited }
        apply(LayoutSingleLineBodies.self, to: &concrete, original: node, gate: gate) {
            LayoutSingleLineBodies.transform($0, original: $1, parent: parent, context: $2)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: DictionaryExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard var concrete = visited.as(DictionaryExprSyntax.self) else { return visited }
        apply(LayoutSingleLineBodies.self, to: &concrete, original: node, gate: gate) {
            LayoutSingleLineBodies.transform($0, original: $1, parent: parent, context: $2)
        }
        return ExprSyntax(concrete)
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
            KeepModifiersOnSameLine.self,
            to: &current,
            original: node,
            as: AssociatedTypeDeclSyntax.self,
            gate: gate
        ) { KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2) }
        return current
    }

    override func visit(_ node: AttributeSyntax) -> AttributeSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)
        apply(UseMainAttributeNotMainFunc.self, to: &current, original: node, gate: gate) {
            UseMainAttributeNotMainFunc.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseAtCNotUnderscoreCDecl.self, to: &current, original: node, gate: gate) {
            UseAtCNotUnderscoreCDecl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseAtSpecializeNotUnderscore.self, to: &current, original: node, gate: gate) {
            UseAtSpecializeNotUnderscore.transform($0, original: $1, parent: parent, context: $2)
        }
        return current
    }

    override func visit(_ node: AttributedTypeSyntax) -> TypeSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current: TypeSyntax = super.visit(node)
        applyAsserting(
            NoExplicitOwnershipModifiers.self,
            to: &current,
            original: node,
            as: AttributedTypeSyntax.self,
            gate: gate
        ) { NoExplicitOwnershipModifiers.transform($0, original: $1, parent: parent, context: $2) }
        return current
    }

    override func visit(_ node: AwaitExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runHoistTry = context.shouldRewrite(HoistTry.self, gate: gate)
        if runHoistTry { HoistTry.willEnter(node, context: context) }
        defer { if runHoistTry { HoistTry.didExit(node, context: context) } }
        var current: ExprSyntax = super.visit(node)
        applyAsserting(HoistTry.self, to: &current, original: node, as: AwaitExprSyntax.self, gate: gate) {
            HoistTry.transform($0, original: $1, parent: parent, context: $2)
        }
        return current
    }

    override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)
        apply(DropRedundantLetError.self, to: &current, original: node, gate: gate) {
            DropRedundantLetError.transform($0, original: $1, parent: parent, context: $2)
        }
        return current
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runNoForceTry = context.shouldRewrite(NoForceTry.self, gate: gate)
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        let runNoGuardInTests = context.shouldRewrite(NoGuardInTests.self, gate: gate)
        let runPreferSelfType = context.shouldRewrite(UseSelfNotTypeName.self, gate: gate)
        let runPreferSwiftTesting = context.shouldRewrite(UseSwiftTestingNotXCTest.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)
        if runNoForceTry { NoForceTry.willEnter(node, context: context) }
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        if runNoGuardInTests { NoGuardInTests.willEnter(node, context: context) }
        if runPreferSelfType { UseSelfNotTypeName.willEnter(node, context: context) }
        if runPreferSwiftTesting { UseSwiftTestingNotXCTest.willEnter(node, context: context) }
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }

        defer {
            if runNoForceTry { NoForceTry.didExit(node, context: context) }
            if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
            if runNoGuardInTests { NoGuardInTests.didExit(node, context: context) }
            if runPreferSelfType { UseSelfNotTypeName.didExit(node, context: context) }
            if runPreferSwiftTesting { UseSwiftTestingNotXCTest.didExit(node, context: context) }
            if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(ClassDeclSyntax.self) else { return visited }
        apply(PlaceDocCommentsBeforeModifiers.self, to: &concrete, original: node, gate: gate) {
            PlaceDocCommentsBeforeModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SortModifiers.self, to: &concrete, original: node, gate: gate) {
            SortModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseFinalClasses.self, to: &concrete, original: node, gate: gate) {
            UseFinalClasses.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseStaticNotClassFunc.self, to: &concrete, original: node, gate: gate) {
            UseStaticNotClassFunc.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseSwiftTestingNotXCTest.self, to: &concrete, original: node, gate: gate) {
            UseSwiftTestingNotXCTest.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantAccessControl.self, to: &concrete, original: node, gate: gate) {
            DropRedundantAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantMainActorOnView.self, to: &concrete, original: node, gate: gate) {
            DropRedundantMainActorOnView.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantObjcAttribute.self, to: &concrete, original: node, gate: gate) {
            DropRedundantObjcAttribute.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SimplifyGenericConstraints.self, to: &concrete, original: node, gate: gate) {
            SimplifyGenericConstraints.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(RequireSuiteAccessControl.self, to: &concrete, original: node, gate: gate) {
            RequireSuiteAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseTripleSlashOverDocBlock.self, to: &concrete, original: node, gate: gate) {
            UseTripleSlashOverDocBlock.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(RequireTestFnPrefixOrAttribute.self, to: &concrete, original: node, gate: gate) {
            RequireTestFnPrefixOrAttribute.transform($0, original: $1, parent: parent, context: $2)
        }
        if context.shouldRewrite(DropRedundantFinal.self, gate: gate) {
            concrete = DropRedundantFinal.apply(concrete, context: context)
        }
        if context.shouldRewrite(DropRedundantSwiftTestingSuite.self, gate: gate) {
            concrete = DropRedundantSwiftTestingSuite.removeSuite(
                from: concrete, keyword: \.classKeyword, context: context
            )
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        // ConvertStaticStructToEnum runs last because it can widen the class to an `EnumDeclSyntax`
        // .
        return context.shouldRewrite(ConvertStaticStructToEnum.self, gate: gate)
            ? ConvertStaticStructToEnum.transform(concrete, original: node, parent: parent, context: context)
            : DeclSyntax(concrete)
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runNamedClosureParams = context.shouldRewrite(RequireNamedClosureParams.self, gate: gate)
        let runNoForceTry = context.shouldRewrite(NoForceTry.self, gate: gate)
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        let runNoGuardInTests = context.shouldRewrite(NoGuardInTests.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)
        if runNamedClosureParams { RequireNamedClosureParams.willEnter(node, context: context) }
        if runNoForceTry { NoForceTry.willEnter(node, context: context) }
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        if runNoGuardInTests { NoGuardInTests.willEnter(node, context: context) }
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }

        defer {
            if runNamedClosureParams { RequireNamedClosureParams.didExit(node, context: context) }
            if runNoForceTry { NoForceTry.didExit(node, context: context) }
            if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
            if runNoGuardInTests { NoGuardInTests.didExit(node, context: context) }
            if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(ClosureExprSyntax.self) else { return visited }
        apply(DropRedundantReturn.self, to: &concrete, original: node, gate: gate) {
            DropRedundantReturn.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropUnusedArguments.self, to: &concrete, original: node, gate: gate) {
            DropUnusedArguments.transform($0, original: $1, parent: parent, context: $2)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent

        if context.shouldRewrite(UseVoidNotEmptyTuple.self, gate: gate) {
            UseVoidNotEmptyTuple.willEnter(node, context: context)
        }
        var result = super.visit(node)

        if context.shouldRewrite(NoParensInClosureParams.self, gate: gate) {
            result = NoParensInClosureParams.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(UseVoidNotEmptyTuple.self, gate: gate) {
            result = UseVoidNotEmptyTuple.apply(result, context: context)
        }
        return result
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent

        if context.shouldRewrite(DropSemicolons.self, gate: gate) {
            DropSemicolons.willEnter(node, context: context)
        }
        if context.shouldRewrite(SplitMultipleDeclsPerLine.self, gate: gate) {
            SplitMultipleDeclsPerLine.willEnter(node, context: context)
        }
        if context.shouldRewrite(UseEarlyExits.self, gate: gate) {
            UseEarlyExits.willEnter(node, context: context)
        }
        var result = super.visit(node)

        if context.shouldRewrite(RemoveEmptyExtensions.self, gate: gate) {
            result = RemoveEmptyExtensions.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(NoAssignmentInExpressions.self, gate: gate) {
            result = NoAssignmentInExpressions.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(DropSemicolons.self, gate: gate) {
            result = DropSemicolons.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(SplitMultipleDeclsPerLine.self, gate: gate) {
            result = SplitMultipleDeclsPerLine.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(UseIfElseAsExpression.self, gate: gate) {
            result = UseIfElseAsExpression.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(UseIfElseNotSwitchOnBool.self, gate: gate) {
            result = UseIfElseNotSwitchOnBool.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(UseTernary.self, gate: gate) {
            result = UseTernary.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(DropRedundantLet.self, gate: gate) {
            result = DropRedundantLet.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(DropRedundantProperty.self, gate: gate) {
            result = DropRedundantProperty.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(UseEarlyExits.self, gate: gate) {
            result = UseEarlyExits.apply(result, context: context)
        }
        if context.shouldRewrite(NoGuardInTests.self, gate: gate) {
            result = NoGuardInTests.transform(result, original: node, parent: parent, context: context)
        }
        return result
    }

    override func visit(_ node: CodeBlockItemSyntax) -> CodeBlockItemSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)

        if context.shouldRewrite(UseDocCommentsOnAPI.self, gate: gate) {
            current = UseDocCommentsOnAPI.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        if context.shouldRewrite(InsertBlankLineBeforeControlFlowBlocks.self, gate: gate) {
            InsertBlankLineBeforeControlFlowBlocks.willEnter(node, context: context)
        }
        var result = super.visit(node)
        if context.shouldRewrite(InsertBlankLineAfterGuard.self, gate: gate) {
            result = InsertBlankLineAfterGuard.apply(result, context: context)
        }

        if context.shouldRewrite(InsertBlankLineBeforeControlFlowBlocks.self, gate: gate),
           let updated = InsertBlankLineBeforeControlFlowBlocks.insertBlankLines(
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
        var current = super.visit(node)

        if context.shouldRewrite(UseCommaNotAndInConditions.self, gate: gate) {
            current = UseCommaNotAndInConditions.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: ConditionElementSyntax) -> ConditionElementSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent

        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.willEnter(node, context: context)
        }
        var result = super.visit(node)

        if context.shouldRewrite(UseExplicitNilCheck.self, gate: gate) {
            result = UseExplicitNilCheck.transform(result, original: node, parent: parent, context: context)
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
        var current = super.visit(node)

        if context.shouldRewrite(MatchExtensionAccessToMembers.self, gate: gate) {
            current = MatchExtensionAccessToMembers.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let visited = super.visit(node)

        if let concrete = visited.as(DeclReferenceExprSyntax.self),
           context.shouldRewrite(RequireNamedClosureParams.self, gate: gate)
        {
            RequireNamedClosureParams.rewriteDeclReference(concrete, context: context)
        }
        return visited
    }

    override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard var concrete = visited.as(DeinitializerDeclSyntax.self) else { return visited }

        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseTripleSlashOverDocBlock.self, to: &concrete, original: node, gate: gate) {
            UseTripleSlashOverDocBlock.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard var concrete = visited.as(DoStmtSyntax.self) else { return visited }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        return StmtSyntax(concrete)
    }

    override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current: DeclSyntax = super.visit(node)

        applyAsserting(
            KeepModifiersOnSameLine.self, to: &current, original: node, as: EnumCaseDeclSyntax.self, gate: gate
        ) { KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2) }
        applyAsserting(
            DropRedundantRawValues.self, to: &current, original: node, as: EnumCaseDeclSyntax.self, gate: gate
        ) { DropRedundantRawValues.transform($0, original: $1, parent: parent, context: $2) }

        return current
    }

    override func visit(_ node: EnumCaseElementSyntax) -> EnumCaseElementSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)

        if context.shouldRewrite(NoCaseNamedNone.self, gate: gate) {
            current = NoCaseNamedNone.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runPreferSelfType = context.shouldRewrite(UseSelfNotTypeName.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)

        if context.shouldRewrite(SplitMultipleDeclsPerLine.self, gate: gate) {
            SplitMultipleDeclsPerLine.willEnter(node, context: context)
        }
        if runPreferSelfType { UseSelfNotTypeName.willEnter(node, context: context) }
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }

        defer {
            if runPreferSelfType { UseSelfNotTypeName.didExit(node, context: context) }
            if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)

        guard var concrete = visited.as(EnumDeclSyntax.self) else { return visited }

        apply(CollapseSimpleEnums.self, to: &concrete, original: node, gate: gate) {
            CollapseSimpleEnums.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(PlaceDocCommentsBeforeModifiers.self, to: &concrete, original: node, gate: gate) {
            PlaceDocCommentsBeforeModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(HoistIndirectEnum.self, to: &concrete, original: node, gate: gate) {
            HoistIndirectEnum.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SortModifiers.self, to: &concrete, original: node, gate: gate) {
            SortModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SplitMultipleDeclsPerLine.self, to: &concrete, original: node, gate: gate) {
            SplitMultipleDeclsPerLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantAccessControl.self, to: &concrete, original: node, gate: gate) {
            DropRedundantAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantMainActorOnView.self, to: &concrete, original: node, gate: gate) {
            DropRedundantMainActorOnView.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantObjcAttribute.self, to: &concrete, original: node, gate: gate) {
            DropRedundantObjcAttribute.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantSendable.self, to: &concrete, original: node, gate: gate) {
            DropRedundantSendable.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SimplifyGenericConstraints.self, to: &concrete, original: node, gate: gate) {
            SimplifyGenericConstraints.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseTripleSlashOverDocBlock.self, to: &concrete, original: node, gate: gate) {
            UseTripleSlashOverDocBlock.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(RequireTestFnPrefixOrAttribute.self, to: &concrete, original: node, gate: gate) {
            RequireTestFnPrefixOrAttribute.transform($0, original: $1, parent: parent, context: $2)
        }
        if context.shouldRewrite(DropRedundantSwiftTestingSuite.self, gate: gate) {
            concrete = DropRedundantSwiftTestingSuite.removeSuite(
                from: concrete, keyword: \.enumKeyword, context: context
            )
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runPreferSelfType = context.shouldRewrite(UseSelfNotTypeName.self, gate: gate)
        let runPreferSwiftTesting = context.shouldRewrite(UseSwiftTestingNotXCTest.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)

        if runPreferSelfType { UseSelfNotTypeName.willEnter(node, context: context) }
        if runPreferSwiftTesting { UseSwiftTestingNotXCTest.willEnter(node, context: context) }
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }

        defer {
            if runPreferSelfType { UseSelfNotTypeName.didExit(node, context: context) }
            if runPreferSwiftTesting { UseSwiftTestingNotXCTest.didExit(node, context: context) }
            if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)

        guard var concrete = visited.as(ExtensionDeclSyntax.self) else { return visited }

        apply(PlaceDocCommentsBeforeModifiers.self, to: &concrete, original: node, gate: gate) {
            PlaceDocCommentsBeforeModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseAngleBracketsOnExtensions.self, to: &concrete, original: node, gate: gate) {
            UseAngleBracketsOnExtensions.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantAccessControl.self, to: &concrete, original: node, gate: gate) {
            DropRedundantAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseTripleSlashOverDocBlock.self, to: &concrete, original: node, gate: gate) {
            UseTripleSlashOverDocBlock.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runLayoutSingleLineBodies = context.shouldRewrite(LayoutSingleLineBodies.self, gate: gate)
        if runLayoutSingleLineBodies { LayoutSingleLineBodies.willEnter(node, context: context) }

        defer {
            if runLayoutSingleLineBodies { LayoutSingleLineBodies.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(ForStmtSyntax.self) else { return visited }

        apply(HoistCaseLet.self, to: &concrete, original: node, gate: gate) {
            HoistCaseLet.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseWhereClauseInForLoop.self, to: &concrete, original: node, gate: gate) {
            UseWhereClauseInForLoop.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantEnumerated.self, to: &concrete, original: node, gate: gate) {
            DropRedundantEnumerated.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropUnusedArguments.self, to: &concrete, original: node, gate: gate) {
            DropUnusedArguments.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(LayoutSingleLineBodies.self, to: &concrete, original: node, gate: gate) {
            LayoutSingleLineBodies.transform($0, original: $1, parent: parent, context: $2)
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

        if context.shouldRewrite(UseURLMacroForURLLiterals.self, gate: gate) {
            let widened = UseURLMacroForURLLiterals.transform(concrete, original: node, parent: parent, context: context)

            if let stillForce = widened.as(ForceUnwrapExprSyntax.self) {
                concrete = stillForce
            } else {
                return widened
            }
        }
        return context.shouldRewrite(NoForceUnwrap.self, gate: gate)
            ? NoForceUnwrap.rewriteForceUnwrap(concrete, context: context)
            : ExprSyntax(concrete)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        let runPreferSwiftTesting = context.shouldRewrite(UseSwiftTestingNotXCTest.self, gate: gate)
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }

        if context.shouldRewrite(NoTrailingClosureParens.self, gate: gate) {
            NoTrailingClosureParens.willEnter(node, context: context)
        }
        if runPreferSwiftTesting { UseSwiftTestingNotXCTest.willEnter(node, context: context) }

        defer {
            if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
            if runPreferSwiftTesting { UseSwiftTestingNotXCTest.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(FunctionCallExprSyntax.self) else { return visited }
        // HoistAwait may widen `foo(await x)` to `await foo(x)` .
        if let widened = applyWidening(
            HoistAwait.self, to: &concrete, original: node, gate: gate,
            {
                HoistAwait.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        // HoistTry may widen `foo(try x)` to `try foo(x)` .
        if let widened = applyWidening(
            HoistTry.self, to: &concrete, original: node, gate: gate,
            {
                HoistTry.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        apply(UseAssertionFailureNotAssertFalse.self, to: &concrete, original: node, gate: gate) {
            UseAssertionFailureNotAssertFalse.transform($0, original: $1, parent: parent, context: $2)
        }
        // UseSwiftTestingNotXCTest may widen `FunctionCallExpr` to `MacroExpansionExpr` .
        if let widened = applyWidening(
            UseSwiftTestingNotXCTest.self, to: &concrete, original: node, gate: gate,
            {
                UseSwiftTestingNotXCTest.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        // UseDotZero may widen the call to a `MemberAccessExpr` .
        if let widened = applyWidening(
            UseDotZero.self, to: &concrete, original: node, gate: gate,
            {
                UseDotZero.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        apply(UseKeyPath.self, to: &concrete, original: node, gate: gate) {
            UseKeyPath.transform($0, original: $1, parent: parent, context: $2)
        }
        // DropRedundantClosureWrapper may unwrap `{ x }()` to `x` (any `ExprSyntax` ).
        if let widened = applyWidening(
            DropRedundantClosureWrapper.self, to: &concrete, original: node, gate: gate,
            {
                DropRedundantClosureWrapper.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        apply(DropRedundantInitCall.self, to: &concrete, original: node, gate: gate) {
            DropRedundantInitCall.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(RequireFatalErrorMessage.self, to: &concrete, original: node, gate: gate) {
            RequireFatalErrorMessage.transform($0, original: $1, parent: parent, context: $2)
        }
        if context.shouldRewrite(NoTrailingClosureParens.self, gate: gate) {
            concrete = NoTrailingClosureParens.apply(concrete, context: context)
        }
        if context.shouldRewrite(UseTrailingClosures.self, gate: gate) {
            concrete = UseTrailingClosures.apply(concrete, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(WrapMultilineFunctionChains.self, gate: gate) {
            concrete = WrapMultilineFunctionChains.apply(concrete, context: context)
        }
        // NestedCallLayout may produce a different ExprSyntax kind.
        var resultExpr = ExprSyntax(concrete)

        if context.shouldRewrite(NestedCallLayout.self, gate: gate) {
            resultExpr = NestedCallLayout.transform(concrete, original: node, parent: parent, context: context)
            if let typed = resultExpr.as(FunctionCallExprSyntax.self) { concrete = typed }
        }
        // NoForceUnwrap chain-top wrapping at this call.
        return context.shouldRewrite(NoForceUnwrap.self, gate: gate)
            ? NoForceUnwrap.rewriteFunctionCallTop(concrete, context: context)
            : resultExpr
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runNoForceTry = context.shouldRewrite(NoForceTry.self, gate: gate)
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        let runNoGuardInTests = context.shouldRewrite(NoGuardInTests.self, gate: gate)
        let runPreferSwiftTesting = context.shouldRewrite(UseSwiftTestingNotXCTest.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)
        if runNoForceTry { NoForceTry.willEnter(node, context: context) }
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        if runNoGuardInTests { NoGuardInTests.willEnter(node, context: context) }
        if runPreferSwiftTesting { UseSwiftTestingNotXCTest.willEnter(node, context: context) }
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }

        defer {
            if runNoForceTry { NoForceTry.didExit(node, context: context) }
            if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) }
            if runNoGuardInTests { NoGuardInTests.didExit(node, context: context) }
            if runPreferSwiftTesting { UseSwiftTestingNotXCTest.didExit(node, context: context) }
            if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(FunctionDeclSyntax.self) else { return visited }

        apply(PlaceDocCommentsBeforeModifiers.self, to: &concrete, original: node, gate: gate) {
            PlaceDocCommentsBeforeModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SortModifiers.self, to: &concrete, original: node, gate: gate) {
            SortModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(NoExplicitOwnershipModifiers.self, to: &concrete, original: node, gate: gate) {
            NoExplicitOwnershipModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(NoGuardInTests.self, to: &concrete, original: node, gate: gate) {
            NoGuardInTests.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseSomeForGenericParameters.self, to: &concrete, original: node, gate: gate) {
            UseSomeForGenericParameters.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantAccessControl.self, to: &concrete, original: node, gate: gate) {
            DropRedundantAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantAsync.self, to: &concrete, original: node, gate: gate) {
            DropRedundantAsync.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantObjcAttribute.self, to: &concrete, original: node, gate: gate) {
            DropRedundantObjcAttribute.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantReturn.self, to: &concrete, original: node, gate: gate) {
            DropRedundantReturn.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantThrows.self, to: &concrete, original: node, gate: gate) {
            DropRedundantThrows.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantViewBuilder.self, to: &concrete, original: node, gate: gate) {
            DropRedundantViewBuilder.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SimplifyGenericConstraints.self, to: &concrete, original: node, gate: gate) {
            SimplifyGenericConstraints.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseSwiftTestingNames.self, to: &concrete, original: node, gate: gate) {
            UseSwiftTestingNames.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseTripleSlashOverDocBlock.self, to: &concrete, original: node, gate: gate) {
            UseTripleSlashOverDocBlock.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropUnusedArguments.self, to: &concrete, original: node, gate: gate) {
            DropUnusedArguments.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseImplicitInit.self, to: &concrete, original: node, gate: gate) {
            UseImplicitInit.transform($0, original: $1, parent: parent, context: $2)
        }
        // NoForceTry — after children visit, add a `throws` clause if any inner `try!` was
        // converted.
        if context.shouldRewrite(NoForceTry.self, gate: gate) {
            concrete = NoForceTry.afterFunctionDecl(concrete, context: context)
        }
        // NoForceUnwrap — same pattern.
        if context.shouldRewrite(NoForceUnwrap.self, gate: gate) {
            concrete = NoForceUnwrap.afterFunctionDecl(concrete, context: context)
        }
        apply(DropRedundantEscaping.self, to: &concrete, original: node, gate: gate) {
            DropRedundantEscaping.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(LayoutSingleLineBodies.self, to: &concrete, original: node, gate: gate) {
            LayoutSingleLineBodies.transform($0, original: $1, parent: parent, context: $2)
        }
        // UseSwiftTestingNotXCTest may widen `FunctionDecl` to `InitializerDecl` / `DeinitializerDecl` ;
        // early-return on kind change.
        if let widened = applyWidening(
            UseSwiftTestingNotXCTest.self, to: &concrete, original: node, gate: gate,
            {
                UseSwiftTestingNotXCTest.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        // DropRedundantOverride may delete `override` declarations entirely.
        return context.shouldRewrite(DropRedundantOverride.self, gate: gate)
            ? DropRedundantOverride.transform(concrete, original: node, parent: parent, context: context)
            : DeclSyntax(concrete)
    }

    override func visit(_ node: FunctionEffectSpecifiersSyntax) -> FunctionEffectSpecifiersSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)

        if context.shouldRewrite(DropRedundantTypedThrows.self, gate: gate) {
            current = DropRedundantTypedThrows.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)

        if context.shouldRewrite(FlagEmptyCollectionLiteral.self, gate: gate) {
            current = FlagEmptyCollectionLiteral.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: FunctionSignatureSyntax) -> FunctionSignatureSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        var result = super.visit(node)
        if context.shouldRewrite(DropVoidReturnFromSignature.self, gate: gate) {
            result = DropVoidReturnFromSignature.apply(result, context: context)
        }
        return result
    }

    override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent

        if context.shouldRewrite(UseVoidNotEmptyTuple.self, gate: gate) {
            UseVoidNotEmptyTuple.willEnter(node, context: context)
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(FunctionTypeSyntax.self) else { return visited }
        apply(DropRedundantTypedThrows.self, to: &concrete, original: node, gate: gate) {
            DropRedundantTypedThrows.transform($0, original: $1, parent: parent, context: $2)
        }
        if context.shouldRewrite(UseVoidNotEmptyTuple.self, gate: gate) {
            concrete = UseVoidNotEmptyTuple.apply(concrete, context: context)
        }
        return TypeSyntax(concrete)
    }

    override func visit(_ node: GenericSpecializationExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent

        if context.shouldRewrite(UseShorthandTypeNames.self, gate: gate) {
            UseShorthandTypeNames.willEnter(node, context: context)
        }
        var result: ExprSyntax = super.visit(node)

        if context.shouldRewrite(UseShorthandTypeNames.self, gate: gate),
           let typed = result.as(GenericSpecializationExprSyntax.self)
        {
            result = UseShorthandTypeNames.transform(typed, original: node, parent: parent, context: context)
        }
        return result
    }

    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runLayoutSingleLineBodies = context.shouldRewrite(LayoutSingleLineBodies.self, gate: gate)
        if runLayoutSingleLineBodies { LayoutSingleLineBodies.willEnter(node, context: context) }

        defer {
            if runLayoutSingleLineBodies { LayoutSingleLineBodies.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(GuardStmtSyntax.self) else { return visited }

        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.guardKeyword.trailingTrivia)
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(LayoutSingleLineBodies.self, to: &concrete, original: node, gate: gate) {
            LayoutSingleLineBodies.transform($0, original: $1, parent: parent, context: $2)
        }
        return StmtSyntax(concrete)
    }

    override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent

        if context.shouldRewrite(UseShorthandTypeNames.self, gate: gate) {
            UseShorthandTypeNames.willEnter(node, context: context)
        }
        var result: TypeSyntax = super.visit(node)

        if context.shouldRewrite(UseShorthandTypeNames.self, gate: gate),
           let typed = result.as(IdentifierTypeSyntax.self)
        {
            result = UseShorthandTypeNames.transform(typed, original: node, parent: parent, context: context)
        }
        return result
    }

    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runLayoutSingleLineBodies = context.shouldRewrite(LayoutSingleLineBodies.self, gate: gate)
        if runLayoutSingleLineBodies { LayoutSingleLineBodies.willEnter(node, context: context) }

        defer {
            if runLayoutSingleLineBodies { LayoutSingleLineBodies.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(IfExprSyntax.self) else { return visited }
        apply(CollapseSimpleIfElse.self, to: &concrete, original: node, gate: gate) {
            CollapseSimpleIfElse.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseUnavailableNotFatalError.self, to: &concrete, original: node, gate: gate) {
            UseUnavailableNotFatalError.transform($0, original: $1, parent: parent, context: $2)
        }
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.ifKeyword.trailingTrivia)
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(LayoutSingleLineBodies.self, to: &concrete, original: node, gate: gate) {
            LayoutSingleLineBodies.transform($0, original: $1, parent: parent, context: $2)
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

        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseSwiftTestingNotXCTest.self, to: &concrete, original: node, gate: gate) {
            UseSwiftTestingNotXCTest.transform($0, original: $1, parent: parent, context: $2)
        }
        if context.shouldRewrite(DropRedundantSwiftTestingSuite.self, gate: gate) {
            DropRedundantSwiftTestingSuite.visitImport(concrete, context: context)
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
        apply(NoAssignmentInExpressions.self, to: &concrete, original: node, gate: gate) {
            NoAssignmentInExpressions.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(NoYodaConditions.self, to: &concrete, original: node, gate: gate) {
            NoYodaConditions.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseCompoundAssignment.self, to: &concrete, original: node, gate: gate) {
            UseCompoundAssignment.transform($0, original: $1, parent: parent, context: $2)
        }
        if let widened = applyWidening(
            UseIsEmpty.self, to: &concrete, original: node, gate: gate,
            {
                UseIsEmpty.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        if let widened = applyWidening(
            UseToggle.self, to: &concrete, original: node, gate: gate,
            {
                UseToggle.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        if let widened = applyWidening(
            DropRedundantNilCoalescing.self, to: &concrete, original: node, gate: gate,
            {
                DropRedundantNilCoalescing.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        apply(BreakAfterAssignToConditional.self, to: &concrete, original: node, gate: gate) {
            BreakAfterAssignToConditional.transform($0, original: $1, parent: parent, context: $2)
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
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }
        defer { if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard var concrete = visited.as(InitializerDeclSyntax.self) else { return visited }
        apply(PlaceDocCommentsBeforeModifiers.self, to: &concrete, original: node, gate: gate) {
            PlaceDocCommentsBeforeModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(MarkInitCoderUnavailable.self, to: &concrete, original: node, gate: gate) {
            MarkInitCoderUnavailable.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SortModifiers.self, to: &concrete, original: node, gate: gate) {
            SortModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseSomeForGenericParameters.self, to: &concrete, original: node, gate: gate) {
            UseSomeForGenericParameters.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantAccessControl.self, to: &concrete, original: node, gate: gate) {
            DropRedundantAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantObjcAttribute.self, to: &concrete, original: node, gate: gate) {
            DropRedundantObjcAttribute.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseTripleSlashOverDocBlock.self, to: &concrete, original: node, gate: gate) {
            UseTripleSlashOverDocBlock.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropUnusedArguments.self, to: &concrete, original: node, gate: gate) {
            DropUnusedArguments.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseImplicitInit.self, to: &concrete, original: node, gate: gate) {
            UseImplicitInit.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantEscaping.self, to: &concrete, original: node, gate: gate) {
            DropRedundantEscaping.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(LayoutSingleLineBodies.self, to: &concrete, original: node, gate: gate) {
            LayoutSingleLineBodies.transform($0, original: $1, parent: parent, context: $2)
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
            original: node,
            as: IntegerLiteralExprSyntax.self,
            gate: gate
        ) { GroupNumericLiterals.transform($0, original: $1, parent: parent, context: $2) }
        return current
    }

    override func visit(_ node: LabeledExprSyntax) -> LabeledExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)

        if context.shouldRewrite(DropRedundantLet.self, gate: gate) {
            current = DropRedundantLet.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current: ExprSyntax = super.visit(node)
        applyAsserting(
            UseFileIDNotFile.self,
            to: &current,
            original: node,
            as: MacroExpansionExprSyntax.self,
            gate: gate
        ) { UseFileIDNotFile.transform($0, original: $1, parent: parent, context: $2) }
        return current
    }

    override func visit(_ node: MatchingPatternConditionSyntax) -> MatchingPatternConditionSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)

        if context.shouldRewrite(HoistCaseLet.self, gate: gate) {
            current = HoistCaseLet.transform(current, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(DropRedundantCasePattern.self, gate: gate) {
            current = DropRedundantCasePattern.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        defer { if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard var concrete = visited.as(MemberAccessExprSyntax.self) else { return visited }
        if let widened = applyWidening(
            UseCountWhere.self, to: &concrete, original: node, gate: gate,
            {
                UseCountWhere.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        apply(UseIsDisjoint.self, to: &concrete, original: node, gate: gate) {
            UseIsDisjoint.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseSelfNotTypeName.self, to: &concrete, original: node, gate: gate) {
            UseSelfNotTypeName.transform($0, original: $1, parent: parent, context: $2)
        }
        if let widened = applyWidening(
            DropRedundantSelf.self, to: &concrete, original: node, gate: gate,
            {
                DropRedundantSelf.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        if let widened = applyWidening(
            DropRedundantStaticSelf.self, to: &concrete, original: node, gate: gate,
            {
                DropRedundantStaticSelf.transform($0, original: $1, parent: parent, context: $2)
            })
        {
            return widened
        }
        return context.shouldRewrite(NoForceUnwrap.self, gate: gate)
            ? NoForceUnwrap.rewriteMemberAccess(concrete, context: context)
            : ExprSyntax(concrete)
    }

    override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent

        if context.shouldRewrite(DropSemicolons.self, gate: gate) {
            DropSemicolons.willEnter(node, context: context)
        }
        var current = super.visit(node)

        if context.shouldRewrite(DropSemicolons.self, gate: gate) {
            current = DropSemicolons.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: MemberBlockItemSyntax) -> MemberBlockItemSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)

        if context.shouldRewrite(UseDocCommentsOnAPI.self, gate: gate) {
            current = UseDocCommentsOnAPI.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: OptionalBindingConditionSyntax) -> OptionalBindingConditionSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)

        if context.shouldRewrite(DropBacktickedSelf.self, gate: gate) {
            current = DropBacktickedSelf.transform(current, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(DropRedundantOptionalBinding.self, gate: gate) {
            current = DropRedundantOptionalBinding.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)

        if context.shouldRewrite(FlagEmptyCollectionLiteral.self, gate: gate) {
            current = FlagEmptyCollectionLiteral.transform(current, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(CollapseSingleLineGetter.self, gate: gate) {
            current = CollapseSingleLineGetter.transform(current, original: node, parent: parent, context: context)
        }

        if context.shouldRewrite(DropRedundantReturn.self, gate: gate) {
            current = DropRedundantReturn.transform(current, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(UseImplicitInit.self, gate: gate) {
            current = UseImplicitInit.transform(current, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(BreakAfterAssignToConditional.self, gate: gate) {
            current = BreakAfterAssignToConditional.transform(current, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(LayoutSingleLineBodies.self, gate: gate) {
            current = LayoutSingleLineBodies.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: PrefixOperatorExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var result: ExprSyntax = super.visit(node)

        if context.shouldRewrite(UseExplicitFalseInGuards.self, gate: gate),
           let prefix = result.as(PrefixOperatorExprSyntax.self)
        {
            result = UseExplicitFalseInGuards.transform(prefix, original: node, parent: parent, context: context)
        }
        return result
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard var concrete = visited.as(ProtocolDeclSyntax.self) else { return visited }
        apply(PlaceDocCommentsBeforeModifiers.self, to: &concrete, original: node, gate: gate) {
            PlaceDocCommentsBeforeModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantAccessControl.self, to: &concrete, original: node, gate: gate) {
            DropRedundantAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseTripleSlashOverDocBlock.self, to: &concrete, original: node, gate: gate) {
            UseTripleSlashOverDocBlock.transform($0, original: $1, parent: parent, context: $2)
        }
        if context.shouldRewrite(UseAnyObjectOnDelegate.self, gate: gate) {
            concrete = UseAnyObjectOnDelegate.apply(concrete, context: context)
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runLayoutSingleLineBodies = context.shouldRewrite(LayoutSingleLineBodies.self, gate: gate)

        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.willEnter(node, context: context)
        }
        if runLayoutSingleLineBodies { LayoutSingleLineBodies.willEnter(node, context: context) }

        defer {
            if runLayoutSingleLineBodies { LayoutSingleLineBodies.didExit(node, context: context) }
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
        apply(LayoutSingleLineBodies.self, to: &concrete, original: node, gate: gate) {
            LayoutSingleLineBodies.transform($0, original: $1, parent: parent, context: $2)
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
            NoParensAroundConditions.fixKeywordTrailingTrivia(
                &concrete.returnKeyword.trailingTrivia)
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
        if context.shouldRewrite(UseAtEntryNotEnvironmentKey.self, gate: gate) {
            UseAtEntryNotEnvironmentKey.willEnter(node, context: context)
        }
        if context.shouldRewrite(UseFinalClasses.self, gate: gate) {
            UseFinalClasses.willEnter(node, context: context)
        }
        if context.shouldRewrite(UseSwiftTestingNotXCTest.self, gate: gate) {
            UseSwiftTestingNotXCTest.willEnter(node, context: context)
        }
        if context.shouldRewrite(DropRedundantAccessControl.self, gate: gate) {
            DropRedundantAccessControl.willEnter(node, context: context)
        }
        if context.shouldRewrite(UseSwiftTestingNames.self, gate: gate) {
            UseSwiftTestingNames.willEnter(node, context: context)
        }
        if context.shouldRewrite(RequireSuiteAccessControl.self, gate: gate) {
            RequireSuiteAccessControl.willEnter(node, context: context)
        }
        if context.shouldRewrite(UseURLMacroForURLLiterals.self, gate: gate) {
            UseURLMacroForURLLiterals.willEnter(node, context: context)
        }
        if context.shouldRewrite(RequireTestFnPrefixOrAttribute.self, gate: gate) {
            RequireTestFnPrefixOrAttribute.willEnter(node, context: context)
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
        let runPreferSelfType = context.shouldRewrite(UseSelfNotTypeName.self, gate: gate)
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)
        if runPreferSelfType { UseSelfNotTypeName.willEnter(node, context: context) }
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }

        defer {
            if runPreferSelfType { UseSelfNotTypeName.didExit(node, context: context) }
            if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(StructDeclSyntax.self) else { return visited }
        apply(PlaceDocCommentsBeforeModifiers.self, to: &concrete, original: node, gate: gate) {
            PlaceDocCommentsBeforeModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SortModifiers.self, to: &concrete, original: node, gate: gate) {
            SortModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantAccessControl.self, to: &concrete, original: node, gate: gate) {
            DropRedundantAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantEquatable.self, to: &concrete, original: node, gate: gate) {
            DropRedundantEquatable.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantMainActorOnView.self, to: &concrete, original: node, gate: gate) {
            DropRedundantMainActorOnView.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantObjcAttribute.self, to: &concrete, original: node, gate: gate) {
            DropRedundantObjcAttribute.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantSendable.self, to: &concrete, original: node, gate: gate) {
            DropRedundantSendable.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SimplifyGenericConstraints.self, to: &concrete, original: node, gate: gate) {
            SimplifyGenericConstraints.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(RequireSuiteAccessControl.self, to: &concrete, original: node, gate: gate) {
            RequireSuiteAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseTripleSlashOverDocBlock.self, to: &concrete, original: node, gate: gate) {
            UseTripleSlashOverDocBlock.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(RequireTestFnPrefixOrAttribute.self, to: &concrete, original: node, gate: gate) {
            RequireTestFnPrefixOrAttribute.transform($0, original: $1, parent: parent, context: $2)
        }
        if context.shouldRewrite(DropRedundantSwiftTestingSuite.self, gate: gate) {
            concrete = DropRedundantSwiftTestingSuite.removeSuite(
                from: concrete, keyword: \.structKeyword, context: context
            )
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        // ConvertStaticStructToEnum runs last because it can widen `StructDeclSyntax` to
        // `EnumDeclSyntax` .
        return context.shouldRewrite(ConvertStaticStructToEnum.self, gate: gate)
            ? ConvertStaticStructToEnum.transform(concrete, original: node, parent: parent, context: context)
            : DeclSyntax(concrete)
    }

    override func visit(_ node: SubscriptCallExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let runNoForceUnwrap = context.shouldRewrite(NoForceUnwrap.self, gate: gate)
        if runNoForceUnwrap { NoForceUnwrap.willEnter(node, context: context) }
        defer { if runNoForceUnwrap { NoForceUnwrap.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard let concrete = visited.as(SubscriptCallExprSyntax.self) else { return visited }
        return context.shouldRewrite(NoForceUnwrap.self, gate: gate)
            ? NoForceUnwrap.rewriteSubscriptCallTop(concrete, context: context)
            : ExprSyntax(concrete)
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }
        defer { if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard var concrete = visited.as(SubscriptDeclSyntax.self) else { return visited }
        apply(PlaceDocCommentsBeforeModifiers.self, to: &concrete, original: node, gate: gate) {
            PlaceDocCommentsBeforeModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SortModifiers.self, to: &concrete, original: node, gate: gate) {
            SortModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseSomeForGenericParameters.self, to: &concrete, original: node, gate: gate) {
            UseSomeForGenericParameters.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantAccessControl.self, to: &concrete, original: node, gate: gate) {
            DropRedundantAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantObjcAttribute.self, to: &concrete, original: node, gate: gate) {
            DropRedundantObjcAttribute.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantReturn.self, to: &concrete, original: node, gate: gate) {
            DropRedundantReturn.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseTripleSlashOverDocBlock.self, to: &concrete, original: node, gate: gate) {
            UseTripleSlashOverDocBlock.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropUnusedArguments.self, to: &concrete, original: node, gate: gate) {
            DropUnusedArguments.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseImplicitInit.self, to: &concrete, original: node, gate: gate) {
            UseImplicitInit.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(LayoutSingleLineBodies.self, to: &concrete, original: node, gate: gate) {
            LayoutSingleLineBodies.transform($0, original: $1, parent: parent, context: $2)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)

        if context.shouldRewrite(HoistCaseLet.self, gate: gate) {
            current = HoistCaseLet.transform(current, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(DropRedundantCasePattern.self, gate: gate) {
            current = DropRedundantCasePattern.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: SwitchCaseLabelSyntax) -> SwitchCaseLabelSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        var current = super.visit(node)

        if context.shouldRewrite(DropLabelsInCasePatterns.self, gate: gate) {
            current = DropLabelsInCasePatterns.transform(current, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(WrapCompoundCaseItems.self, gate: gate) {
            current = WrapCompoundCaseItems.transform(current, original: node, parent: parent, context: context)
        }
        return current
    }

    override func visit(_ node: SwitchCaseListSyntax) -> SwitchCaseListSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }

        if context.shouldRewrite(DropFallthroughOnlyCases.self, gate: gate) {
            DropFallthroughOnlyCases.willEnter(node, context: context)
        }
        var result = super.visit(node)

        if context.shouldRewrite(DropFallthroughOnlyCases.self, gate: gate) {
            result = DropFallthroughOnlyCases.apply(result, context: context)
        }
        return result
    }

    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        if context.shouldRewrite(InsertBlankLineBeforeControlFlowBlocks.self, gate: gate) {
            InsertBlankLineBeforeControlFlowBlocks.willEnter(node, context: context)
        }
        var result = super.visit(node)

        if context.shouldRewrite(DropRedundantBreak.self, gate: gate) {
            result = DropRedundantBreak.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(LayoutSwitchCaseBodies.self, gate: gate) {
            result = LayoutSwitchCaseBodies.transform(result, original: node, parent: parent, context: context)
        }
        if context.shouldRewrite(InsertBlankLineBeforeControlFlowBlocks.self, gate: gate),
           let updated = InsertBlankLineBeforeControlFlowBlocks.insertBlankLines(
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
        if context.shouldRewrite(IndentSwitchCases.self, gate: gate) {
            IndentSwitchCases.willEnter(node, context: context)
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(SwitchExprSyntax.self) else { return visited }

        if context.shouldRewrite(InsertBlankLineAfterSwitchCase.self, gate: gate) {
            concrete = InsertBlankLineAfterSwitchCase.apply(concrete, context: context)
        }
        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate),
           let stripped = NoParensAroundConditions.minimalSingleExpression(
               concrete.subject, context: context)
        {
            concrete.subject = stripped
            NoParensAroundConditions.fixKeywordTrailingTrivia(
                &concrete.switchKeyword.trailingTrivia)
        }
        if context.shouldRewrite(IndentSwitchCases.self, gate: gate) {
            concrete = IndentSwitchCases.apply(concrete, context: context)
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        if context.shouldRewrite(NormalizeSwitchCaseSpacing.self, gate: gate) {
            concrete = NormalizeSwitchCaseSpacing.apply(concrete, context: context)
        }
        return ExprSyntax(concrete)
    }

    override func visit(_ node: TernaryExprSyntax) -> ExprSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard var concrete = visited.as(TernaryExprSyntax.self) else { return visited }
        apply(NoVoidTernary.self, to: &concrete, original: node, gate: gate) {
            NoVoidTernary.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(WrapTernaryBranches.self, to: &concrete, original: node, gate: gate) {
            WrapTernaryBranches.transform($0, original: $1, parent: parent, context: $2)
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
            PlaceDocCommentsBeforeModifiers.self, to: &current, original: node,
            as: TypeAliasDeclSyntax.self, gate: gate
        ) { PlaceDocCommentsBeforeModifiers.transform($0, original: $1, parent: parent, context: $2) }
        applyAsserting(
            SortModifiers.self, to: &current, original: node, as: TypeAliasDeclSyntax.self, gate: gate
        ) { SortModifiers.transform($0, original: $1, parent: parent, context: $2) }
        applyAsserting(
            KeepModifiersOnSameLine.self, to: &current, original: node, as: TypeAliasDeclSyntax.self, gate: gate
        ) { KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2) }
        applyAsserting(
            DropRedundantAccessControl.self, to: &current, original: node, as: TypeAliasDeclSyntax.self, gate: gate
        ) { DropRedundantAccessControl.transform($0, original: $1, parent: parent, context: $2) }
        applyAsserting(
            UseTripleSlashOverDocBlock.self, to: &current, original: node, as: TypeAliasDeclSyntax.self, gate: gate
        ) { UseTripleSlashOverDocBlock.transform($0, original: $1, parent: parent, context: $2) }
        return current
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runRedundantSelf = context.shouldRewrite(DropRedundantSelf.self, gate: gate)
        if runRedundantSelf { DropRedundantSelf.willEnter(node, context: context) }
        defer { if runRedundantSelf { DropRedundantSelf.didExit(node, context: context) } }
        let visited = super.visit(node)
        guard var concrete = visited.as(VariableDeclSyntax.self) else { return visited }
        apply(NoCaseNamedNone.self, to: &concrete, original: node, gate: gate) {
            NoCaseNamedNone.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(PlaceDocCommentsBeforeModifiers.self, to: &concrete, original: node, gate: gate) {
            PlaceDocCommentsBeforeModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(SortModifiers.self, to: &concrete, original: node, gate: gate) {
            SortModifiers.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(KeepModifiersOnSameLine.self, to: &concrete, original: node, gate: gate) {
            KeepModifiersOnSameLine.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(MakeStateVarsPrivate.self, to: &concrete, original: node, gate: gate) {
            MakeStateVarsPrivate.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantAccessControl.self, to: &concrete, original: node, gate: gate) {
            DropRedundantAccessControl.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantNilInit.self, to: &concrete, original: node, gate: gate) {
            DropRedundantNilInit.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantObjcAttribute.self, to: &concrete, original: node, gate: gate) {
            DropRedundantObjcAttribute.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantCasePattern.self, to: &concrete, original: node, gate: gate) {
            DropRedundantCasePattern.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantSetterACL.self, to: &concrete, original: node, gate: gate) {
            DropRedundantSetterACL.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantTypeAnnotation.self, to: &concrete, original: node, gate: gate) {
            DropRedundantTypeAnnotation.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(DropRedundantViewBuilder.self, to: &concrete, original: node, gate: gate) {
            DropRedundantViewBuilder.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(UseTripleSlashOverDocBlock.self, to: &concrete, original: node, gate: gate) {
            UseTripleSlashOverDocBlock.transform($0, original: $1, parent: parent, context: $2)
        }
        if context.shouldRewrite(UseStrongOutlets.self, gate: gate) {
            concrete = UseStrongOutlets.apply(concrete, context: context)
        }
        return DeclSyntax(concrete)
    }

    override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
        guard let gate = context.gate(for: node) else { return super.visit(node) }
        let parent = Syntax(node).parent
        let runLayoutSingleLineBodies = context.shouldRewrite(LayoutSingleLineBodies.self, gate: gate)
        if runLayoutSingleLineBodies { LayoutSingleLineBodies.willEnter(node, context: context) }

        defer {
            if runLayoutSingleLineBodies { LayoutSingleLineBodies.didExit(node, context: context) }
        }
        let visited = super.visit(node)
        guard var concrete = visited.as(WhileStmtSyntax.self) else { return visited }

        if context.shouldRewrite(NoParensAroundConditions.self, gate: gate) {
            NoParensAroundConditions.fixKeywordTrailingTrivia(&concrete.whileKeyword.trailingTrivia)
        }
        apply(BreakBeforeMultilineBrace.self, to: &concrete, original: node, gate: gate) {
            BreakBeforeMultilineBrace.transform($0, original: $1, parent: parent, context: $2)
        }
        apply(LayoutSingleLineBodies.self, to: &concrete, original: node, gate: gate) {
            LayoutSingleLineBodies.transform($0, original: $1, parent: parent, context: $2)
        }
        return StmtSyntax(concrete)
    }
}
