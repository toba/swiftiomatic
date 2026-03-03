import SwiftSyntax

struct UnhandledThrowingTaskRule {
    static let id = "unhandled_throwing_task"
    static let name = "Unhandled Throwing Task"
    static let summary = ""
    static let isOptIn = true

    var options = SeverityOption<Self>(.error)
}

extension UnhandledThrowingTaskRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension UnhandledThrowingTaskRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.hasViolation {
                violations.append(node.calledExpression.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

extension FunctionCallExprSyntax {
    fileprivate var hasViolation: Bool {
        isTaskWithImplicitErrorType && doesThrow
            && !(isAssigned || isValueOrResultAccessed || isReturnValue)
    }

    private var isTaskWithImplicitErrorType: Bool {
        if let typeIdentifier = calledExpression.as(DeclReferenceExprSyntax.self),
           typeIdentifier.baseName.text == "Task"
        {
            return true
        }

        if let specializedExpression = calledExpression.as(GenericSpecializationExprSyntax.self),
           let typeIdentifier = specializedExpression.expression.as(DeclReferenceExprSyntax.self),
           typeIdentifier.baseName.text == "Task",
           let lastGeneric = specializedExpression.genericArgumentClause
           .arguments.last?.argument.as(IdentifierTypeSyntax.self),
           lastGeneric.typeName == "_"
        {
            return true
        }

        return false
    }

    private var isAssigned: Bool {
        guard let parent else {
            return false
        }

        if parent.is(InitializerClauseSyntax.self) {
            return true
        }

        if let list = parent.as(ExprListSyntax.self),
           list.contains(where: { $0.is(AssignmentExprSyntax.self) })
        {
            return true
        }

        return false
    }

    private var isValueOrResultAccessed: Bool {
        guard let parent = parent?.as(MemberAccessExprSyntax.self) else {
            return false
        }

        return parent.declName.baseName.text == "value" || parent.declName.baseName.text == "result"
    }

    fileprivate var doesThrow: Bool {
        ThrowsVisitor(viewMode: .sourceAccurate)
            .walk(tree: self, handler: \.doesThrow)
    }
}

/// If the `doesThrow` property is true after visiting, then this node throws an error that is "unhandled."
/// Try statements inside a `do` with a `catch` that handles all errors will not be marked as throwing.
private final class ThrowsVisitor: SyntaxVisitor {
    var doesThrow = false

    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        // No need to continue traversing if we already throw.
        if doesThrow {
            return .skipChildren
        }

        // If there are no catch clauses, visit children to see if there are any try expressions.
        guard let lastCatchClause = node.catchClauses.last else {
            return .visitChildren
        }

        let catchItems = lastCatchClause.catchItems

        // If we have a value binding pattern, only an IdentifierPatternSyntax will catch
        // any error; if it's not an IdentifierPatternSyntax, we need to visit children.
        if let pattern = catchItems.last?.pattern?.as(ValueBindingPatternSyntax.self),
           !pattern.pattern.is(IdentifierPatternSyntax.self)
        {
            return .visitChildren
        }

        // Check the catch clause tree for unhandled throws.
        if ThrowsVisitor(viewMode: .sourceAccurate).walk(
            tree: lastCatchClause,
            handler: \.doesThrow,
        ) {
            doesThrow = true
        }

        // We don't need to visit children of the `do` node, since all errors are handled by the catch.
        return .skipChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // No need to continue traversing if we already throw.
        if doesThrow {
            return .skipChildren
        }

        // Result initializers with trailing closures handle thrown errors.
        if let typeIdentifier = node.calledExpression.as(DeclReferenceExprSyntax.self),
           typeIdentifier.baseName.text == "Result",
           node.trailingClosure != nil
        {
            return .skipChildren
        }

        return .visitChildren
    }

    override func visitPost(_ node: TryExprSyntax) {
        if node.questionOrExclamationMark == nil {
            doesThrow = true
        }
    }

    override func visitPost(_: ThrowStmtSyntax) {
        doesThrow = true
    }
}

extension SyntaxProtocol {
    private var isExplicitReturnValue: Bool {
        parent?.is(ReturnStmtSyntax.self) == true
    }

    private var isImplicitReturnValue: Bool {
        // 4th parent: FunctionDecl
        // 3rd parent: | CodeBlock
        // 2nd parent:   | CodeBlockItemList
        // 1st parent:     | CodeBlockItem
        // Current node:     | FunctionDeclSyntax
        guard
            let parentFunctionDecl = parent?.parent?.parent?.parent?.as(FunctionDeclSyntax.self),
            parentFunctionDecl.body?.statements.count == 1,
            parentFunctionDecl.signature.returnClause != nil
        else {
            return false
        }

        return true
    }

    fileprivate var isReturnValue: Bool {
        isExplicitReturnValue || isImplicitReturnValue
    }
}
