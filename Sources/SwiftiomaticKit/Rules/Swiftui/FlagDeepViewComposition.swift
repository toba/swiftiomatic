import SwiftSyntax

/// Flag a view `body` that nests three or more structural containers inside each other.
///
/// SwiftUI evaluates the whole `body` of a view as one unit. A body that nests stacks, scroll
/// views, lists and `ForEach` several levels deep rebuilds every level when any value it reads
/// changes. An inner level extracted into its own `View` type gets its own inputs, and SwiftUI
/// skips it when they do not change.
///
/// A container counts toward the depth only when it sits inside the content of another container.
/// Containers in sibling modifiers such as `.overlay { }` and `.background { }` do not add up.
///
/// Lint: The `body` of a `View` , or `body(content:)` of a `ViewModifier` , nests three or more
/// structural containers.
final class FlagDeepViewComposition: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    /// The nesting depth at which the rule reports
    private static let threshold = 3

    /// The SwiftUI views whose only job is to arrange other views
    private static let containers: Set<String> = [
        "VStack", "HStack", "ZStack", "LazyVStack", "LazyHStack", "LazyVGrid", "LazyHGrid", "Grid",
        "GridRow", "ScrollView", "ScrollViewReader", "List", "Form", "Section", "Group", "GroupBox",
        "ForEach", "NavigationStack", "NavigationSplitView", "NavigationView", "TabView",
        "GeometryReader", "ViewThatFits", "ControlGroup", "DisclosureGroup", "OutlineGroup", "Table",
    ]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard context.viewEntry(forMember: node) != nil else { return .skipChildren }

        for binding in node.bindings {
            guard binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body",
                  let accessors = binding.accessorBlock else { continue }
            check(accessors)
        }
        return .skipChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let labels = node.signature.parameterClause.parameters.map(\.firstName.text)

        if node.name.text == "body", labels == ["content"], let body = node.body,
           context.viewEntry(forMember: node) != nil { check(body) }
        return .skipChildren
    }

    private func check(_ body: some SyntaxProtocol) {
        let finder = DepthFinder(viewMode: .sourceAccurate)
        finder.walk(body)
        guard finder.deepest.count >= Self.threshold, let outermost = finder.deepest.first else {
            return
        }
        let path = finder.deepest.map(\.name).joined(separator: " > ")
        diagnose(.deepComposition(path: path, count: finder.deepest.count), on: outermost.call)
    }

    private final class DepthFinder: SyntaxVisitor {
        typealias Level = (name: String, call: FunctionCallExprSyntax)

        var stack: [Level] = []
        var deepest: [Level] = []

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            guard let name = Self.containerName(of: node) else { return .visitChildren }
            stack.append((name, node))
            if stack.count > deepest.count { deepest = stack }
            return .visitChildren
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if stack.last?.call.id == node.id { stack.removeLast() }
        }

        private static func containerName(of call: FunctionCallExprSyntax) -> String? {
            var callee = call.calledExpression
            if let specialized = callee.as(GenericSpecializationExprSyntax.self) {
                callee = specialized.expression
            }
            let name = callee.as(DeclReferenceExprSyntax.self)?.baseName.text
                ?? qualifiedSwiftUIName(callee)
            return name.flatMap { FlagDeepViewComposition.containers.contains($0) ? $0 : nil }
        }

        /// The name in `SwiftUI.VStack`
        private static func qualifiedSwiftUIName(_ callee: ExprSyntax) -> String? {
            guard let member = callee.as(MemberAccessExprSyntax.self),
                  member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "SwiftUI"
            else { return nil }
            return member.declName.baseName.text
        }
    }
}

fileprivate extension Finding.Message {
    static func deepComposition(path: String, count: Int) -> Finding.Message {
        """
        'body' nests \(count) structural containers (\(path)). Extract an inner level into a \
        'View' type so SwiftUI can skip it
        """
    }
}
