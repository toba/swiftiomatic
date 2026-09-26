import SwiftSyntax

/// Flag an initializer assignment to a property whose `willSet` or `didSet` observer then does not
/// run.
///
/// Swift does not call a property's observers when the type's own initializer assigns the property.
/// An observer that resets a cache, posts a notification or validates the value is therefore
/// skipped for the first value. That is often correct, because the rest of the state is not ready
/// yet. When the observer must run, assign the value from a `defer` block in the initializer, or
/// from a method that the initializer calls.
///
/// The rule stays silent for a property that a `defer` block in the same initializer assigns, or
/// that a method the initializer calls assigns. An assignment inside a closure or a nested function
/// does not count, because it does not run as part of the initializer.
///
/// Lint: An initializer assignment to an observed stored property raises a warning.
final class FlagObserverSkippedInInit: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock)
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock)
        return .visitChildren
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock)
        return .visitChildren
    }

    private func check(_ memberBlock: MemberBlockSyntax) {
        let decls = memberBlock.members.map(\.decl)
        let observed = Set(
            decls.compactMap { $0.as(VariableDeclSyntax.self) }.flatMap(\.observedNames))
        guard !observed.isEmpty else { return }

        var assignedByMethod = [String: Set<String>]()

        for function in decls.compactMap({ $0.as(FunctionDeclSyntax.self) })
            where !function.modifiers.contains(anyOf: [.static, .class])
        {
            guard let body = function.body else { continue }
            let names = Set(
                AssignmentFinder.find(in: body.statements, observed: observed).map(\.name))
            assignedByMethod[function.name.text, default: []].formUnion(names)
        }

        for initializer in decls.compactMap({ $0.as(InitializerDeclSyntax.self) }) {
            guard let body = initializer.body else { continue }
            let assignments = AssignmentFinder.find(in: body.statements, observed: observed)
            let covered = coveredNames(
                body.statements, observed: observed, assignedByMethod: assignedByMethod)

            for assignment in assignments where !covered.contains(assignment.name) {
                diagnose(.flagObserverSkippedInInit(assignment.name), on: assignment.target)
            }
        }
    }

    /// Returns the observed names that a top-level `defer` block or a called instance method
    /// assigns, so their observers run after all.
    private func coveredNames(
        _ statements: CodeBlockItemListSyntax,
        observed: Set<String>,
        assignedByMethod: [String: Set<String>]
    ) -> Set<String> {
        var covered = Set<String>()

        for item in statements {
            if let deferStmt = item.item.as(DeferStmtSyntax.self) {
                covered.formUnion(
                    AssignmentFinder.find(in: deferStmt.body.statements, observed: observed).map(
                        \.name)
                )
            }
        }

        for call in statements.tokens(viewMode: .sourceAccurate).compactMap(calledMethodName) {
            covered.formUnion(assignedByMethod[call] ?? [])
        }
        return covered
    }

    /// Returns the method name when `token` is the name of a call to `name(...)` or
    /// `self.name(...)`.
    private func calledMethodName(_ token: TokenSyntax) -> String? {
        guard let reference = token.parent?.as(DeclReferenceExprSyntax.self) else { return nil }
        let callee: ExprSyntax

        if let member = reference.parent?.as(MemberAccessExprSyntax.self) {
            guard member.declName.id == reference.id, member.base?.isSelf == true
            else { return nil }
            callee = ExprSyntax(member)
        } else {
            callee = ExprSyntax(reference)
        }
        guard let call = callee.parent?.as(FunctionCallExprSyntax.self),
              call.calledExpression.id == callee.id else { return nil }
        return token.text
    }
}

/// Finds assignments to observed properties in one scope, without nested closures, functions or
/// `defer` blocks.
private final class AssignmentFinder: SyntaxVisitor {
    struct Assignment {
        let name: String
        let target: ExprSyntax
    }

    let observed: Set<String>
    var assignments: [Assignment] = []

    static func find(in node: some SyntaxProtocol, observed: Set<String>) -> [Assignment] {
        let finder = AssignmentFinder(observed: observed)
        finder.walk(node)
        return finder.assignments
    }

    init(observed: Set<String>) {
        self.observed = observed
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.operator.isAssignmentOperator,
              let name = propertyName(node.leftOperand),
              observed.contains(name) else { return .visitChildren }
        assignments.append(Assignment(name: name, target: node.leftOperand))
        return .visitChildren
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: DeferStmtSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    /// Returns the property name for `name` or `self.name`.
    private func propertyName(_ expr: ExprSyntax) -> String? {
        if let reference = expr.as(DeclReferenceExprSyntax.self) { return reference.baseName.text }

        guard let member = expr.as(MemberAccessExprSyntax.self), member.base?.isSelf == true
        else { return nil }
        return member.declName.baseName.text
    }
}

fileprivate extension ExprSyntax {
    var isSelf: Bool {
        self.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self)
    }
}

fileprivate extension VariableDeclSyntax {
    /// The names of the instance stored properties this declaration gives a `willSet` or `didSet`.
    var observedNames: [String] {
        guard !modifiers.contains(anyOf: [.static, .class]) else { return [] }

        return bindings.compactMap { binding in
            guard case let .accessors(accessors)? = binding.accessorBlock?.accessors,
                  accessors.contains(where: {
                      $0.accessorSpecifier.tokenKind == .keyword(.willSet)
                          || $0.accessorSpecifier.tokenKind == .keyword(.didSet)
                  }) else { return nil }
            return binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        }
    }
}

fileprivate extension Finding.Message {
    static func flagObserverSkippedInInit(_ name: String) -> Finding.Message {
        "this assignment does not run the observer of '\(name)'; assign it in a 'defer' block or a method if the observer must run"
    }
}
