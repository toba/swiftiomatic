import SwiftSyntax

/// Flag a statement in an explicit `View` initializer that does more than store an input.
///
/// A parent creates its child views again each time it evaluates its own `body`. Work in the
/// child's initializer repeats on each of those evaluations, even when SwiftUI then skips the
/// child's `body` because its inputs did not change. Store the inputs as they arrive. When the
/// initializer only stores inputs, remove it and use the memberwise initializer.
///
/// Move the work to the place that matches what it does:
///
/// - A cheap value that you derive from the inputs goes in a computed property that `body` reads,
///   or in a smaller child view. An expensive result goes in a model that keeps it until its inputs
///   change.
/// - A synchronous effect for the appearance of the view goes in `onAppear`.
/// - A synchronous effect for a change of one value goes in `onChange(of:initial:)`. Set
///   `initial: true` when the effect must also run when the view appears.
/// - Asynchronous work, such as a load from a database or the network, goes in `task(id:)`, keyed
///   by the input.
///
/// Effects such as `Task { }`, a timer, a notification registration or a data load must not stay in
/// the initializer. The initializer runs for each new view value, not once for the view on screen.
///
/// ```swift
/// .task(id: trail.id) { profile = await loadElevationProfile(for: trail.id) }
/// ```
///
/// These statements are not work:
///
/// - an assignment of a name, a literal, a member access or `nil` to a property
/// - a property wrapper setup such as `_selection = selection` or
///   `_count = State(initialValue: start)`
/// - an assignment of the result of a `@ViewBuilder` or `@ContentBuilder` parameter call, such as
///   `self.popover = popover()`
/// - a call to `super.init(...)`
///
/// An initializer that only evaluates builder content can go away. Put `@ViewBuilder` on the stored
/// `content` property, and the memberwise initializer accepts the builder.
///
/// A delegation to `self.init(...)` is work. It runs a second initializer and often derives each
/// argument from the input, so each construction of the view pays for both.
///
/// A call in the initial value of a stored property, such as `let stamp = Date.now.formatted()`, is
/// work too. So is a call inside an array, dictionary or tuple literal, such as
/// `let columns = [GridItem(.flexible())]`. SwiftUI evaluates it each time a parent re-creates the
/// view. A `@State` initial value works the same way before Xcode 27, and in Xcode 27 when the
/// property is not `private`. The wrapper then discards every value after the first. In Xcode 27
/// and later, SwiftUI evaluates the initial value of a `private` `@State` property once, when it
/// sets up the storage. The rule still reports it, because an expensive model or an effect in that
/// value needs an owner or a lifecycle modifier. A `@StateObject` initial value is exempt, because
/// the wrapper takes it as an autoclosure and evaluates it once. Keep a trivial value, such as
/// `Color(white: 0.5)`, in the default and suppress the finding.
///
/// Each finding carries a note at the name of the view type. The note shows which type SwiftUI
/// constructs again.
///
/// Lint: An explicit initializer of a view type holds a statement other than those above, or a
/// stored property of a view type has a call, or a literal that holds a call, as its initial value.
final class NoWorkInViewInitializer: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let body = node.body, context.viewEntry(forMember: node) != nil
        else { return .skipChildren }
        let builders = Set(
            node.signature.parameterClause.parameters
                .filter(\.attributes.hasResultBuilder)
                .map { ($0.secondName ?? $0.firstName).text }
        )

        var notes: [Finding.Note]?

        for statement in body.statements where !Self.isInputSetup(statement.item, builders) {
            if notes == nil { notes = ownerNotes(for: node) }
            diagnose(.workInInitializer, on: statement.item, notes: notes ?? [])
        }
        return .skipChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard !node.modifiers.contains(anyOf: [.static, .class]),
              !Self.autoclosureWrappers.contains(node.attributes.firstAttributeName ?? ""),
              context.viewEntry(forMember: node) != nil else { return .skipChildren }

        for binding in node.bindings where binding.accessorBlock == nil {
            guard let value = binding.initializer?.value, Self.makesCall(value) else { continue }
            diagnose(.workInInitialValue, on: value, notes: ownerNotes(for: node))
        }
        return .skipChildren
    }

    /// Whether `value` is a call, or an array, dictionary or tuple literal with a call among its
    /// elements, such as `[GridItem(.flexible())]`
    private static func makesCall(_ value: ExprSyntax) -> Bool {
        if value.is(FunctionCallExprSyntax.self) { return true }

        if let array = value.as(ArrayExprSyntax.self) {
            return array.elements.contains { makesCall($0.expression) }
        }

        if let tuple = value.as(TupleExprSyntax.self) {
            return tuple.elements.contains { makesCall($0.expression) }
        }

        if let dictionary = value.as(DictionaryExprSyntax.self),
           case let .elements(elements) = dictionary.content {
            return elements.contains { makesCall($0.key) || makesCall($0.value) }
        }
        return false
    }

    /// Property wrappers that take their initial value as an autoclosure and evaluate it once
    private static let autoclosureWrappers: Set<String> = ["StateObject"]

    private static func isInputSetup(
        _ item: CodeBlockItemSyntax.Item,
        _ builders: Set<String>
    ) -> Bool {
        guard case let .expr(expression) = item else { return false }

        if let call = expression.as(FunctionCallExprSyntax.self) { return isSuperInit(call) }

        guard let assignment = expression.as(InfixOperatorExprSyntax.self),
              assignment.operator.is(AssignmentExprSyntax.self) else { return false }
        let value = assignment.rightOperand

        if isPlainValue(value) { return true }
        guard let call = value.as(FunctionCallExprSyntax.self) else { return false }

        if let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
            builders.contains(callee.baseName.text) { return true }
        // `_count = State(initialValue: start)` sets up the wrapper storage
        let target = assignment.leftOperand.assignmentRootName ?? ""
        return target.hasPrefix("_") && call.trailingClosure == nil
            && call.arguments.allSatisfy { isPlainValue($0.expression) }
    }

    /// Whether `call` is `super.init(...)`
    private static func isSuperInit(_ call: FunctionCallExprSyntax) -> Bool {
        guard let member = call.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.tokenKind == .keyword(.`init`) else { return false }
        return member.base?.is(SuperExprSyntax.self) == true
    }

    /// A note at the name of the view type that owns `member`, or no note when this file does not
    /// declare that type
    private func ownerNotes(for member: some SyntaxProtocol) -> [Finding.Note] {
        guard let declaration = TypeMemberIndex.owningDeclaration(of: member),
              let owner = TypeMemberIndex.typeNameToken(of: declaration) else { return [] }
        return [
            Finding.Note(
                message: .viewTypeConstructedAgain,
                location: Finding.Location(owner.startLocation(
                    converter: context.sourceLocationConverter))
            )
        ]
    }

    /// Whether reading `expression` costs nothing more than a load
    private static func isPlainValue(_ expression: ExprSyntax) -> Bool {
        if expression.is(DeclReferenceExprSyntax.self) || expression.is(NilLiteralExprSyntax.self)
            || expression.is(BooleanLiteralExprSyntax.self)
            || expression.is(IntegerLiteralExprSyntax.self)
            || expression.is(FloatLiteralExprSyntax.self) { return true }

        if let string = expression.as(StringLiteralExprSyntax.self) {
            return string.segments.allSatisfy { $0.is(StringSegmentSyntax.self) }
        }

        if let member = expression.as(MemberAccessExprSyntax.self) {
            return member.base.map(isPlainValue) ?? true
        }

        if let tuple = expression.as(TupleExprSyntax.self),
           let only = tuple.elements.first,
           tuple.elements.count == 1 { return isPlainValue(only.expression) }
        return false
    }
}

fileprivate extension Finding.Message {
    static let viewTypeConstructedAgain: Finding.Message =
        "SwiftUI constructs this view type again each time its parent evaluates 'body'"

    static let workInInitialValue: Finding.Message = """
        SwiftUI evaluates this initial value each time a parent re-creates the view, so the work \
        repeats. Pass the value in, or create it in a model
        """

    static let workInInitializer: Finding.Message = """
        This view initializer does work. A parent re-creates the view on each of its updates, so \
        the work repeats. Store the inputs, and move effects to 'onAppear', \
        'onChange(of:initial:)' or 'task(id:)'
        """
}
