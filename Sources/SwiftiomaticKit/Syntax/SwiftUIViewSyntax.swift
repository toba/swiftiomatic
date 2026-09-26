import SwiftSyntax

// Syntax helpers that the SwiftUI view rules share. The rules stay syntax-only, so each helper
// decides from the shape of the source and the same-file `TypeMemberIndex` .

extension Context {
    /// The index entry of the view type whose member block directly holds `node`
    ///
    /// Returns `nil` when `node` is not a direct member, or when the type does not conform to `View`
    /// or `ViewModifier` in this file.
    func viewEntry(forMember node: some SyntaxProtocol) -> TypeMemberIndex.TypeEntry? {
        guard node.parent?.is(MemberBlockItemSyntax.self) == true,
              let name = TypeMemberIndex.enclosingTypeName(of: node),
              let entry = typeMembers(around: node).types[name],
              entry.isView else { return nil }
        return entry
    }
}

extension TypeMemberIndex.TypeEntry {
    /// The number of stored instance properties the type and its same-file extensions declare
    var storedInstancePropertyCount: Int {
        members.values.reduce(0) { count, overloads in
            count + overloads.count(where: { $0.kind == .storedProperty && !$0.isStatic })
        }
    }

    /// Whether the member named `name` is a stored property that carries the `@State` wrapper
    func isStateProperty(_ name: String) -> Bool {
        members[name]?.contains {
            $0.kind == .storedProperty
                && $0.declaration.as(VariableDeclSyntax.self)?.attributes
                    .attribute(named: "State") != nil
        } == true
    }

    /// Whether the member named `name` is a stored instance property
    func isStoredInstanceProperty(_ name: String) -> Bool {
        members[name]?.contains { $0.kind == .storedProperty && !$0.isStatic } == true
    }
}

extension AttributeListSyntax {
    /// Whether the list holds a result builder attribute such as `@ViewBuilder` or
    /// `@ContentBuilder`
    ///
    /// The match is by name shape, because the tree carries no type information. Any attribute
    /// whose simple name ends in `Builder` counts.
    var hasResultBuilder: Bool {
        contains {
            guard case let .attribute(attribute) = $0 else { return false }
            let name = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
                ?? attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
            return name?.hasSuffix("Builder") == true
        }
    }

    /// The simple name of the first attribute, which for a stored property is its wrapper
    var firstAttributeName: String? {
        for element in self {
            guard case let .attribute(attribute) = element else { continue }
            if let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
                return identifier.name.text
            }
            return attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
        }
        return nil
    }
}

extension SyntaxProtocol {
    /// The generic parameter names of the type declaration whose member block holds this node
    var enclosingGenericParameterNames: Set<String> {
        var current = parent

        while let cur = current {
            if cur.is(MemberBlockSyntax.self), let owner = cur.parent {
                let clause = owner.as(StructDeclSyntax.self)?.genericParameterClause
                    ?? owner.as(ClassDeclSyntax.self)?.genericParameterClause
                    ?? owner.as(EnumDeclSyntax.self)?.genericParameterClause
                return Set(clause?.parameters.map(\.name.text) ?? [])
            }
            current = cur.parent
        }
        return []
    }
}

extension TypeSyntax {
    /// The type with `Optional` and implicitly unwrapped `Optional` layers removed
    var unwrappingOptional: TypeSyntax {
        if let optional = self.as(OptionalTypeSyntax.self) {
            return optional.wrappedType.unwrappingOptional
        }
        if let unwrapped = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return unwrapped.wrappedType.unwrappingOptional
        }
        return self
    }

    /// The closure type under optional, attribute and single-element parenthesis layers, if any
    ///
    /// `(@escaping () -> Void)?` gives `() -> Void` .
    var functionType: FunctionTypeSyntax? {
        if let function = self.as(FunctionTypeSyntax.self) { return function }
        if let attributed = self.as(AttributedTypeSyntax.self) { return attributed.baseType.functionType }
        if let optional = self.as(OptionalTypeSyntax.self) { return optional.wrappedType.functionType }
        if let unwrapped = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return unwrapped.wrappedType.functionType
        }
        if let tuple = self.as(TupleTypeSyntax.self), tuple.elements.count == 1,
           let element = tuple.elements.first, element.firstName == nil {
            return element.type.functionType
        }
        return nil
    }

    /// The simple name of an identifier type, after optional layers, or `nil` for any other type
    var simpleTypeName: String? {
        unwrappingOptional.as(IdentifierTypeSyntax.self)?.name.text
    }
}

extension ExprSyntax {
    /// Whether the folded operator is `=` or a compound assignment such as `+=`
    var isAssignmentOperator: Bool {
        if self.is(AssignmentExprSyntax.self) { return true }
        return isCompoundAssignmentOperator
    }

    /// Whether the folded operator is a compound assignment such as `+=` or `<<=`
    var isCompoundAssignmentOperator: Bool {
        guard let binary = self.as(BinaryOperatorExprSyntax.self) else { return false }
        let text = binary.operator.text
        return text.count > 1 && text.hasSuffix("=")
            && !["==", "!=", "<=", ">=", "===", "!=="].contains(text)
    }

    /// The root of an assignment target
    ///
    /// Member accesses, subscripts, optional chaining and force unwraps are removed until the
    /// root is a bare name or `self.name` . For `self.stats.words[0]` the root is `self.stats` .
    var assignmentRoot: ExprSyntax {
        var current = self

        while true {
            if let member = current.as(MemberAccessExprSyntax.self), let base = member.base {
                if let reference = base.as(DeclReferenceExprSyntax.self),
                   reference.baseName.tokenKind == .keyword(.self) { return current }
                current = base
            } else if let subscriptCall = current.as(SubscriptCallExprSyntax.self) {
                current = subscriptCall.calledExpression
            } else if let chaining = current.as(OptionalChainingExprSyntax.self) {
                current = chaining.expression
            } else if let unwrap = current.as(ForceUnwrapExprSyntax.self) {
                current = unwrap.expression
            } else {
                return current
            }
        }
    }

    /// The member name an assignment root names, for a bare name or `self.name`
    var assignmentRootName: String? {
        let root = assignmentRoot
        if let reference = root.as(DeclReferenceExprSyntax.self) { return reference.baseName.text }
        return root.as(MemberAccessExprSyntax.self)?.declName.baseName.text
    }

    /// The reference that a bare `name` or `self.name` spells, or `nil` for any other shape
    var selfMemberReference: DeclReferenceExprSyntax? {
        if let bare = self.as(DeclReferenceExprSyntax.self) { return bare }
        guard let access = self.as(MemberAccessExprSyntax.self),
              access.base?.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self)
        else { return nil }
        return access.declName
    }
}

extension InfixOperatorExprSyntax {
    /// The assignments inside `node` , in source order
    ///
    /// - Parameters:
    ///   - compound: Whether a compound assignment such as `+=` also counts. When it is `false` ,
    ///     only a plain `=` counts.
    ///   - enteringClosures: Whether the search enters closures inside `node` . When `node` is a
    ///     closure itself, the search always enters it.
    static func assignments(
        in node: some SyntaxProtocol,
        compound: Bool,
        enteringClosures: Bool
    ) -> [InfixOperatorExprSyntax] {
        let finder = AssignmentFinder(
            root: node.id, compound: compound, enteringClosures: enteringClosures)
        finder.walk(node)
        return finder.assignments
    }

    private final class AssignmentFinder: SyntaxVisitor {
        let root: SyntaxIdentifier
        let compound: Bool
        let enteringClosures: Bool
        var assignments: [InfixOperatorExprSyntax] = []

        init(root: SyntaxIdentifier, compound: Bool, enteringClosures: Bool) {
            self.root = root
            self.compound = compound
            self.enteringClosures = enteringClosures
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
            let matches = compound
                ? node.operator.isAssignmentOperator
                : node.operator.is(AssignmentExprSyntax.self)
            if matches { assignments.append(node) }
            return .visitChildren
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            enteringClosures || node.id == root ? .visitChildren : .skipChildren
        }
    }
}

extension DeclReferenceExprSyntax {
    /// The `self.name` access when this reference is its member, or this reference otherwise
    ///
    /// A rule that inspects how a member is used starts from this node, so `self.name` and `name`
    /// read the same.
    var selfQualifiedUse: Syntax {
        if let access = parent?.as(MemberAccessExprSyntax.self), access.declName.id == id {
            return Syntax(access)
        }
        return Syntax(self)
    }
}

extension FunctionCallExprSyntax {
    /// The name of the modifier this call applies, such as `onAppear` for `.onAppear { }`
    var modifierName: String? {
        calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
    }

    /// The closure a modifier runs
    ///
    /// The closure arrives as the trailing closure, as a labeled argument such as `perform:` , or
    /// as the last unlabeled argument.
    func actionClosure(labels: Set<String> = ["perform", "action"]) -> ClosureExprSyntax? {
        if let trailing = trailingClosure { return trailing }

        if let labeled = arguments.first(where: { labels.contains($0.label?.text ?? "") }),
           let closure = labeled.expression.as(ClosureExprSyntax.self) { return closure }
        return arguments.last.flatMap {
            $0.label == nil ? $0.expression.as(ClosureExprSyntax.self) : nil
        }
    }
}

extension VariableDeclSyntax {
    /// Property wrappers whose value the view owns or reads from SwiftUI, not from its parent
    static let ownedWrappers: Set<String> = [
        "State", "StateObject", "Environment", "EnvironmentObject", "FocusState", "FocusedValue",
        "FocusedObject", "AppStorage", "SceneStorage", "Namespace", "Query", "GestureState",
        "ScaledMetric", "AccessibilityFocusState",
    ]

    /// Property wrappers that project state a parent or a focused view owns
    ///
    /// A write through one of these changes the state of its owner.
    static let bindingWrappers: Set<String> = ["Binding", "FocusedBinding"]

    /// Property wrappers whose storage SwiftUI installs after the initializer returns
    ///
    /// The set is `ownedWrappers` plus `bindingWrappers` .
    static let dynamicPropertyWrappers: Set<String> =
        Self.ownedWrappers.union(Self.bindingWrappers)

    /// The owned wrappers whose storage SwiftUI installs for the view itself
    ///
    /// A value that a parent passes through the memberwise initializer only seeds this storage
    /// once. The set is a subset of `ownedWrappers` .
    static let installedStorageWrappers: Set<String> = [
        "State", "StateObject", "AppStorage", "SceneStorage", "FocusState", "GestureState",
    ]

    /// The owned wrappers that keep state for one view identity across updates
    ///
    /// When the identity of the view moves to a different element, this state moves with it. The
    /// set is a subset of `ownedWrappers` .
    static let identityStateWrappers: Set<String> = [
        "State", "FocusState", "StateObject", "AccessibilityFocusState",
    ]

    /// The stored instance properties of a view declaration that a parent passes in
    ///
    /// A property with a wrapper the view owns, such as `@State` or `@Environment` , is not an
    /// input. Neither is a `static` property, a computed property, or one without a type
    /// annotation.
    var viewInputs: [(name: String, type: TypeSyntax)] {
        guard !modifiers.contains(where: {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        }) else { return [] }

        if let wrapper = attributes.firstAttributeName, Self.ownedWrappers.contains(wrapper) {
            return []
        }
        return bindings.compactMap { binding in
            guard binding.accessorBlock == nil,
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let type = binding.typeAnnotation?.type else { return nil }
            return (name, type)
        }
    }
}

extension ExprSyntax {
    /// The expression that a chain of modifier calls starts from
    ///
    /// For `Row(tag: tag).padding().onTapGesture { }` the root is the call `Row(tag: tag)` . A call
    /// whose callee is a member access with a base counts as a modifier, so the walk steps to that
    /// base. An expression that is not such a call is its own root.
    var modifierChainRoot: ExprSyntax {
        var current = self

        while let call = current.as(FunctionCallExprSyntax.self),
              let base = call.calledExpression.as(MemberAccessExprSyntax.self)?.base {
            current = base
        }
        return current
    }
}

extension FunctionCallExprSyntax {
    /// The name of the type that this call constructs, or `nil` when the callee does not name an
    /// uppercase type
    ///
    /// The name is the last component of the callee after `.init` and generic arguments are
    /// removed. `Binding(get:set:)` , `Binding<Int>(get:set:)` , `Binding.init(get:set:)` and
    /// `SwiftUI.Binding(get:set:)` all give `Binding` .
    var constructedTypeName: String? {
        var callee = calledExpression

        if let member = callee.as(MemberAccessExprSyntax.self),
           member.declName.baseName.tokenKind == .keyword(.`init`),
           let base = member.base { callee = base }

        if let generic = callee.as(GenericSpecializationExprSyntax.self) {
            callee = generic.expression
        }
        let name: String? =
            if let reference = callee.as(DeclReferenceExprSyntax.self) {
                reference.baseName.text
            } else if let member = callee.as(MemberAccessExprSyntax.self), member.base != nil {
                member.declName.baseName.text
            } else {
                nil
            }
        guard let name, name.first?.isUppercase == true else { return nil }
        return name
    }
}

extension ClosureExprSyntax {
    /// Calls whose closures run in response to an event rather than during `body`
    ///
    /// A modifier whose name is `on` followed by an uppercase letter, such as `onTapGesture` ,
    /// also counts. `runsAfterBody` checks that shape separately.
    private static let deferredCalls: Set<String> = [
        "Task", "immediate", "detached", "immediateDetached", "task", "refreshable",
        "dropDestination", "draggable", "withAnimation",
    ]

    /// Argument labels that pass a closure to run later
    private static let deferredLabels: Set<String> = ["action", "perform", "set"]

    /// Whether this closure runs after the `body` evaluation that builds it
    ///
    /// A closure runs later when it is the action of an event modifier such as `.onTapGesture` or
    /// `.task` , the operation of a `Task` , or an argument labeled `action` , `perform` or `set` .
    /// A call whose name ends in `Button` runs its trailing closure later, unless the call also
    /// has an `action:` argument. `Button(action:label:)` takes its label as the trailing
    /// closure or as `label:` , and the label runs during `body` .
    var runsAfterBody: Bool {
        guard let call = owningCall else { return false }
        let label = parent?.as(LabeledExprSyntax.self)?.label?.text
        if let label, Self.deferredLabels.contains(label) { return true }

        if let task = call.taskCall,
           task.factory.map({ FunctionCallExprSyntax.taskFactories.contains($0) }) ?? true {
            return true
        }
        guard let name = call.calleeBaseName else { return false }

        if name.hasSuffix("Button") {
            guard label == nil else { return false }
            return !call.arguments.contains { $0.label?.text == "action" }
        }
        if name.hasPrefix("on"), name.dropFirst(2).first?.isUppercase == true { return true }
        return Self.deferredCalls.contains(name)
    }
}

/// The SwiftUI views, shapes and controls that ship with the framework
///
/// A rule uses the list to tell a custom `View` , which stores its inputs and can be skipped, from a
/// built-in view that renders or lays out what it receives.
enum SwiftUIBuiltInViews {
    /// Whether `name` can name a custom `View` : it starts with an uppercase letter and is not a
    /// built-in view
    static func isCustomViewName(_ name: String) -> Bool {
        name.first?.isUppercase == true && !names.contains(name)
    }

    static let names: Set<String> = [
        "AsyncImage", "Button", "Canvas", "Capsule", "Chart", "Circle", "Color", "ColorPicker",
        "ContentUnavailableView", "ControlGroup", "DatePicker", "DisclosureGroup", "Divider",
        "EmptyView", "ForEach", "Form", "Gauge", "GeometryReader", "Grid", "GridRow", "Group",
        "GroupBox", "HStack", "Image", "Label", "LabeledContent", "LazyHGrid", "LazyHStack",
        "LazyVGrid", "LazyVStack", "Link", "List", "Map", "Menu", "NavigationLink",
        "NavigationSplitView", "NavigationStack", "OutlineGroup", "Picker", "ProgressView",
        "Rectangle", "RoundedRectangle", "ScrollView", "Section", "SecureField", "ShareLink",
        "Slider", "Spacer", "Stepper", "Tab", "TabView", "Table", "Text", "TextEditor", "TextField",
        "TimelineView", "Toggle", "VStack", "VideoPlayer", "ViewThatFits", "ZStack",
    ]
}
