import SwiftSyntax

/// Flag three SwiftUI layout shapes that lay out wrongly or waste space.
///
/// A `GeometryReader` takes all the space its container proposes. A scroll view or a lazy stack
/// proposes no fixed size on its scroll axis, so a `GeometryReader` directly in its content
/// collapses or fills the axis. `.onGeometryChange` measures a view without this problem.
///
/// A `NavigationStack` or `NavigationSplitView` inside the content of another one makes a second
/// navigation stack. The two stacks fight over the navigation bar and the path. A presented sheet
/// is a separate context, so the rule does not report a stack inside a modal modifier. The rule
/// also reports a same-file view whose `body` holds its own navigation container, when that view
/// appears inside the content of another navigation container.
///
/// Two scroll views on the same axis in one `VStack` or `HStack` split the space of the stack
/// between them, unless a `.frame` bounds each one. The result is seldom the layout the author
/// wants.
///
/// Lint: A `GeometryReader` directly inside a `ScrollView` , a `List` or a lazy stack, a nested
/// navigation container, or two unbounded same-axis scroll views in one stack.
final class FlagSwiftUILayoutHazard: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    /// Containers that give their content no fixed size on the scroll axis
    private static let scrollingContainers: Set<String> = [
        "ScrollView", "List", "LazyVStack", "LazyHStack", "LazyVGrid", "LazyHGrid",
    ]

    /// Containers that pass their parent's proposal through to their content
    private static let transparentContainers: Set<String> = ["ForEach", "Group", "Section"]

    private static let navigationContainers: Set<String> = [
        "NavigationStack", "NavigationSplitView",
    ]

    /// Modifiers whose content stays inside the current navigation stack
    private static let navigationModifiers: Set<String> = ["navigationDestination"]

    /// The same-file view types whose `body` holds a navigation container
    private var navigationOwners: (root: SyntaxIdentifier, names: Set<String>)?

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let name = Self.containerName(of: node) else { return .visitChildren }

        if name == "GeometryReader" {
            checkGeometryReader(node)
        } else if Self.navigationContainers.contains(name) {
            checkNavigation(node, message: { .nestedNavigation(inner: name, outer: $0) })
        } else if name == "VStack" || name == "HStack" {
            checkSiblingScrollViews(in: node, stack: name)
        } else if navigationOwners(in: node).contains(name) {
            checkNavigation(node, message: { .nestedNavigationView(view: name, outer: $0) })
        }
        return .visitChildren
    }

    // MARK: - GeometryReader

    private func checkGeometryReader(_ node: FunctionCallExprSyntax) {
        for holder in Self.contentHolders(of: node) {
            guard let name = holder.name else { return }
            if Self.transparentContainers.contains(name) { continue }
            guard Self.scrollingContainers.contains(name) else { return }

            diagnose(
                .geometryReaderInScroll(container: name), on: node,
                notes: [ownerNote(name, at: holder.call)])
            return
        }
    }

    // MARK: - Nested navigation

    private func checkNavigation(
        _ node: FunctionCallExprSyntax,
        message: (String) -> Finding.Message
    ) {
        guard let (outer, name) = Self.enclosingNavigation(of: node) else { return }
        diagnose(message(name), on: node, notes: [ownerNote(name, at: outer)])
    }

    /// The navigation container whose content holds `node` without a modal boundary between them
    private static func enclosingNavigation(
        of node: FunctionCallExprSyntax
    ) -> (FunctionCallExprSyntax, String)? {
        for holder in contentHolders(of: node) {
            if holder.isModifier {
                guard let name = holder.name, navigationModifiers.contains(name) else { return nil }
                continue
            }
            if let name = holder.name, navigationContainers.contains(name) {
                return (holder.call, name)
            }
        }
        return nil
    }

    private func navigationOwners(in node: some SyntaxProtocol) -> Set<String> {
        let root = node.root
        if let navigationOwners, navigationOwners.root == root.id { return navigationOwners.names }
        let finder = NavigationFinder(viewMode: .sourceAccurate)
        finder.walk(root)

        let owners = Set(finder.calls.compactMap { call -> String? in
            guard Self.enclosingNavigation(of: call) == nil,
                  Self.contentHolders(of: call).allSatisfy({
                      !$0.isModifier || Self.navigationModifiers.contains($0.name ?? "")
                  }),
                  Self.isInBody(call) else { return nil }
            return TypeMemberIndex.enclosingTypeName(of: call)
        })
        navigationOwners = (root.id, owners)
        return owners
    }

    /// Whether `node` sits in the `body` property of a type
    private static func isInBody(_ node: some SyntaxProtocol) -> Bool {
        var current = node.parent

        while let cur = current {
            if let variable = cur.as(VariableDeclSyntax.self),
               variable.parent?.is(MemberBlockItemSyntax.self) == true
            {
                return variable.bindings.contains {
                    $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body"
                }
            }
            current = cur.parent
        }
        return false
    }

    private final class NavigationFinder: SyntaxVisitor {
        var calls: [FunctionCallExprSyntax] = []

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if let name = FlagSwiftUILayoutHazard.containerName(of: node),
               FlagSwiftUILayoutHazard.navigationContainers.contains(name) { calls.append(node) }
            return .visitChildren
        }
    }

    // MARK: - Sibling scroll views

    private enum Axis { case horizontal, vertical }

    private func checkSiblingScrollViews(in stack: FunctionCallExprSyntax, stack name: String) {
        guard let content = stack.trailingClosure
            ?? stack.arguments.first(where: { $0.label?.text == "content" })?
            .expression.as(ClosureExprSyntax.self)
        else { return }

        var unbounded: [Axis: [(ExprSyntax, String)]] = [:]

        for statement in content.statements {
            guard case let .expr(expression) = statement.item,
                  let (scrollName, axis) = Self.unboundedScrollView(expression) else { continue }
            unbounded[axis, default: []].append((expression, scrollName))
        }

        for axis in [Axis.vertical, .horizontal] {
            guard let group = unbounded[axis], group.count >= 2 else { continue }

            for (expression, scrollName) in group {
                diagnose(
                    .siblingScrollViews(name: scrollName, stack: name),
                    on: expression,
                    notes: [ownerNote(name, at: stack)]
                )
            }
        }
    }

    /// The name and axis of a scroll view that no `.frame` bounds on its scroll axis
    private static func unboundedScrollView(_ expression: ExprSyntax) -> (String, Axis)? {
        var modifiers: [FunctionCallExprSyntax] = []
        var current = expression

        while let call = current.as(FunctionCallExprSyntax.self),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              let base = member.base
        {
            modifiers.append(call)
            current = base
        }

        guard let base = current.as(FunctionCallExprSyntax.self),
              let name = containerName(of: base),
              name == "List" || name == "ScrollView" else { return nil }

        let axis: Axis

        if name == "List" {
            axis = .vertical
        } else {
            let axes = base.arguments.first { $0.label == nil || $0.label?.text == "axes" }?
                .expression.trimmedDescription ?? ""
            let horizontal = axes.contains("horizontal")
            if horizontal, axes.contains("vertical") { return nil }
            axis = horizontal ? .horizontal : .vertical
        }

        let bounds: Set<String> = axis == .vertical
            ? ["height", "maxHeight"]
            : ["width", "maxWidth"]
        let bounded = modifiers.contains { modifier in
            switch modifier.modifierName {
                case "containerRelativeFrame": true
                case "frame":
                    modifier.arguments.contains {
                        bounds.contains($0.label?.text ?? "")
                            && !$0.expression.trimmedDescription.hasSuffix("infinity")
                    }
                default: false
            }
        }
        return bounded ? nil : (name, axis)
    }

    // MARK: - Shared

    private func ownerNote(_ name: String, at node: FunctionCallExprSyntax) -> Finding.Note {
        Finding.Note(
            message: .enclosingContainer(name),
            location: Finding.Location(node.startLocation(
                converter: context.sourceLocationConverter)),
            role: .owner
        )
    }

    /// A call whose closure argument holds a node
    private struct ContentHolder {
        let call: FunctionCallExprSyntax
        /// The container or modifier name, or `nil` for any other callee
        let name: String?
        let isModifier: Bool
    }

    /// The calls whose closure arguments hold `node` , from the innermost out
    ///
    /// The walk stops at the member declaration that holds `node` . A call that `node` reaches
    /// through the called expression, such as a modifier applied to `node` , is not a holder.
    private static func contentHolders(of node: some SyntaxProtocol) -> [ContentHolder] {
        var holders: [ContentHolder] = []
        var child = Syntax(node)
        var closure: ClosureExprSyntax?
        var current = node.parent

        while let cur = current {
            if cur.is(MemberBlockItemSyntax.self) || cur.is(FunctionDeclSyntax.self) { break }

            if let found = cur.as(ClosureExprSyntax.self) {
                closure = found
            } else if let call = cur.as(FunctionCallExprSyntax.self),
               child.id != call.calledExpression.id,
               let closure,
               passes(closure, to: call)
            {
                let modifier = call.modifierName.flatMap {
                    qualifiedSwiftUIName(call.calledExpression) == nil ? $0 : nil
                }
                holders.append(ContentHolder(
                    call: call, name: modifier ?? containerName(of: call),
                    isModifier: modifier != nil))
            }
            if cur.is(FunctionCallExprSyntax.self) { closure = nil }
            child = cur
            current = cur.parent
        }
        return holders
    }

    private static func passes(
        _ closure: ClosureExprSyntax,
        to call: FunctionCallExprSyntax
    ) -> Bool {
        call.trailingClosure?.id == closure.id
            || call.additionalTrailingClosures.contains { $0.closure.id == closure.id }
            || call.arguments.contains { $0.expression.id == closure.id }
    }

    /// The simple name of a call to a type, such as `VStack` for `VStack { }`
    fileprivate static func containerName(of call: FunctionCallExprSyntax) -> String? {
        var callee = call.calledExpression

        if let specialized = callee.as(GenericSpecializationExprSyntax.self) {
            callee = specialized.expression
        }
        return callee.as(DeclReferenceExprSyntax.self)?.baseName.text
            ?? qualifiedSwiftUIName(callee)
    }

    /// The name in `SwiftUI.VStack`
    private static func qualifiedSwiftUIName(_ callee: ExprSyntax) -> String? {
        guard let member = callee.as(MemberAccessExprSyntax.self),
              member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "SwiftUI"
        else { return nil }
        return member.declName.baseName.text
    }
}

fileprivate extension Finding.Message {
    static func geometryReaderInScroll(container: String) -> Finding.Message {
        """
        'GeometryReader' directly inside '\(container)' gets no fixed size proposal and collapses \
        or fills the axis. Measure with '.onGeometryChange' or read the geometry outside the \
        scrolling container
        """
    }

    static func nestedNavigation(inner: String, outer: String) -> Finding.Message {
        """
        '\(inner)' inside the content of another '\(outer)' makes a second navigation stack. Keep \
        one navigation container and push with 'NavigationLink' or '.navigationDestination'
        """
    }

    static func nestedNavigationView(view: String, outer: String) -> Finding.Message {
        """
        '\(view)' declares its own navigation container and appears inside the content of \
        '\(outer)'. Remove the inner container, or present the view modally
        """
    }

    static func siblingScrollViews(name: String, stack: String) -> Finding.Message {
        """
        '\(name)' shares '\(stack)' with another unbounded scroll view on the same axis, so they \
        split the space. Bound each one with '.frame' or merge them into one scroll view
        """
    }

    static func enclosingContainer(_ name: String) -> Finding.Message {
        "the enclosing '\(name)' starts here"
    }
}
