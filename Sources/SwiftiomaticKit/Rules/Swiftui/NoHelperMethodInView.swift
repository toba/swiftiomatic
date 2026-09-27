import SwiftSyntax

/// Flag a method on a view type, other than `body`, that `body` calls or passes as a function
/// value.
///
/// A helper method on a view runs as part of `body`. SwiftUI cannot compare its inputs or skip it,
/// so each evaluation of `body` repeats the work. Keep `body` as the one function of the view. Move
/// the work into a model that owns the result, or into a child view whose inputs SwiftUI compares.
///
/// The rule reads the view type and its same-file extensions. It counts a bare `name` or a
/// `self.name` reference inside `body`, both as a call and as a function value such as
/// `build: render`. A `static` method and a method that returns a view are not reported here.
/// `NoViewFactoryMembers` covers a method that returns a view.
///
/// Lint: A view method that `body` references raises a warning.
final class NoHelperMethodInView: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        guard name != "body",
              !node.modifiers.contains(anyOf: [.static, .class]),
              !Self.returnsView(node),
              let entry = context.viewEntry(forMember: node),
              let bodies = entry.members["body"]?.compactMap(\.body),
              bodies.contains(where: { Self.references(name, in: $0) })
        else { return .skipChildren }
        diagnose(.helperMethodInView(name), on: node.funcKeyword)
        return .skipChildren
    }

    /// Whether the function returns an opaque, erased or concrete view type.
    private static func returnsView(_ node: FunctionDeclSyntax) -> Bool {
        guard let type = node.signature.returnClause?.type else { return false }
        let text = type.trimmedDescription

        if text.hasPrefix("some ") || text.hasPrefix("any ") { return text.hasSuffix("View") }
        let simple = type.as(IdentifierTypeSyntax.self)?.name.text
            ?? type.as(MemberTypeSyntax.self)?.name.text
        return simple?.hasSuffix("View") == true
    }

    /// Whether `node` holds a bare `name` or `self.name` reference.
    private static func references(_ name: String, in node: Syntax) -> Bool {
        node.tokens(viewMode: .sourceAccurate).contains { token in
            guard token.text == name,
                  let reference = token.parent?.as(DeclReferenceExprSyntax.self)
            else { return false }

            // The outermost expression the name forms: `self.name` , or the bare reference
            let member = reference.parent?.as(MemberAccessExprSyntax.self)
            let outer = member.flatMap { $0.declName.id == reference.id ? ExprSyntax($0) : nil }
                ?? ExprSyntax(reference)
            return outer.selfMemberReference?.id == reference.id
        }
    }
}

fileprivate extension Finding.Message {
    static func helperMethodInView(_ name: String) -> Finding.Message {
        "'body' runs '\(name)' on each evaluation; move the work into a model or a child view that SwiftUI can compare"
    }
}
