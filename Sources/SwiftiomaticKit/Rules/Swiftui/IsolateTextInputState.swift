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
/// Lint: A `TextField` , `SecureField` or `TextEditor` in `body` binds `$name` of a same-type
/// `@State` , and two or more views beside it in `body` do not name `name` .
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
              let body = Self.enclosingBody(of: node),
              let entry = context.typeMembers(around: body).enclosingType(of: body),
              entry.isView else { return .visitChildren }
        let state = String(projected.dropFirst())
        guard entry.isStateProperty(state) else { return .visitChildren }

        let unrelated = Self.unrelatedSiblingCount(of: node, state: state)
        if unrelated >= Self.unrelatedViewCount {
            diagnose(.sharedTextInput(callee, state, unrelated), on: node)
        }
        return .visitChildren
    }

    /// The `body` property declaration that holds `node` , if any
    private static func enclosingBody(of node: some SyntaxProtocol) -> VariableDeclSyntax? {
        var current = node.parent

        while let syntax = current {
            if let variable = syntax.as(VariableDeclSyntax.self) {
                let name = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?
                    .identifier.text
                let isBody = name == "body"
                    && variable.parent?.is(MemberBlockItemSyntax.self) == true
                return isBody ? variable : nil
            }
            if syntax.is(FunctionDeclSyntax.self) || syntax.is(MemberBlockSyntax.self) { return nil }
            current = syntax.parent
        }
        return nil
    }

    /// The number of sibling statements, at every builder level between the field and `body` ,
    /// whose source does not name `state`
    private static func unrelatedSiblingCount(of node: some SyntaxProtocol, state: String) -> Int {
        var count = 0
        var current = Syntax(node)

        while let parent = current.parent, !parent.is(VariableDeclSyntax.self) {
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

    private static func names(_ state: String, in item: CodeBlockItemSyntax) -> Bool {
        item.tokens(viewMode: .sourceAccurate).contains {
            $0.text == state || $0.text == "$\(state)" || $0.text == "_\(state)"
        }
    }
}

fileprivate extension Finding.Message {
    static func sharedTextInput(_ control: String, _ state: String, _ count: Int)
        -> Finding.Message
    {
        "'\(control)' writes '\(state)' on every keystroke, and this 'body' also builds \(count) views that do not read it. Move the field and its '@State' into their own 'View'"
    }
}
