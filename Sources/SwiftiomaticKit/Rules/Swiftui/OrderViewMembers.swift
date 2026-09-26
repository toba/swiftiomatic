import SwiftSyntax

/// Flag a member of a `View` type that is not in the standard member order.
///
/// A fixed order makes each view easy to scan. The inputs and the state come first. The `body`
/// comes after them, and the helpers come last. The order is:
///
/// 1. `@Environment` , `@FocusState` and `@FocusedValue` properties
/// 2. `let` stored properties
/// 3. `@State` and other stored properties
/// 4. computed properties that do not build a view
/// 5. `init`
/// 6. `body`
/// 7. other view builders: members that return `some View` or carry `@ViewBuilder`
/// 8. other functions
///
/// The rule ignores `static` members, nested types, type aliases, subscripts and members inside
/// `#if` blocks. It reports only the first member out of order in each member block.
///
/// Lint: A member of a `View` or `ViewModifier` type comes after a member of a later category.
final class OrderViewMembers: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    /// The member categories, in the order they must appear
    private enum Category: Int, Comparable {
        case environment, letProperty, storedProperty, computedProperty, initializer, body
        case viewBuilder, function

        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

        var label: String {
            switch self {
                case .environment: "environment property"
                case .letProperty: "'let' property"
                case .storedProperty: "stored property"
                case .computedProperty: "computed property"
                case .initializer: "initializer"
                case .body: "body"
                case .viewBuilder: "view builder"
                case .function: "function"
            }
        }
    }

    /// A member with its category, its name and the token the finding points at
    private struct Entry {
        let category: Category
        let name: String
        let anchor: TokenSyntax
    }

    /// Wrappers whose value comes from SwiftUI's environment or focus system
    private static let environmentWrappers: Set<String> = [
        "Environment", "FocusState", "FocusedValue",
    ]

    /// Return types that build a view tree
    private static let viewTypes: Set<String> = [
        "some View", "some SwiftUI.View", "any View", "any SwiftUI.View", "AnyView",
        "SwiftUI.AnyView",
    ]

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock)
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock)
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock)
        return .visitChildren
    }

    private func check(_ memberBlock: MemberBlockSyntax) {
        guard let first = memberBlock.members.first,
              context.viewEntry(forMember: first.decl) != nil else { return }
        let entries = memberBlock.members.compactMap { Self.entry(for: $0.decl) }

        for (index, entry) in entries.enumerated() {
            guard let earlier = entries[..<index].first(where: { $0.category > entry.category })
            else { continue }
            let note = Finding.Note(
                message: .moveAbove(earlier.name),
                location: Finding.Location(earlier.anchor.startLocation(
                    converter: context.sourceLocationConverter)),
                role: .member
            )
            diagnose(
                .outOfOrder(entry.name, entry.category.label, earlier.name, earlier.category.label),
                on: entry.anchor,
                notes: [note]
            )
            return
        }
    }

    /// The entry for a member, or `nil` for a member the order does not cover
    private static func entry(for decl: DeclSyntax) -> Entry? {
        if let initializer = decl.as(InitializerDeclSyntax.self) {
            return Entry(category: .initializer, name: "init", anchor: initializer.initKeyword)
        }

        if let function = decl.as(FunctionDeclSyntax.self) {
            guard !isStatic(function.modifiers) else { return nil }
            return Entry(
                category: category(of: function),
                name: function.name.text,
                anchor: function.funcKeyword
            )
        }
        guard let variable = decl.as(VariableDeclSyntax.self),
              !isStatic(variable.modifiers),
              let binding = variable.bindings.first,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        else { return nil }
        return Entry(
            category: category(of: variable, binding: binding, name: name),
            name: name,
            anchor: variable.bindingSpecifier
        )
    }

    private static func category(of function: FunctionDeclSyntax) -> Category {
        let labels = function.signature.parameterClause.parameters.map(\.firstName.text)
        if function.name.text == "body", labels == ["content"] { return .body }

        return function.attributes.hasResultBuilder
            || buildsView(function.signature.returnClause?.type)
            ? .viewBuilder
            : .function
    }

    private static func category(
        of variable: VariableDeclSyntax,
        binding: PatternBindingSyntax,
        name: String
    ) -> Category {
        if isComputed(binding) {
            if name == "body" { return .body }

            return variable.attributes.hasResultBuilder
                || buildsView(binding.typeAnnotation?.type)
                ? .viewBuilder
                : .computedProperty
        }
        if let wrapper = variable.attributes.firstAttributeName,
           environmentWrappers.contains(wrapper) { return .environment }

        if variable.bindingSpecifier.tokenKind == .keyword(.let), variable.attributes.isEmpty {
            return .letProperty
        }
        return .storedProperty
    }

    /// Whether `type` is an opaque, existential or erased view type
    private static func buildsView(_ type: TypeSyntax?) -> Bool {
        type.map { viewTypes.contains($0.trimmedDescription) } ?? false
    }

    /// Whether the binding has a getter, rather than no accessors or only observers
    private static func isComputed(_ binding: PatternBindingSyntax) -> Bool {
        switch binding.accessorBlock?.accessors {
            case nil: false
            case .getter: true
            case let .accessors(list):
                list.contains {
                    ![.keyword(.willSet), .keyword(.didSet)].contains(
                        $0.accessorSpecifier.tokenKind)
                }
        }
    }

    private static func isStatic(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        }
    }
}

fileprivate extension Finding.Message {
    static func outOfOrder(
        _ name: String,
        _ category: String,
        _ other: String,
        _ otherCategory: String
    ) -> Finding.Message {
        "'\(name)' (\(category)) must come before '\(other)' (\(otherCategory))"
    }

    static func moveAbove(_ name: String) -> Finding.Message { "move it above '\(name)'" }
}
