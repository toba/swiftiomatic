import Foundation
import SwiftSyntax

/// A declaration of an identifier within a lexical scope
enum IdentifierDeclaration: Hashable {
    /// A function or closure parameter
    case parameter(name: TokenSyntax)
    /// A local `let` or `var` binding
    case localVariable(name: TokenSyntax)
    /// A compiler-synthesized variable (e.g. `error` in bare `catch` clauses)
    case implicitVariable(name: String)
    /// A wildcard `_` binding that is invisible to name lookup
    case wildcard
    /// A sentinel that marks a type boundary where name lookup stops
    case lookupBoundary

    /// The textual name of the declared identifier (e.g. `a` in `let a = 1`)
    fileprivate var name: String {
        switch self {
            case let .parameter(name): name.text
            case let .localVariable(name): name.text
            case let .implicitVariable(name): name
            case .wildcard: "_"
            case .lookupBoundary: ""
        }
    }

    /// Whether this declaration matches the given identifier name
    ///
    /// Wildcards never match. Backtick-escaped names are normalized by default
    /// since backticks only disambiguate and do not contribute to name resolution.
    ///
    /// - Parameters:
    ///   - id: The identifier name to compare against.
    ///   - disregardBackticks: If `true`, strips backticks before comparing.
    /// - Returns: `true` if this declaration's name matches `id`.
    func declares(id: String, disregardBackticks: Bool = true) -> Bool {
        if self == .wildcard || id == "_" {
            // Insignificant names cannot refer to each other.
            return false
        }
        if disregardBackticks {
            let backticks = CharacterSet(charactersIn: "`")
            return id.trimmingCharacters(in: backticks) == name.trimmingCharacters(in: backticks)
        }
        return id == name
    }
}

/// A ``ViolationCollectingVisitor`` that tracks declared identifiers per lexical scope
///
/// Maintains a hierarchical ``Stack`` of identifier declarations as it walks
/// the AST. Rules that need to know which names are in scope at a given point
/// should subclass this visitor.
class DeclaredIdentifiersTrackingVisitor<Configuration: RuleConfiguration>:
    ViolationCollectingVisitor<Configuration>
{
    /// A stack of identifier arrays representing nested lexical scopes
    typealias Scope = Stack<[IdentifierDeclaration]>

    /// The hierarchical stack of declared identifiers up to the current AST position
    var scope: Scope

    /// Creates a visitor with rule configuration, source file, and optional pre-filled scope
    ///
    /// - Parameters:
    ///   - configuration: Configuration of a rule.
    ///   - file: The source file whose syntax tree will be traversed.
    ///   - scope: A pre-filled scope to continue collecting into.
    @inlinable
    init(configuration: Configuration, file: SwiftSource, scope: Scope = Scope()) {
        self.scope = scope
        super.init(configuration: configuration, file: file)
    }

    /// Whether a given identifier has been declared in any enclosing scope
    ///
    /// - Parameters:
    ///   - identifier: The identifier name to look up.
    /// - Returns: `true` if a matching declaration exists in scope.
    func hasSeenDeclaration(for identifier: String) -> Bool {
        scope.contains { $0.contains { $0.name == identifier } }
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        scope.openChildScope()
        guard let parent = node.parent, !parent.is(SourceFileSyntax.self),
              let grandParent = parent.parent
        else {
            return .visitChildren
        }
        if let ifStmt = grandParent.as(IfExprSyntax.self),
           parent.keyPathInParent != \IfExprSyntax.elseBody
        {
            collectIdentifiers(from: ifStmt.conditions)
        } else if let whileStmt = grandParent.as(WhileStmtSyntax.self) {
            collectIdentifiers(from: whileStmt.conditions)
        } else if let pattern = grandParent.as(ForStmtSyntax.self)?.pattern {
            collectIdentifiers(from: pattern)
        } else if let parameters = grandParent.as(FunctionDeclSyntax.self)?.signature
            .parameterClause
            .parameters
        {
            collectIdentifiers(from: parameters)
        } else if let parameters = grandParent.as(InitializerDeclSyntax.self)?.signature
            .parameterClause
            .parameters
        {
            collectIdentifiers(from: parameters)
        } else if let parameters = grandParent.as(SubscriptDeclSyntax.self)?.parameterClause
            .parameters
        {
            collectIdentifiers(from: parameters)
        } else if let closureParameters = parent.as(ClosureExprSyntax.self)?.signature?
            .parameterClause
        {
            collectIdentifiers(from: closureParameters)
        } else if let switchCase = parent.as(SwitchCaseSyntax.self)?.label.as(
            SwitchCaseLabelSyntax.self,
        ) {
            collectIdentifiers(from: switchCase)
        } else if let catchClause = grandParent.as(CatchClauseSyntax.self) {
            collectIdentifiers(from: catchClause)
        }
        return .visitChildren
    }

    override func visitPost(_: CodeBlockItemListSyntax) {
        scope.pop()
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        if node.parent?.is(MemberBlockItemSyntax.self) != true {
            for binding in node.bindings {
                collectIdentifiers(from: binding.pattern)
            }
        }
    }

    override func visitPost(_ node: GuardStmtSyntax) {
        collectIdentifiers(from: node.conditions)
    }

    // MARK: Type declaration boundaries

    override func visit(_ node: MemberBlockSyntax) -> SyntaxVisitorContinueKind {
        if node.belongsToTypeDefinableInFunction {
            scope.push([.lookupBoundary])
        }
        return .visitChildren
    }

    override func visitPost(_ node: MemberBlockSyntax) {
        if node.belongsToTypeDefinableInFunction {
            scope.pop()
        }
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.parent?.is(MemberBlockItemSyntax.self) != true {
            scope.addToCurrentScope(.localVariable(name: node.name))
        }
        return .visitChildren
    }

    // MARK: Private methods

    private func collectIdentifiers(from parameters: FunctionParameterListSyntax) {
        for param in parameters {
            let name = param.secondName ?? param.firstName
            scope.addToCurrentScope(.parameter(name: name))
        }
    }

    private func collectIdentifiers(from closureParameters: ClosureSignatureSyntax
        .ParameterClause)
    {
        switch closureParameters {
            case let .parameterClause(parameters):
                for param in parameters.parameters {
                    let name = param.secondName ?? param.firstName
                    scope.addToCurrentScope(.parameter(name: name))
                }
            case let .simpleInput(parameters):
                for param in parameters {
                    let name = param.name
                    scope.addToCurrentScope(.parameter(name: name))
                }
        }
    }

    private func collectIdentifiers(from switchCase: SwitchCaseLabelSyntax) {
        switchCase.caseItems
            .map { item -> PatternSyntax in
                item.pattern.as(ValueBindingPatternSyntax.self)?.pattern ?? item.pattern
            }
            .compactMap { pattern -> FunctionCallExprSyntax? in
                pattern.as(ExpressionPatternSyntax.self)?.expression.asFunctionCall
            }
            .map(\.arguments)
            .flatMap(\.self)
            .compactMap { labeledExpr -> PatternExprSyntax? in
                labeledExpr.expression.as(PatternExprSyntax.self)
            }
            .map { patternExpr -> any PatternSyntaxProtocol in
                patternExpr.pattern.as(ValueBindingPatternSyntax.self)?.pattern ?? patternExpr
                    .pattern
            }
            .forEach {
                collectIdentifiers(from: PatternSyntax(fromProtocol: $0))
            }
    }

    private func collectIdentifiers(from catchClause: CatchClauseSyntax) {
        let items = catchClause.catchItems
        if items.isEmpty {
            // A catch clause without explicit catch items has an implicit `error` variable in scope.
            scope.addToCurrentScope(.implicitVariable(name: "error"))
        } else {
            items
                .compactMap { $0.pattern?.as(ValueBindingPatternSyntax.self)?.pattern }
                .forEach(collectIdentifiers(from:))
        }
    }

    private func collectIdentifiers(from conditions: ConditionElementListSyntax) {
        conditions
            .compactMap { $0.condition.as(OptionalBindingConditionSyntax.self)?.pattern }
            .forEach { collectIdentifiers(from: $0) }
    }

    private func collectIdentifiers(from pattern: PatternSyntax) {
        if let id = pattern.as(IdentifierPatternSyntax.self)?.identifier {
            scope.addToCurrentScope(.localVariable(name: id))
        }
    }
}

private extension DeclaredIdentifiersTrackingVisitor.Scope {
    mutating func addToCurrentScope(_ decl: IdentifierDeclaration) {
        modifyLast { $0.append(decl.name == "_" ? .wildcard : decl) }
    }

    mutating func openChildScope() {
        push([])
    }
}

private extension MemberBlockSyntax {
    var belongsToTypeDefinableInFunction: Bool {
        if let parent {
            return [.actorDecl, .classDecl, .enumDecl, .structDecl].contains(parent.kind)
        }
        return false
    }
}
