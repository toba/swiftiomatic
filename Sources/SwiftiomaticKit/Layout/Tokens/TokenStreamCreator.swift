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

import Foundation
import SwiftOperators
import SwiftSyntax

extension AccessorBlockSyntax {
    /// Assuming that the accessor only contains an implicit getter (i.e. no
    /// `get` or `set`), return the code block items in that getter.
    var getterCodeBlockItems: CodeBlockItemListSyntax {
        guard case .getter(let codeBlockItemList) = self.accessors else {
            preconditionFailure("AccessorBlock has an accessor list and not just a getter")
        }
        return codeBlockItemList
    }
}

/// Visits the nodes of a syntax tree and constructs a linear stream of formatting tokens that
/// tell the pretty printer how the source text should be laid out.
final class TokenStreamCreator: SyntaxVisitor {
    var tokens = [Token]()
    var beforeMap = [TokenSyntax: [Token]]()
    var afterMap = [TokenSyntax: [[Token]]]()
    let config: Configuration
    let operatorTable: OperatorTable
    let maxLineLength: Int
    let selection: Selection

    /// The index of the most recently appended break, or nil when no break has been appended.
    var lastBreakIndex: Int? = nil

    /// Whether newlines can be merged into the most recent break, based on which tokens have been
    /// appended since that break.
    var canMergeNewlinesIntoLastBreak = false

    /// Keeps track of the kind of break that should be used inside a multiline string. This differs
    /// depending on surrounding context due to some tricky special cases, so this lets us pass that
    /// information down to the strings that need it.
    var pendingMultilineStringBreakKinds = [StringLiteralExprSyntax: BreakKind]()

    /// Lists tokens that shouldn't be appended to the token stream as `syntax` tokens. They will be
    /// printed conditionally using a different type of token.
    var ignoredTokens = Set<TokenSyntax>()

    /// Lists the expressions that have been visited, from the outermost expression, where contextual
    /// breaks and start/end contextual breaking tokens have been inserted.
    var preVisitedExprs = Set<SyntaxIdentifier>()

    /// Tracks the "root" exprs where previsiting for contextual breaks started so that
    /// `preVisitedExprs` can be emptied after exiting an expr tree.
    var rootExprs = Set<SyntaxIdentifier>()

    /// Lists the tokens that are the closing or final delimiter of a node that shouldn't be split
    /// from the preceding token. When breaks are inserted around compound expressions, the breaks are
    /// moved past these tokens.
    var closingDelimiterTokens = Set<TokenSyntax>()

    /// Tracks closures that are never allowed to be laid out entirely on one line (e.g., closures
    /// in a function call containing multiple trailing closures).
    var forcedBreakingClosures = Set<SyntaxIdentifier>()

    /// Tracks whether we last considered ourselves inside the selection
    var isInsideSelection = true

    init(configuration: Configuration, selection: Selection, operatorTable: OperatorTable) {
        self.config = configuration
        self.selection = selection
        self.operatorTable = operatorTable
        self.maxLineLength = config[LineLength.self]
        super.init(viewMode: .all)
    }

    func makeStream(from node: Syntax) -> [Token] {
        // if we have a selection, then we start outside of it
        if case .ranges = selection {
            appendToken(.disableFormatting(AbsolutePosition(utf8Offset: 0)))
            isInsideSelection = false
        }

        // Because `walk` takes an `inout` argument, and we're a class, we have to do the following
        // dance to pass ourselves in.
        self.walk(node)

        // Make sure we output any trailing text after the last selection range
        if case .ranges = selection {
            appendToken(.enableFormatting(nil))
        }
        defer { tokens = [] }
        return tokens
    }

    var openings = 0

    /// If the syntax token is non-nil, enqueue the given list of formatting tokens before it in the
    /// token stream.
    func before(_ token: TokenSyntax?, tokens: Token...) {
        before(token, tokens: tokens)
    }

    /// If the syntax token is non-nil, enqueue the given list of formatting tokens before it in the
    /// token stream.
    func before(_ token: TokenSyntax?, tokens: [Token]) {
        guard let tok = token else { return }
        beforeMap[tok, default: []] += tokens
    }

    /// If the syntax token is non-nil, enqueue the given list of formatting tokens after it in the
    /// token stream.
    func after(_ token: TokenSyntax?, tokens: Token...) {
        after(token, tokens: tokens)
    }

    /// If the syntax token is non-nil, enqueue the given list of formatting tokens after it in the
    /// token stream.
    func after(_ token: TokenSyntax?, tokens: [Token]) {
        guard let tok = token else { return }
        afterMap[tok, default: []].append(tokens)
    }

    /// Enqueues the given list of formatting tokens between each element of the given syntax
    /// collection (but not before the first one nor after the last one).
    func insertTokens<Node: SyntaxCollection>(
        _ tokens: Token...,
        betweenElementsOf collectionNode: Node
    ) where Node.Element == Syntax {
        for element in collectionNode.dropLast() {
            after(element.lastToken(viewMode: .sourceAccurate), tokens: tokens)
        }
    }

    /// Enqueues the given list of formatting tokens between each element of the given syntax
    /// collection (but not before the first one nor after the last one).
    func insertTokens<Node: SyntaxCollection>(
        _ tokens: Token...,
        betweenElementsOf collectionNode: Node
    ) where Node.Element: SyntaxProtocol {
        for element in collectionNode.dropLast() {
            after(element.lastToken(viewMode: .sourceAccurate), tokens: tokens)
        }
    }

    /// Enqueues the given list of formatting tokens between each element of the given syntax
    /// collection (but not before the first one nor after the last one).
    func insertTokens<Node: SyntaxCollection>(
        _ tokens: Token...,
        betweenElementsOf collectionNode: Node
    ) where Node.Element == DeclSyntax {
        for element in collectionNode.dropLast() {
            after(element.lastToken(viewMode: .sourceAccurate), tokens: tokens)
        }
    }

    func verbatimToken(_ node: Syntax, indentingBehavior: IndentingBehavior = .allLines) {
        if let firstToken = node.firstToken(viewMode: .sourceAccurate) {
            appendBeforeTokens(firstToken)
        }

        appendToken(
            .verbatim(Verbatim(text: node.description, indentingBehavior: indentingBehavior))
        )

        if let lastToken = node.lastToken(viewMode: .sourceAccurate) {
            // Extract any comments that trail the verbatim block since they belong to the next syntax
            // token. Leading comments don't need special handling since they belong to the current node,
            // and will get printed.
            appendAfterTokensAndTrailingComments(lastToken)
        }
    }

    // MARK: - Visit/VisitPost forwarding stubs
    //
    // Swift does not allow overriding methods in extensions of non-@objc classes.
    // These stubs forward to implementations in the TokenStreamCreator+*.swift
    // extension files.

    override func visit(_ node: AccessorDeclListSyntax) -> SyntaxVisitorContinueKind { visitAccessorDeclList(node) }
    override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind { visitAccessorDecl(node) }
    override func visit(_ node: AccessorEffectSpecifiersSyntax) -> SyntaxVisitorContinueKind { visitAccessorEffectSpecifiers(node) }
    override func visit(_ node: AccessorParametersSyntax) -> SyntaxVisitorContinueKind { visitAccessorParameters(node) }
    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind { visitActorDecl(node) }
    override func visit(_ node: ArrayElementListSyntax) -> SyntaxVisitorContinueKind { visitArrayElementList(node) }
    override func visit(_ node: ArrayElementSyntax) -> SyntaxVisitorContinueKind { visitArrayElement(node) }
    override func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind { visitArrayExpr(node) }
    override func visit(_ node: ArrayTypeSyntax) -> SyntaxVisitorContinueKind { visitArrayType(node) }
    override func visit(_ node: ArrowExprSyntax) -> SyntaxVisitorContinueKind { visitArrowExpr(node) }
    override func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind { visitAsExpr(node) }
    override func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind { visitAssignmentExpr(node) }
    override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind { visitAssociatedTypeDecl(node) }
    override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind { visitAttribute(node) }
    override func visit(_ node: AttributedTypeSyntax) -> SyntaxVisitorContinueKind { visitAttributedType(node) }
    override func visit(_ node: AvailabilityArgumentListSyntax) -> SyntaxVisitorContinueKind { visitAvailabilityArgumentList(node) }
    override func visit(_ node: AvailabilityConditionSyntax) -> SyntaxVisitorContinueKind { visitAvailabilityCondition(node) }
    override func visit(_ node: AvailabilityLabeledArgumentSyntax) -> SyntaxVisitorContinueKind { visitAvailabilityLabeledArgument(node) }
    override func visit(_ node: AwaitExprSyntax) -> SyntaxVisitorContinueKind { visitAwaitExpr(node) }
    override func visit(_ node: BackDeployedAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind { visitBackDeployedAttributeArguments(node) }
    override func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind { visitBinaryOperatorExpr(node) }
    override func visit(_ node: BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind { visitBooleanLiteralExpr(node) }
    override func visit(_ node: BorrowExprSyntax) -> SyntaxVisitorContinueKind { visitBorrowExpr(node) }
    override func visit(_ node: BreakStmtSyntax) -> SyntaxVisitorContinueKind { visitBreakStmt(node) }
    override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind { visitCatchClause(node) }
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind { visitClassDecl(node) }
    override func visit(_ node: ClosureCaptureClauseSyntax) -> SyntaxVisitorContinueKind { visitClosureCaptureClause(node) }
    override func visit(_ node: ClosureCaptureListSyntax) -> SyntaxVisitorContinueKind { visitClosureCaptureList(node) }
    override func visit(_ node: ClosureCaptureSyntax) -> SyntaxVisitorContinueKind { visitClosureCapture(node) }
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind { visitClosureExpr(node) }
    override func visit(_ node: ClosureParameterClauseSyntax) -> SyntaxVisitorContinueKind { visitClosureParameterClause(node) }
    override func visit(_ node: ClosureParameterSyntax) -> SyntaxVisitorContinueKind { visitClosureParameter(node) }
    override func visit(_ node: ClosureShorthandParameterSyntax) -> SyntaxVisitorContinueKind { visitClosureShorthandParameter(node) }
    override func visit(_ node: ClosureSignatureSyntax) -> SyntaxVisitorContinueKind { visitClosureSignature(node) }
    override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind { visitCodeBlockItemList(node) }
    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind { visitCodeBlockItem(node) }
    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind { visitCodeBlock(node) }
    override func visit(_ node: CompositionTypeElementSyntax) -> SyntaxVisitorContinueKind { visitCompositionTypeElement(node) }
    override func visit(_ node: CompositionTypeSyntax) -> SyntaxVisitorContinueKind { visitCompositionType(node) }
    override func visit(_ node: ConditionElementSyntax) -> SyntaxVisitorContinueKind { visitConditionElement(node) }
    override func visit(_ node: ConformanceRequirementSyntax) -> SyntaxVisitorContinueKind { visitConformanceRequirement(node) }
    override func visit(_ node: ConsumeExprSyntax) -> SyntaxVisitorContinueKind { visitConsumeExpr(node) }
    override func visit(_ node: ContinueStmtSyntax) -> SyntaxVisitorContinueKind { visitContinueStmt(node) }
    override func visit(_ node: CopyExprSyntax) -> SyntaxVisitorContinueKind { visitCopyExpr(node) }
    override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind { visitDeclModifier(node) }
    override func visit(_ node: DeclNameArgumentSyntax) -> SyntaxVisitorContinueKind { visitDeclNameArgument(node) }
    override func visit(_ node: DeclNameArgumentsSyntax) -> SyntaxVisitorContinueKind { visitDeclNameArguments(node) }
    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind { visitDeclReferenceExpr(node) }
    override func visit(_ node: DeferStmtSyntax) -> SyntaxVisitorContinueKind { visitDeferStmt(node) }
    override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind { visitDeinitializerDecl(node) }
    override func visit(_ node: DerivativeAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind { visitDerivativeAttributeArguments(node) }
    override func visit(_ node: DesignatedTypeSyntax) -> SyntaxVisitorContinueKind { visitDesignatedType(node) }
    override func visit(_ node: DictionaryElementListSyntax) -> SyntaxVisitorContinueKind { visitDictionaryElementList(node) }
    override func visit(_ node: DictionaryElementSyntax) -> SyntaxVisitorContinueKind { visitDictionaryElement(node) }
    override func visit(_ node: DictionaryExprSyntax) -> SyntaxVisitorContinueKind { visitDictionaryExpr(node) }
    override func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind { visitDictionaryType(node) }
    override func visit(_ node: DifferentiabilityArgumentSyntax) -> SyntaxVisitorContinueKind { visitDifferentiabilityArgument(node) }
    override func visit(_ node: DifferentiabilityArgumentsSyntax) -> SyntaxVisitorContinueKind { visitDifferentiabilityArguments(node) }
    override func visit(_ node: DifferentiabilityWithRespectToArgumentSyntax) -> SyntaxVisitorContinueKind { visitDifferentiabilityWithRespectToArgument(node) }
    override func visit(_ node: DifferentiableAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind { visitDifferentiableAttributeArguments(node) }
    override func visit(_ node: DiscardAssignmentExprSyntax) -> SyntaxVisitorContinueKind { visitDiscardAssignmentExpr(node) }
    override func visit(_ node: DiscardStmtSyntax) -> SyntaxVisitorContinueKind { visitDiscardStmt(node) }
    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind { visitDoStmt(node) }
    override func visit(_ node: DocumentationAttributeArgumentSyntax) -> SyntaxVisitorContinueKind { visitDocumentationAttributeArgument(node) }
    override func visit(_ node: EditorPlaceholderExprSyntax) -> SyntaxVisitorContinueKind { visitEditorPlaceholderExpr(node) }
    override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind { visitEnumCaseDecl(node) }
    override func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind { visitEnumCaseElement(node) }
    override func visit(_ node: EnumCaseParameterClauseSyntax) -> SyntaxVisitorContinueKind { visitEnumCaseParameterClause(node) }
    override func visit(_ node: EnumCaseParameterListSyntax) -> SyntaxVisitorContinueKind { visitEnumCaseParameterList(node) }
    override func visit(_ node: EnumCaseParameterSyntax) -> SyntaxVisitorContinueKind { visitEnumCaseParameter(node) }
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind { visitEnumDecl(node) }
    override func visit(_ node: ExpressionPatternSyntax) -> SyntaxVisitorContinueKind { visitExpressionPattern(node) }
    override func visit(_ node: ExpressionSegmentSyntax) -> SyntaxVisitorContinueKind { visitExpressionSegment(node) }
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind { visitExtensionDecl(node) }
    override func visit(_ node: FallThroughStmtSyntax) -> SyntaxVisitorContinueKind { visitFallThroughStmt(node) }
    override func visit(_ node: FloatLiteralExprSyntax) -> SyntaxVisitorContinueKind { visitFloatLiteralExpr(node) }
    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind { visitForStmt(node) }
    override func visit(_ node: ForceUnwrapExprSyntax) -> SyntaxVisitorContinueKind { visitForceUnwrapExpr(node) }
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind { visitFunctionCallExpr(node) }
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { visitFunctionDecl(node) }
    override func visit(_ node: FunctionEffectSpecifiersSyntax) -> SyntaxVisitorContinueKind { visitFunctionEffectSpecifiers(node) }
    override func visit(_ node: FunctionParameterClauseSyntax) -> SyntaxVisitorContinueKind { visitFunctionParameterClause(node) }
    override func visit(_ node: FunctionParameterListSyntax) -> SyntaxVisitorContinueKind { visitFunctionParameterList(node) }
    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind { visitFunctionParameter(node) }
    override func visit(_ node: FunctionSignatureSyntax) -> SyntaxVisitorContinueKind { visitFunctionSignature(node) }
    override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind { visitFunctionType(node) }
    override func visit(_ node: GenericArgumentClauseSyntax) -> SyntaxVisitorContinueKind { visitGenericArgumentClause(node) }
    override func visit(_ node: GenericArgumentSyntax) -> SyntaxVisitorContinueKind { visitGenericArgument(node) }
    override func visit(_ node: GenericParameterClauseSyntax) -> SyntaxVisitorContinueKind { visitGenericParameterClause(node) }
    override func visit(_ node: GenericParameterListSyntax) -> SyntaxVisitorContinueKind { visitGenericParameterList(node) }
    override func visit(_ node: GenericParameterSyntax) -> SyntaxVisitorContinueKind { visitGenericParameter(node) }
    override func visit(_ node: GenericRequirementSyntax) -> SyntaxVisitorContinueKind { visitGenericRequirement(node) }
    override func visit(_ node: GenericSpecializationExprSyntax) -> SyntaxVisitorContinueKind { visitGenericSpecializationExpr(node) }
    override func visit(_ node: GenericWhereClauseSyntax) -> SyntaxVisitorContinueKind { visitGenericWhereClause(node) }
    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind { visitGuardStmt(node) }
    override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind { visitIdentifierPattern(node) }
    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind { visitIdentifierType(node) }
    override func visit(_ node: IfConfigClauseSyntax) -> SyntaxVisitorContinueKind { visitIfConfigClause(node) }
    override func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind { visitIfConfigDecl(node) }
    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind { visitIfExpr(node) }
    override func visit(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) -> SyntaxVisitorContinueKind { visitImplicitlyUnwrappedOptionalType(node) }
    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind { visitImportDecl(node) }
    override func visit(_ node: InOutExprSyntax) -> SyntaxVisitorContinueKind { visitInOutExpr(node) }
    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind { visitInfixOperatorExpr(node) }
    override func visit(_ node: InheritanceClauseSyntax) -> SyntaxVisitorContinueKind { visitInheritanceClause(node) }
    override func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind { visitInheritedType(node) }
    override func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind { visitInitializerClause(node) }
    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind { visitInitializerDecl(node) }
    override func visit(_ node: InlineArrayTypeSyntax) -> SyntaxVisitorContinueKind { visitInlineArrayType(node) }
    override func visit(_ node: ImportPathComponentSyntax) -> SyntaxVisitorContinueKind { visitImportPathComponent(node) }
    override func visit(_ node: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind { visitIntegerLiteralExpr(node) }
    override func visit(_ node: IsExprSyntax) -> SyntaxVisitorContinueKind { visitIsExpr(node) }
    override func visit(_ node: IsTypePatternSyntax) -> SyntaxVisitorContinueKind { visitIsTypePattern(node) }
    override func visit(_ node: KeyPathComponentSyntax) -> SyntaxVisitorContinueKind { visitKeyPathComponent(node) }
    override func visit(_ node: KeyPathExprSyntax) -> SyntaxVisitorContinueKind { visitKeyPathExpr(node) }
    override func visit(_ node: KeyPathSubscriptComponentSyntax) -> SyntaxVisitorContinueKind { visitKeyPathSubscriptComponent(node) }
    override func visit(_ node: LabeledExprListSyntax) -> SyntaxVisitorContinueKind { visitLabeledExprList(node) }
    override func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind { visitLabeledExpr(node) }
    override func visit(_ node: LabeledStmtSyntax) -> SyntaxVisitorContinueKind { visitLabeledStmt(node) }
    override func visit(_ node: MacroDeclSyntax) -> SyntaxVisitorContinueKind { visitMacroDecl(node) }
    override func visit(_ node: MacroExpansionDeclSyntax) -> SyntaxVisitorContinueKind { visitMacroExpansionDecl(node) }
    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind { visitMacroExpansionExpr(node) }
    override func visit(_ node: MatchingPatternConditionSyntax) -> SyntaxVisitorContinueKind { visitMatchingPatternCondition(node) }
    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind { visitMemberAccessExpr(node) }
    override func visit(_ node: MemberBlockItemListSyntax) -> SyntaxVisitorContinueKind { visitMemberBlockItemList(node) }
    override func visit(_ node: MemberBlockItemSyntax) -> SyntaxVisitorContinueKind { visitMemberBlockItem(node) }
    override func visit(_ node: MemberBlockSyntax) -> SyntaxVisitorContinueKind { visitMemberBlock(node) }
    override func visit(_ node: MemberTypeSyntax) -> SyntaxVisitorContinueKind { visitMemberType(node) }
    override func visit(_ node: MultipleTrailingClosureElementSyntax) -> SyntaxVisitorContinueKind { visitMultipleTrailingClosureElement(node) }
    override func visit(_ node: MetatypeTypeSyntax) -> SyntaxVisitorContinueKind { visitMetatypeType(node) }
    override func visit(_ node: NilLiteralExprSyntax) -> SyntaxVisitorContinueKind { visitNilLiteralExpr(node) }
    override func visit(_ node: ObjCSelectorPieceListSyntax) -> SyntaxVisitorContinueKind { visitObjCSelectorPieceList(node) }
    override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind { visitOperatorDecl(node) }
    override func visit(_ node: OperatorPrecedenceAndTypesSyntax) -> SyntaxVisitorContinueKind { visitOperatorPrecedenceAndTypes(node) }
    override func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind { visitOptionalBindingCondition(node) }
    override func visit(_ node: OptionalChainingExprSyntax) -> SyntaxVisitorContinueKind { visitOptionalChainingExpr(node) }
    override func visit(_ node: OptionalTypeSyntax) -> SyntaxVisitorContinueKind { visitOptionalType(node) }
    override func visit(_ node: OriginallyDefinedInAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind { visitOriginallyDefinedInAttributeArguments(node) }
    override func visit(_ node: PackElementExprSyntax) -> SyntaxVisitorContinueKind { visitPackElementExpr(node) }
    override func visit(_ node: PackElementTypeSyntax) -> SyntaxVisitorContinueKind { visitPackElementType(node) }
    override func visit(_ node: PackExpansionExprSyntax) -> SyntaxVisitorContinueKind { visitPackExpansionExpr(node) }
    override func visit(_ node: PackExpansionTypeSyntax) -> SyntaxVisitorContinueKind { visitPackExpansionType(node) }
    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind { visitPatternBinding(node) }
    override func visit(_ node: PatternExprSyntax) -> SyntaxVisitorContinueKind { visitPatternExpr(node) }
    override func visit(_ node: PlatformVersionItemListSyntax) -> SyntaxVisitorContinueKind { visitPlatformVersionItemList(node) }
    override func visit(_ node: PlatformVersionSyntax) -> SyntaxVisitorContinueKind { visitPlatformVersion(node) }
    override func visit(_ node: PostfixIfConfigExprSyntax) -> SyntaxVisitorContinueKind { visitPostfixIfConfigExpr(node) }
    override func visit(_ node: PostfixOperatorExprSyntax) -> SyntaxVisitorContinueKind { visitPostfixOperatorExpr(node) }
    override func visit(_ node: PrecedenceGroupAssignmentSyntax) -> SyntaxVisitorContinueKind { visitPrecedenceGroupAssignment(node) }
    override func visit(_ node: PrecedenceGroupAssociativitySyntax) -> SyntaxVisitorContinueKind { visitPrecedenceGroupAssociativity(node) }
    override func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind { visitPrecedenceGroupDecl(node) }
    override func visit(_ node: PrecedenceGroupNameSyntax) -> SyntaxVisitorContinueKind { visitPrecedenceGroupName(node) }
    override func visit(_ node: PrecedenceGroupRelationSyntax) -> SyntaxVisitorContinueKind { visitPrecedenceGroupRelation(node) }
    override func visit(_ node: PrefixOperatorExprSyntax) -> SyntaxVisitorContinueKind { visitPrefixOperatorExpr(node) }
    override func visit(_ node: PrimaryAssociatedTypeClauseSyntax) -> SyntaxVisitorContinueKind { visitPrimaryAssociatedTypeClause(node) }
    override func visit(_ node: PrimaryAssociatedTypeSyntax) -> SyntaxVisitorContinueKind { visitPrimaryAssociatedType(node) }
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind { visitProtocolDecl(node) }
    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind { visitRepeatStmt(node) }
    override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind { visitReturnClause(node) }
    override func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind { visitReturnStmt(node) }
    override func visit(_ node: SameTypeRequirementSyntax) -> SyntaxVisitorContinueKind { visitSameTypeRequirement(node) }
    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind { visitSequenceExpr(node) }
    override func visit(_ node: SimpleStringLiteralExprSyntax) -> SyntaxVisitorContinueKind { visitSimpleStringLiteralExpr(node) }
    override func visit(_ node: SomeOrAnyTypeSyntax) -> SyntaxVisitorContinueKind { visitSomeOrAnyType(node) }
    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind { visitSourceFile(node) }
    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind { visitStringLiteralExpr(node) }
    override func visit(_ node: StringSegmentSyntax) -> SyntaxVisitorContinueKind { visitStringSegment(node) }
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind { visitStructDecl(node) }
    override func visit(_ node: SubscriptCallExprSyntax) -> SyntaxVisitorContinueKind { visitSubscriptCallExpr(node) }
    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind { visitSubscriptDecl(node) }
    override func visit(_ node: SuperExprSyntax) -> SyntaxVisitorContinueKind { visitSuperExpr(node) }
    override func visit(_ node: SwitchCaseLabelSyntax) -> SyntaxVisitorContinueKind { visitSwitchCaseLabel(node) }
    override func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind { visitSwitchCase(node) }
    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind { visitSwitchExpr(node) }
    override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind { visitTernaryExpr(node) }
    override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind { visitThrowStmt(node) }
    override func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind { visitTryExpr(node) }
    override func visit(_ node: TupleExprSyntax) -> SyntaxVisitorContinueKind { visitTupleExpr(node) }
    override func visit(_ node: TuplePatternElementListSyntax) -> SyntaxVisitorContinueKind { visitTuplePatternElementList(node) }
    override func visit(_ node: TuplePatternElementSyntax) -> SyntaxVisitorContinueKind { visitTuplePatternElement(node) }
    override func visit(_ node: TuplePatternSyntax) -> SyntaxVisitorContinueKind { visitTuplePattern(node) }
    override func visit(_ node: TupleTypeElementSyntax) -> SyntaxVisitorContinueKind { visitTupleTypeElement(node) }
    override func visit(_ node: TupleTypeSyntax) -> SyntaxVisitorContinueKind { visitTupleType(node) }
    override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind { visitTypeAliasDecl(node) }
    override func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind { visitTypeAnnotation(node) }
    override func visit(_ node: TypeEffectSpecifiersSyntax) -> SyntaxVisitorContinueKind { visitTypeEffectSpecifiers(node) }
    override func visit(_ node: TypeExprSyntax) -> SyntaxVisitorContinueKind { visitTypeExpr(node) }
    override func visit(_ node: TypeInitializerClauseSyntax) -> SyntaxVisitorContinueKind { visitTypeInitializerClause(node) }
    override func visit(_ node: UnexpectedNodesSyntax) -> SyntaxVisitorContinueKind { visitUnexpectedNodes(node) }
    override func visit(_ node: UnsafeExprSyntax) -> SyntaxVisitorContinueKind { visitUnsafeExpr(node) }
    override func visit(_ node: ValueBindingPatternSyntax) -> SyntaxVisitorContinueKind { visitValueBindingPattern(node) }
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind { visitVariableDecl(node) }
    override func visit(_ node: WhereClauseSyntax) -> SyntaxVisitorContinueKind { visitWhereClause(node) }
    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind { visitWhileStmt(node) }
    override func visit(_ node: WildcardPatternSyntax) -> SyntaxVisitorContinueKind { visitWildcardPattern(node) }
    override func visit(_ node: YieldStmtSyntax) -> SyntaxVisitorContinueKind { visitYieldStmt(node) }
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind { visitToken(token) }
    override func visitPost(_ node: FunctionCallExprSyntax) { visitPostFunctionCallExpr(node) }
    override func visitPost(_ node: MemberAccessExprSyntax) { visitPostMemberAccessExpr(node) }
    override func visitPost(_ node: PostfixIfConfigExprSyntax) { visitPostPostfixIfConfigExpr(node) }
    override func visitPost(_ node: SubscriptCallExprSyntax) { visitPostSubscriptCallExpr(node) }
}

extension Syntax {
    /// Creates a pretty-printable token stream for the provided Syntax node.
    func makeTokenStream(
        configuration: Configuration,
        selection: Selection,
        operatorTable: OperatorTable
    ) -> [Token] {
        let commentsMoved = CommentMovingRewriter(selection: selection).rewrite(self)
        return TokenStreamCreator(
            configuration: configuration,
            selection: selection,
            operatorTable: operatorTable
        ).makeStream(from: commentsMoved)
    }
}

extension TriviaPiece {
    /// True if the trivia piece is unexpected text.
    var isUnexpectedText: Bool {
        switch self {
        case .unexpectedText: return true
        default: return false
        }
    }
}

extension NewlineBehavior {
    static func + (lhs: NewlineBehavior, rhs: NewlineBehavior) -> NewlineBehavior {
        switch (lhs, rhs) {
        case (.elective, _):
            // `rhs` is either also elective or a required newline, which overwrites elective.
            return rhs
        case (_, .elective):
            // `lhs` is either also elective or a required newline, which overwrites elective.
            return lhs

        case (.escaped, _):
            return rhs
        case (_, .escaped):
            return lhs
        case (.soft(let lhsCount, let lhsDiscretionary), .soft(let rhsCount, let rhsDiscretionary)):
            let mergedCount: Int
            if lhsDiscretionary && rhsDiscretionary {
                mergedCount = lhsCount + rhsCount
            } else if lhsDiscretionary {
                mergedCount = lhsCount
            } else if rhsDiscretionary {
                mergedCount = rhsCount
            } else {
                mergedCount = max(lhsCount, rhsCount)
            }
            return .soft(count: mergedCount, discretionary: lhsDiscretionary || rhsDiscretionary)

        case (.soft(let softCount, _), .hard(let hardCount)),
            (.hard(let hardCount), .soft(let softCount, _)):
            return .hard(count: max(softCount, hardCount))

        case (.hard(let lhsCount), .hard(let rhsCount)):
            return .hard(count: lhsCount + rhsCount)
        }
    }
}
