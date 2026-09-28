import SwiftSyntax

/// Flag a view `body` that nests three or more structural levels inside each other.
///
/// Deep nesting is a sign that one body holds more than one responsibility. Review the nested
/// regions. When a region has its own responsibility or its own dependencies, move it into a
/// focused `View` type, such as `struct HabitatSection: View { let habitatID: Habitat.ID }`. Give
/// the child only the values and the environment or observable dependencies that its `body` reads.
///
/// A focused child makes its responsibility and its inputs clear at its initializer. It also gives
/// SwiftUI an update boundary. SwiftUI evaluates the whole `body` of a view as one unit, and a deep
/// body evaluates every level when any value it reads changes. SwiftUI skips the `body` of a child
/// `View` type when its inputs do not change. A helper that returns `some View` does not make this
/// boundary.
///
/// Keep cohesive composition together. When the levels only arrange one piece of interface and read
/// the same values, the depth alone is not a reason to extract. Do not extract every stack or
/// modifier chain.
///
/// A container counts as a level when it sits inside the content of another level. A `.background`
/// or `.overlay` layer also counts as a level, one deeper than the view it decorates, when its
/// content holds a container, or when it fills a shape, as in
/// `.background(.quaternary, in: .capsule)` . A shape layer composes a shape view with its own
/// style. A leaf layer such as `.background(.red)` adds no level. Levels that sit side by side do
/// not add up: two containers in sibling modifiers, or two layers in one modifier chain, each count
/// only once.
///
/// The rule reports once per body, on the `body` declaration. A note marks the innermost level of
/// the deepest path, because that level is the one to extract. When several paths reach the same
/// depth, the last one counts.
///
/// Lint: The `body` of a `View`, or `body(content:)` of a `ViewModifier`, nests three or more
/// structural levels.
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
        "GeometryReader", "ViewThatFits", "ControlGroup", "DisclosureGroup", "OutlineGroup",
        "Table",
    ]

    /// The modifiers that stack a layer on the view they decorate
    private static let layers: Set<String> = ["background", "overlay"]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard context.viewEntry(forMember: node) != nil else { return .skipChildren }

        for binding in node.bindings {
            guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                  name.text == "body",
                  let accessors = binding.accessorBlock else { continue }
            check(accessors, reportingOn: name)
        }
        return .skipChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let labels = node.signature.parameterClause.parameters.map(\.firstName.text)

        if node.name.text == "body",
           labels == ["content"],
           let body = node.body,
           context.viewEntry(forMember: node) != nil { check(body, reportingOn: node.name) }
        return .skipChildren
    }

    private func check(_ body: some SyntaxProtocol, reportingOn name: TokenSyntax) {
        let finder = DepthFinder(viewMode: .sourceAccurate)
        finder.walk(body)
        guard finder.deepest.count >= Self.threshold, let innermost = finder.deepest.last
        else { return }
        let path = finder.deepest.map(\.name).joined(separator: " > ")
        let note = Finding.Note(
            message: .deepestLevel(innermost.name),
            location: Finding.Location(innermost.anchor.startLocation(
                converter: context.sourceLocationConverter))
        )
        diagnose(.deepComposition(path: path, count: finder.deepest.count), on: name, notes: [note])
    }

    private final class DepthFinder: SyntaxVisitor {
        /// One level of the path. `anchor` is where the note points: the call of a container, or
        /// the modifier name of a layer.
        typealias Level = (name: String, call: FunctionCallExprSyntax, anchor: Syntax)

        var stack: [Level] = []
        var deepest: [Level] = []

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if let layer = Self.layerModifier(of: node) {
                // The decorated view stays at the current depth. Only the layer content sits one
                // level deeper.
                walk(node.calledExpression)
                push((layer.text, node, Syntax(layer)))
                walk(node.arguments)
                if let closure = node.trailingClosure { walk(closure) }
                walk(node.additionalTrailingClosures)
                stack.removeLast()
                return .skipChildren
            }
            guard let name = Self.containerName(of: node) else { return .visitChildren }
            push((name, node, Syntax(node)))
            return .visitChildren
        }

        private func push(_ level: Level) {
            stack.append(level)
            // the last of equally deep paths wins, so the note sits on the level read last
            if stack.count >= deepest.count { deepest = stack }
        }

        /// The modifier name in `view.background(...)` or `view.overlay(...)` , when the layer
        /// fills a shape or its content holds a container
        private static func layerModifier(of call: FunctionCallExprSyntax) -> TokenSyntax? {
            guard let name = call.modifierName,
                  FlagDeepViewComposition.layers.contains(name),
                  let member = call.calledExpression.as(MemberAccessExprSyntax.self),
                  member.base != nil,
                  fillsShape(call) || holdsContainer(call) else { return nil }
            return member.declName.baseName
        }

        /// Whether `call` is the shape form of a layer, `background(_:in:fillStyle:)` or
        /// `overlay(_:in:fillStyle:)`
        private static func fillsShape(_ call: FunctionCallExprSyntax) -> Bool {
            call.arguments.contains { $0.label?.hasText("in") == true }
        }

        /// Whether the arguments or trailing closures of `call` hold a container call
        private static func holdsContainer(_ call: FunctionCallExprSyntax) -> Bool {
            let finder = ContainerFinder(viewMode: .sourceAccurate)
            finder.walk(call.arguments)
            if let closure = call.trailingClosure { finder.walk(closure) }
            finder.walk(call.additionalTrailingClosures)
            return finder.found
        }

        /// Finds the first container call in the code it walks
        private final class ContainerFinder: SyntaxVisitor {
            var found = false

            override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
                if found || DepthFinder.containerName(of: node) != nil {
                    found = true
                    return .skipChildren
                }
                return .visitChildren
            }
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
        'body' nests \(count) structural levels (\(path)). Extract an inner level into a 'View' \
        type so SwiftUI can skip it
        """
    }

    static func deepestLevel(_ name: String) -> Finding.Message {
        "the deepest level, '\(name)', starts here"
    }
}
