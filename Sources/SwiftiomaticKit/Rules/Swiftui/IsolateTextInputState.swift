import SwiftSyntax

/// Flag a text input bound to the view's own `@State` in a `body` that also builds unrelated views.
///
/// Each keystroke writes the state, and each write makes SwiftUI evaluate the whole `body` again.
/// When the same `body` builds other sections that never read the text, their construction repeats
/// on every keystroke. Move the field and its state into their own `View` , so a keystroke only
/// evaluates that view.
///
/// A view counts as unrelated when it is a sibling statement of the field, or of a container that
/// holds the field, and its source never names the state. A binding the view receives is exempt,
/// because its owner already evaluates on each keystroke.
///
/// The field can sit in `body` or in a same-type helper that builds part of the view. The rule also
/// reports the field when `body` , or a same-type member that `body` reaches, reads an
/// `@Environment` value in a member that does not name the state. That work repeats on every
/// keystroke too.
///
/// The finding carries a note at the `@State` declaration. When environment work is the cause, it
/// also carries a note at each `@Environment` declaration that the work reads.
///
/// Lint: A `TextField` , `SecureField` or `TextEditor` in `body` or a view helper binds `$name` of
/// a same-type `@State` , and two or more views beside it do not name `name` , or `body` reaches an
/// `@Environment` read in a member that does not name `name` .
final class IsolateTextInputState: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    private static let textInputs: Set<String> = ["TextField", "SecureField", "TextEditor"]

    /// The number of unrelated views at which the rule reports the field
    private static let unrelatedViewCount = 2

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let callee = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
              Self.textInputs.contains(callee),
              let text = node.arguments.first(where: { $0.label?.text == "text" }),
              let projected = text.expression.as(DeclReferenceExprSyntax.self)?.baseName.text,
              projected.hasPrefix("$"),
              let member = Self.enclosingMember(of: node),
              let entry = context.typeMembers(around: member).enclosingType(of: member),
              entry.isView else { return .visitChildren }
        let state = String(projected.dropFirst())
        guard entry.isStateProperty(state) else { return .visitChildren }

        let unrelated = Self.unrelatedSiblingCount(of: node, state: state)
        if unrelated >= Self.unrelatedViewCount {
            diagnose(
                .sharedTextInput(callee, state, unrelated), on: node,
                notes: stateNotes(entry: entry, state: state))
        } else if let values = Self.unrelatedEnvironmentReads(in: entry, state: state),
                  let first = values.first {
            diagnose(
                .sharedEnvironmentWork(callee, state, first), on: node,
                notes: stateNotes(entry: entry, state: state)
                    + environmentNotes(entry: entry, values: values, state: state))
        }
        return .visitChildren
    }

    /// A note at the `@State` declaration that the field writes
    private func stateNotes(entry: TypeMemberIndex.TypeEntry, state: String) -> [Finding.Note] {
        guard let declaration = entry.members[state]?.first(where: { $0.kind == .storedProperty })?
            .declaration else { return [] }
        return [Finding.Note(
            message: .keystrokeState(state),
            location: Finding.Location(
                declaration.startLocation(converter: context.sourceLocationConverter)),
            role: .input
        )]
    }

    /// A note at each `@Environment` declaration whose value feeds the unrelated work
    private func environmentNotes(
        entry: TypeMemberIndex.TypeEntry,
        values: [String],
        state: String
    ) -> [Finding.Note] {
        values.compactMap { value in
            let declaration = entry.members[value]?
                .first(where: { $0.kind == .storedProperty })?.declaration
            return declaration.map { declaration in
                Finding.Note(
                    message: .unrelatedEnvironmentValue(value, state),
                    location: Finding.Location(
                        declaration.startLocation(converter: context.sourceLocationConverter)),
                    role: .input
                )
            }
        }
    }

    /// The `@Environment` properties that `body` reads, directly or through the same-type members
    /// it reaches, in the first member whose source does not name `state` . The list keeps source
    /// order and holds each name once.
    ///
    /// Closures that run later, such as a `Button` action, an `.onSubmit` body or a
    /// `Task.detached` operation, are not followed, because they do not run during `body` .
    private static func unrelatedEnvironmentReads(
        in entry: TypeMemberIndex.TypeEntry,
        state: String
    ) -> [String]? {
        let environment = Set(entry.members.compactMap { name, overloads in
            overloads.contains {
                $0.kind == .storedProperty
                    && $0.declaration.as(VariableDeclSyntax.self)?.attributes
                        .firstAttributeName == "Environment"
            } ? name : nil
        })
        guard !environment.isEmpty,
              let body = entry.members["body"]?.first(where: { $0.body != nil }) else { return nil }

        var visited: Set<SyntaxIdentifier> = []
        var pending = [body]

        while !pending.isEmpty {
            let member = pending.removeFirst()
            guard let region = member.body, visited.insert(member.declaration.id).inserted
            else { continue }
            let references = TypeMemberIndex.references(
                in: region, of: entry, skipping: { $0.runsAfterBody })

            if !names(state, in: Syntax(region)) {
                var seen: Set<String> = []
                let reads = references.map(\.name)
                    .filter { environment.contains($0) && seen.insert($0).inserted }
                if !reads.isEmpty { return reads }
            }
            pending += references.filter { !$0.spelling.hasPrefix("$") }
                .flatMap { $0.members.filter { $0.kind != .storedProperty } }
        }
        return nil
    }

    /// The type member declaration that holds `node` : `body` , or a property or method that
    /// builds part of the view
    private static func enclosingMember(of node: some SyntaxProtocol) -> DeclSyntax? {
        var current = node.parent

        while let syntax = current {
            if syntax.is(VariableDeclSyntax.self) || syntax.is(FunctionDeclSyntax.self) {
                guard syntax.parent?.is(MemberBlockItemSyntax.self) == true else { return nil }
                return syntax.as(DeclSyntax.self)
            }
            if syntax.is(MemberBlockSyntax.self) { return nil }
            current = syntax.parent
        }
        return nil
    }

    /// The number of sibling statements, at every builder level between the field and `body` ,
    /// whose source does not name `state`
    private static func unrelatedSiblingCount(of node: some SyntaxProtocol, state: String) -> Int {
        var count = 0
        var current = Syntax(node)

        while let parent = current.parent, !parent.is(VariableDeclSyntax.self),
              !parent.is(FunctionDeclSyntax.self) {
            if let list = parent.as(CodeBlockItemListSyntax.self) {
                for item in list where item.id != current.id
                    && (item.item.is(ExprSyntax.self) || item.item.is(ExpressionStmtSyntax.self))
                    && !names(state, in: item) {
                    count += 1
                }
            }
            current = parent
        }
        return count
    }

    private static func names(_ state: String, in item: some SyntaxProtocol) -> Bool {
        item.tokens(viewMode: .sourceAccurate).contains {
            $0.text == state || $0.text == "$\(state)" || $0.text == "_\(state)"
        }
    }
}

fileprivate extension Finding.Message {
    static func keystrokeState(_ state: String) -> Finding.Message {
        "The field writes '\(state)' on every keystroke"
    }

    static func unrelatedEnvironmentValue(_ value: String, _ state: String) -> Finding.Message {
        "'\(value)' comes from the environment and feeds work that does not use '\(state)'"
    }

    static func sharedEnvironmentWork(_ control: String, _ state: String, _ value: String)
        -> Finding.Message
    {
        "'\(control)' writes '\(state)' on every keystroke, and this view also reads the environment value '\(value)' for work that does not use it. Move the field and its '@State' into their own 'View'"
    }

    static func sharedTextInput(_ control: String, _ state: String, _ count: Int)
        -> Finding.Message
    {
        "'\(control)' writes '\(state)' on every keystroke, and this 'body' also builds \(count) views that do not read it. Move the field and its '@State' into their own 'View'"
    }
}
