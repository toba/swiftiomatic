import SwiftSyntax

/// Push filters, limits and counts into the fetch instead of running them on the fetched array.
///
/// `ModelContext.fetch(_:)` loads every model that the descriptor matches. A `filter` or a
/// `first(where:)` on the result then runs in memory, after the store did the full load. A
/// `#Predicate` on the `FetchDescriptor` lets the store skip the rows. `fetchLimit` does the same
/// for `prefix` , and `fetchCount(_:)` counts the rows without loading a model.
///
/// The rule checks a call chained directly on the fetch, and a local that the fetch binds in the
/// same scope. It reports a local only when the post-fetch operations are the only uses of the
/// local. When the code uses the full array for other work too, the fetch is necessary. The rule
/// does not report a `var` that the scope assigns again.
///
/// The rule is syntax-only. It accepts a `fetch` call when the receiver name contains "context" or
/// when the argument is a `FetchDescriptor` initializer. A `fetch` method of another type can match
/// when its receiver has a name such as `context` .
///
/// Lint: The result of `<context>.fetch(...)` flows into `filter` , `prefix` , `first(where:)` or
/// `count` .
final class UseFetchDescriptorNotPostFilter: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftdata }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard Self.isModelFetch(node) else { return .visitChildren }

        if let operation = Self.postFetchOperation(on: Syntax(node)) {
            report(operation, fetch: node)
        } else if let (name, scope, isVar) = Self.localBinding(of: node) {
            checkLocal(named: name, in: scope, isVar: isVar, fetch: node)
        }
        return .visitChildren
    }

    private func report(_ operation: PostFetchOperation, fetch: FunctionCallExprSyntax) {
        let note = Finding.Note(
            message: .fetchLoadsAll,
            location: Finding.Location(fetch.startLocation(
                converter: context.sourceLocationConverter)),
            role: .input
        )
        diagnose(.postFetch(operation.name, operation.fix), on: operation.anchor, notes: [note])
    }

    // MARK: - Fetch calls

    /// Whether `call` is a `ModelContext.fetch` call, judged by its receiver name or its argument.
    private static func isModelFetch(_ call: FunctionCallExprSyntax) -> Bool {
        guard let member = call.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "fetch",
            let base = member.base,
            let first = call.arguments.first,
            first.label == nil else { return false }

        if lastName(of: base)?.lowercased().contains("context") == true { return true }
        guard let argCall = first.expression.as(FunctionCallExprSyntax.self) else { return false }
        var callee = argCall.calledExpression

        if let generic = callee.as(GenericSpecializationExprSyntax.self) {
            callee = generic.expression
        }
        return callee.as(DeclReferenceExprSyntax.self)?.baseName.text == "FetchDescriptor"
    }

    private static func lastName(of expr: ExprSyntax) -> String? {
        if let ref = expr.as(DeclReferenceExprSyntax.self) { return ref.baseName.text }

        if let member = expr.as(MemberAccessExprSyntax.self) {
            return member.declName.baseName.text
        }
        return nil
    }

    // MARK: - Post-fetch operations

    private struct PostFetchOperation {
        let name: String
        let fix: String
        let anchor: DeclReferenceExprSyntax
    }

    /// The operation that `value` flows into directly, such as `value.filter { }` , or `nil` .
    private static func postFetchOperation(on value: Syntax) -> PostFetchOperation? {
        guard let member = value.parent?.as(MemberAccessExprSyntax.self),
              member.base.map(Syntax.init) == value else { return nil }
        let call = member.parent?.as(FunctionCallExprSyntax.self)
        let isCalled = call.map { $0.calledExpression.id == member.id } ?? false
        let predicate = "a '#Predicate' on the 'FetchDescriptor'"

        switch member.declName.baseName.text {
            case "count" where !isCalled:
                return .init(name: "count", fix: "'fetchCount(_:)'", anchor: member.declName)
            case "filter" where isCalled:
                return .init(name: "filter", fix: predicate, anchor: member.declName)
            case "prefix" where isCalled:
                return .init(
                    name: "prefix", fix: "'fetchLimit' on the 'FetchDescriptor'",
                    anchor: member.declName)
            case "first" where isCalled:
                guard let call,
                      call.arguments.first?.label?.text == "where"
                          || (call.arguments.isEmpty && call.trailingClosure != nil)
                else { return nil }
                return .init(name: "first(where:)", fix: predicate, anchor: member.declName)
            default: return nil
        }
    }

    // MARK: - Local bindings

    /// The local name, the enclosing statement list, and whether the binding is a `var` , when
    /// `fetch` initializes a local.
    private static func localBinding(
        of fetch: FunctionCallExprSyntax
    ) -> (String, CodeBlockItemListSyntax, Bool)? {
        var value = Syntax(fetch)

        while let parent = value.parent,
              parent.is(TryExprSyntax.self) || parent.is(AwaitExprSyntax.self)
        { value = parent }
        guard let initializer = value.parent?.as(InitializerClauseSyntax.self),
              let binding = initializer.parent?.as(PatternBindingSyntax.self),
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              let decl = binding.parent?.parent?.as(VariableDeclSyntax.self),
              let scope = decl.parent?.parent?.as(CodeBlockItemListSyntax.self) else { return nil }
        return (name, scope, decl.bindingSpecifier.tokenKind == .keyword(.var))
    }

    private func checkLocal(
        named name: String,
        in scope: CodeBlockItemListSyntax,
        isVar: Bool,
        fetch: FunctionCallExprSyntax
    ) {
        let collector = LocalUseCollector(name: name, after: fetch.endPosition)
        collector.walk(scope)
        guard !collector.references.isEmpty, !(isVar && collector.isAssigned) else { return }
        let operations = collector.references.map { Self.postFetchOperation(on: Syntax($0)) }
        guard operations.allSatisfy({ $0 != nil }) else { return }
        for operation in operations.compactMap(\.self) { report(operation, fetch: fetch) }
    }
}

/// Collects the references to one local name after a position, outside nested functions and types.
private final class LocalUseCollector: SyntaxVisitor {
    let name: String
    let start: AbsolutePosition
    var references: [DeclReferenceExprSyntax] = []
    var isAssigned = false

    init(name: String, after start: AbsolutePosition) {
        self.name = name
        self.start = start
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: StructDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: ClassDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: EnumDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: ActorDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.position >= start, node.baseName.text == name, node.argumentNames == nil
        else { return .visitChildren }
        // `x.name` names a member, not the local.
        if let member = node.parent?.as(MemberAccessExprSyntax.self), member.declName.id == node.id
        { return .visitChildren }
        references.append(node)
        return .visitChildren
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        if node.operator.is(AssignmentExprSyntax.self),
            node.leftOperand.as(DeclReferenceExprSyntax.self)?.baseName.text == name
        {
            isAssigned = true
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func postFetch(_ operation: String, _ fix: String) -> Finding.Message {
        "'\(operation)' runs in memory on every fetched model; use \(fix) in the fetch"
    }

    static let fetchLoadsAll: Finding.Message = "the fetch that loads every matching model"
}
