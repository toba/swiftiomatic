import SwiftSyntax

/// Flag `ForEach(_, id: \.self)`, which uses the whole element value as the identity of each row.
///
/// SwiftUI uses the `id` of each element to match rows across updates. With `\.self`, the identity
/// changes when any stored property of the element changes. SwiftUI then removes the row and
/// inserts a new one, so the row loses its state, its focus and its animation. SwiftUI also hashes
/// and compares each identifier on every update. The cost grows with the size of the value, for
/// example with the length of a string.
///
/// Give each element a small identifier that an edit cannot change:
///
/// ```swift
/// struct Note: Identifiable {
///     let id = UUID()
///     var text: String
/// }
///
/// ForEach(notes) { note in Text(note.text) }
/// ForEach($notes) { $note in TextField("Note", text: $note.text) }
/// ```
///
/// A `Codable` element needs `var id = UUID()`. The synthesized decoder does not decode a `let`
/// that has an initial value, so each decoded element gets a new identifier. Do not change `id`
/// after initialization.
///
/// Keep `id: \.self` when each element is a small, stable and unique identifier, for example a
/// short code, a tag, a dictionary key, an enum case or a database ID. Suppress the finding there.
/// The rule does not report `indices` or a range of `Int`, because `\.self` is the only possible id
/// for them.
///
/// Lint: A `ForEach` call has the argument `id: \.self`, and its data is not `indices` or an `Int`
/// range.
final class FlagForEachIDSelfInView: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
            ident.baseName.text == "ForEach" else { return .visitChildren }

        if let firstArg = node.arguments.first,
           firstArg.label == nil,
           isIntegerIndexedReceiver(firstArg.expression) { return .visitChildren }

        for arg in node.arguments where arg.label?.text == "id" {
            if isKeyPathSelf(arg.expression) { diagnose(.idSelfFragile, on: arg.expression) }
        }
        return .visitChildren
    }

    /// `<expr>.indices`, or a `Range`/`ClosedRange` literal (`a..<b`, `a...b`), or `Range(...)`.
    /// For these, `Int` is the element type and `\.self` is the only valid id.
    private func isIntegerIndexedReceiver(_ expr: ExprSyntax) -> Bool {
        if let member = expr.as(MemberAccessExprSyntax.self),
           member.declName.baseName.text == "indices" { return true }

        if let infix = expr.as(InfixOperatorExprSyntax.self),
           let op = infix.operator.as(BinaryOperatorExprSyntax.self)
        {
            let text = op.operator.text
            if text == "..<" || text == "..." { return true }
        }
        if let seq = expr.as(SequenceExprSyntax.self) {
            for element in seq.elements {
                if let op = element.as(BinaryOperatorExprSyntax.self) {
                    let text = op.operator.text
                    if text == "..<" || text == "..." { return true }
                }
            }
        }
        if let call = expr.as(FunctionCallExprSyntax.self),
           let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
           callee.baseName.text == "Range" { return true }
        return false
    }

    private func isKeyPathSelf(_ expr: ExprSyntax) -> Bool {
        guard let kp = expr.as(KeyPathExprSyntax.self),
              kp.components.count == 1,
              let only = kp.components.first else { return false }

        if let property = only.component.as(KeyPathPropertyComponentSyntax.self),
            property.declName.baseName.tokenKind == .keyword(.self) { return true }
        return false
    }
}

fileprivate extension Finding.Message {
    static let idSelfFragile: Finding.Message =
        "'id: \\.self' replaces the row on each edit, so make the element 'Identifiable' with 'let id = UUID()'"
}
