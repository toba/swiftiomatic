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
    private static let ownedWrappers: Set<String> = [
        "State", "StateObject", "Environment", "EnvironmentObject", "FocusState", "FocusedValue",
        "FocusedObject", "AppStorage", "SceneStorage", "Namespace", "Query", "GestureState",
        "ScaledMetric", "AccessibilityFocusState",
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
