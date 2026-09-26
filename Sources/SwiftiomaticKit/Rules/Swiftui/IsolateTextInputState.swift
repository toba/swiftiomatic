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
            diagnose(.sharedTextInput(callee, state, unrelated), on: node)
        } else if let value = Self.unrelatedEnvironmentRead(in: entry, state: state) {
            diagnose(.sharedEnvironmentWork(callee, state, value), on: node)
        }
        return .visitChildren
    }

    /// The first `@Environment` property that `body` reads, directly or through the same-type
    /// members it reaches, in a member whose source does not name `state`
    ///
    /// Closures that run later, such as a `Button` action or an `.onSubmit` body, are not
    /// followed, because they do not run during `body` .
    private static func unrelatedEnvironmentRead(
        in entry: TypeMemberIndex.TypeEntry,
        state: String
    ) -> String? {
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
                in: region, of: entry, skipping: runsLater)

            if !names(state, in: Syntax(region)),
               let read = references.first(where: { environment.contains($0.name) }) {
                return read.name
            }
            pending += references.filter { !$0.spelling.hasPrefix("$") }
                .flatMap { $0.members.filter { $0.kind != .storedProperty } }
        }
        return nil
    }

    /// Whether a closure runs in response to an event rather than during `body`
    private static func runsLater(_ closure: ClosureExprSyntax) -> Bool {
        guard let call = closure.owningCall, let name = call.calleeBaseName else { return false }
        if let label = closure.parent?.as(LabeledExprSyntax.self)?.label?.text,
           ["action", "perform", "set"].contains(label) { return true }
        if name.hasSuffix("Button"),
           !call.arguments.contains(where: { $0.label?.text == "action" }) { return true }
        return name.hasPrefix("on") || name == "task" || name == "Task" || name == "refreshable"
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
