import SwiftSyntax

/// Flag the `.tabItem` view modifier.
///
/// The `Tab` type supersedes `.tabItem`. A `Tab` declares its label, its selection value and its
/// role in one place, and it supports the sidebar-adaptable `TabView` style, tab sections and
/// customization. `.tabItem` still works, but it gets none of these.
///
/// `.tabItem` has a meaning only in a `TabView`, so the rule does not look for the enclosing
/// `TabView`. That also covers a child view that another file puts in a `TabView`.
///
/// Lint: A modifier call `.tabItem { ... }` .
final class UseTabNotTabItem: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.base != nil,
              member.declName.baseName.text == "tabItem",
              Self.passesOnlyLabelClosure(node) else { return .visitChildren }
        diagnose(.useTab, on: member.declName)
        return .visitChildren
    }

    /// Whether `node` passes one closure, as a trailing closure or as one unlabeled argument
    private static func passesOnlyLabelClosure(_ node: FunctionCallExprSyntax) -> Bool {
        if node.trailingClosure != nil { return node.arguments.isEmpty }
        guard node.arguments.count == 1, let argument = node.arguments.first else { return false }
        return argument.label == nil && argument.expression.is(ClosureExprSyntax.self)
    }
}

fileprivate extension Finding.Message {
    static let useTab: Finding.Message =
        "consider 'Tab' in place of '.tabItem'. A 'Tab' carries its label, value and role in one declaration"
}
