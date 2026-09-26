import SwiftSyntax

/// Require `[weak self]` in an `Observations` closure that a class or an actor creates.
///
/// An `Observations` sequence keeps its closure while a consumer iterates the sequence. A closure
/// that captures `self` strongly keeps the owner alive for the same time. A `for await` loop over
/// the sequence does not end by itself, so the owner often stays alive until the process ends. Add
/// `[weak self]` to the capture list and read `self?` in the closure.
///
/// The rule also checks a `for await` loop over an `Observations` sequence inside a `Task { }`
/// closure. The task keeps its closure until the loop ends. If the task closure captures `self`
/// strongly, the task keeps the owner alive. The rule matches a sequence that the loop creates
/// directly, or a local that an `Observations` initializer binds in the same function.
///
/// Swift requires an explicit `self.` in an escaping closure of a class or an actor, unless the
/// capture list holds `self`. So the rule looks for an explicit `self` in the closure body and for
/// a strong `self` in the capture list. A value type does not have this problem, so the rule does
/// not check a struct or an enum. The rule checks an extension only when the same file declares the
/// extended type as a class or an actor. A static member does not capture an instance, so the rule
/// does not check it.
///
/// The rule does not check `[weak self]` followed by `guard let self` before the loop. That form
/// also keeps the owner alive while the loop runs. A task that the owner stores and cancels also
/// gets a finding. Suppress the finding for that task.
///
/// `UseWeakSelfInClosures` reports `unowned` captures. `FlagRecursiveObservationTracking` reports
/// the recursive `withObservationTracking` pattern. This rule does not repeat either check.
///
/// Lint: An `Observations` closure in a class or an actor captures `self` strongly, or a
/// `for await` loop over `Observations` runs in a `Task` closure that captures `self` strongly.
final class RequireWeakSelfInObservations: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .memory }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let anchor = Self.observationsAnchor(of: node),
              let closure = Self.closure(of: node),
              Self.capturesSelfStrongly(closure),
              let owner = instanceOwner(of: node) else { return .visitChildren }
        diagnose(
            .strongSelfInObservations, on: anchor, notes: notes(closure: closure, owner: owner))
        return .visitChildren
    }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        guard node.awaitKeyword != nil,
              iteratesObservations(node),
              let taskClosure = Self.enclosingTaskClosure(of: node),
              Self.capturesSelfStrongly(taskClosure),
              let owner = instanceOwner(of: taskClosure) else { return .visitChildren }
        diagnose(
            .strongSelfTaskOverObservations,
            on: node.forKeyword,
            notes: notes(closure: taskClosure, owner: owner)
        )
        return .visitChildren
    }

    // MARK: - Notes

    private func notes(closure: ClosureExprSyntax, owner: OwnerName) -> [Finding.Note] {
        let converter = context.sourceLocationConverter
        return [
            Finding.Note(
                message: .closureCapturesSelf,
                location: Finding.Location(closure.leftBrace.startLocation(converter: converter)),
                role: .closure
            ),
            Finding.Note(
                message: .ownerKeptAlive(owner.name),
                location: Finding.Location(owner.node.startLocation(converter: converter)),
                role: .owner
            ),
        ]
    }

    // MARK: - Observations calls

    /// The node to report for an `Observations { }` or `Observations.untilFinished { }` call, or
    /// `nil` when the call is not one of them.
    private static func observationsAnchor(of call: FunctionCallExprSyntax) -> Syntax? {
        let callee = call.calledExpression
        if isObservationsType(callee) { return Syntax(callee) }

        if let member = callee.as(MemberAccessExprSyntax.self),
           member.declName.baseName.text == "untilFinished",
           let base = member.base,
           isObservationsType(base) { return Syntax(member.declName) }
        return nil
    }

    /// Whether `expr` names the `Observations` type, with or without generic arguments.
    private static func isObservationsType(_ expr: ExprSyntax) -> Bool {
        if let ref = expr.as(DeclReferenceExprSyntax.self) {
            return ref.baseName.text == "Observations"
        }

        if let generic = expr.as(GenericSpecializationExprSyntax.self) {
            return isObservationsType(generic.expression)
        }
        return false
    }

    /// Whether `expr` , without `try` and `await` , creates an `Observations` sequence.
    private static func isObservationsCall(_ expr: ExprSyntax) -> Bool {
        guard let call = unwrapped(expr).as(FunctionCallExprSyntax.self) else { return false }
        return observationsAnchor(of: call) != nil
    }

    private static func unwrapped(_ expr: ExprSyntax) -> ExprSyntax {
        if let tryExpr = expr.as(TryExprSyntax.self) { return unwrapped(tryExpr.expression) }
        if let awaitExpr = expr.as(AwaitExprSyntax.self) { return unwrapped(awaitExpr.expression) }
        return expr
    }

    /// The trailing closure of `call` , or its first argument when the argument is a closure.
    private static func closure(of call: FunctionCallExprSyntax) -> ClosureExprSyntax? {
        if let trailing = call.trailingClosure { return trailing }
        return call.arguments.first?.expression.as(ClosureExprSyntax.self)
    }

    // MARK: - Self capture

    /// Whether `closure` captures `self` strongly.
    ///
    /// A capture list entry decides the answer when it names `self` . Otherwise an explicit `self`
    /// in the body decides it.
    private static func capturesSelfStrongly(_ closure: ClosureExprSyntax) -> Bool {
        let selfCaptures = closure.signature?.capture?.items.filter(capturesSelf) ?? []
        if !selfCaptures.isEmpty { return selfCaptures.contains { $0.specifier == nil } }
        let finder = SelfReferenceFinder(viewMode: .sourceAccurate)
        finder.walk(closure.statements)
        return finder.found
    }

    private static func capturesSelf(_ item: ClosureCaptureSyntax) -> Bool {
        guard let initializer = item.initializer else {
            return item.name.tokenKind == .keyword(.self)
        }
        return initializer.value.as(DeclReferenceExprSyntax.self)?.baseName
            .tokenKind
            == .keyword(.self)
    }

    // MARK: - Task loops

    /// Whether the loop iterates an `Observations` sequence that it creates, or a local that an
    /// `Observations` initializer binds in the same function.
    private func iteratesObservations(_ loop: ForStmtSyntax) -> Bool {
        let sequence = Self.unwrapped(loop.sequence)
        if Self.isObservationsCall(sequence) { return true }
        guard let ref = sequence.as(DeclReferenceExprSyntax.self), ref.argumentNames == nil
        else { return false }
        return Self.localBindsObservations(named: ref.baseName.text, before: loop)
    }

    private static func localBindsObservations(
        named name: String,
        before node: ForStmtSyntax
    ) -> Bool {
        var current = Syntax(node)

        while let parent = current.parent {
            if parent.is(FunctionDeclSyntax.self) || parent.is(MemberBlockSyntax.self) {
                return false
            }

            if let items = parent.as(CodeBlockItemListSyntax.self) {
                for item in items {
                    if item.position >= current.position { break }
                    guard let decl = item.item.as(VariableDeclSyntax.self) else { continue }

                    for binding in decl.bindings {
                        if binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
                            .text == name,
                           let value = binding.initializer?.value,
                           isObservationsCall(value) { return true }
                    }
                }
            }
            current = parent
        }
        return false
    }

    /// The closure of the `Task` that holds `node` , when the nearest closure around `node` is one.
    private static func enclosingTaskClosure(of node: some SyntaxProtocol) -> ClosureExprSyntax? {
        var current = node.parent
        while let cur = current, !cur.is(ClosureExprSyntax.self) { current = cur.parent }
        guard let closure = current?.as(ClosureExprSyntax.self) else { return nil }

        var callNode = closure.parent
        if callNode?.is(LabeledExprSyntax.self) == true { callNode = callNode?.parent?.parent }
        guard let call = callNode?.as(FunctionCallExprSyntax.self),
              isTaskCallee(call.calledExpression) else { return nil }
        return closure
    }

    private static func isTaskCallee(_ expr: ExprSyntax) -> Bool {
        if let ref = expr.as(DeclReferenceExprSyntax.self) { return ref.baseName.text == "Task" }

        if let generic = expr.as(GenericSpecializationExprSyntax.self) {
            return isTaskCallee(generic.expression)
        }

        if let member = expr.as(MemberAccessExprSyntax.self), let base = member.base {
            let factories: Set = ["detached", "immediate", "immediateDetached"]
            return factories.contains(member.declName.baseName.text) && isTaskCallee(base)
        }
        return false
    }

    // MARK: - Owner

    private struct OwnerName {
        let name: String
        let node: Syntax
    }

    /// The class or actor whose instance member holds `node` , or `nil` for a value type, a static
    /// member, or code outside a type.
    private func instanceOwner(of node: some SyntaxProtocol) -> OwnerName? {
        var current = node.parent

        while let cur = current {
            if Self.isStaticMember(cur) { return nil }

            if cur.is(MemberBlockSyntax.self), let decl = cur.parent {
                if let classDecl = decl.as(ClassDeclSyntax.self) {
                    return OwnerName(name: classDecl.name.text, node: Syntax(classDecl.name))
                }

                if let actorDecl = decl.as(ActorDeclSyntax.self) {
                    return OwnerName(name: actorDecl.name.text, node: Syntax(actorDecl.name))
                }
                guard let ext = decl.as(ExtensionDeclSyntax.self),
                      let name = TypeMemberIndex.typeName(of: decl),
                      let kind = context.typeMembers(around: node).types[name]?.kind,
                      kind == .class || kind == .actor else { return nil }
                return OwnerName(name: name, node: Syntax(ext.extendedType))
            }
            current = cur.parent
        }
        return nil
    }

    private static func isStaticMember(_ node: Syntax) -> Bool {
        guard node.parent?.is(MemberBlockItemSyntax.self) == true else { return false }
        let modifiers: DeclModifierListSyntax? = node.as(FunctionDeclSyntax.self)?.modifiers
            ?? node.as(VariableDeclSyntax.self)?.modifiers
            ?? node.as(SubscriptDeclSyntax.self)?.modifiers
        return modifiers?.contains {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        } ?? false
    }
}

/// Finds an explicit `self` expression.
private final class SelfReferenceFinder: SyntaxVisitor {
    var found = false

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        if node.baseName.tokenKind == .keyword(.self) { found = true }
        return found ? .skipChildren : .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let strongSelfInObservations: Finding.Message =
        "'Observations' closure captures 'self' strongly; add '[weak self]' so that the sequence does not keep the owner alive"

    static let strongSelfTaskOverObservations: Finding.Message =
        "'for await' over 'Observations' runs in a 'Task' that captures 'self' strongly; the loop does not end, so the task keeps the owner alive"

    static let closureCapturesSelf: Finding.Message = "the closure that captures 'self'"

    static func ownerKeptAlive(_ name: String) -> Finding.Message {
        "'\(name)' is the owner that the closure keeps alive"
    }
}
