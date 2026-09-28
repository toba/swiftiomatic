import SwiftSyntax

/// Flag a stored property of function type in a `View` or `ViewModifier` type.
///
/// SwiftUI compares the stored inputs of a view to decide whether to evaluate its `body` again. It
/// cannot compare two closures, so a view that stores one looks changed on every update of its
/// parent. The cost grows with how often the parent updates. A `Binding(get:set:)` input has the
/// same problem, because it holds two closures.
///
/// Pass what the child needs in a form SwiftUI can compare:
///
/// - The value that the closure computes.
/// - A focused binding for a value that the child writes, such as `$model[isFavorite: id]`.
/// - An `@Observable` model that owns the action, so the child calls a method on it.
///
/// A view whose parent seldom updates can keep a closure input. Suppress the finding there.
///
/// The rule resolves a function typealias that the same file declares, such as
/// `typealias SelectNode = (Node.ID) -> Void`, and a generic or optional use of one.
///
/// Builder content is not an input of this kind. A property with a result builder attribute such as
/// `@ViewBuilder` or `@ContentBuilder` is exempt, and so is a closure whose result type is a
/// generic parameter of the view, such as `() -> Label` .
///
/// The rule also reports the places where the view uses such an input. It reports each reference to
/// the input in a method or a computed property of the view. It also reports each method or
/// computed property, such as `body` , that reaches the input directly or through another member of
/// the view. An initializer that stores the input is not a use.
///
/// Lint: A stored property of a view type has a function type and no result builder attribute. A
/// member of the view refers to that property, or calls a member that refers to it.
final class NoClosureInputInView: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .shouldNot }

    /// The closure inputs that each member reaches, cached per view type name
    private var reachCache: [String: [String: Set<String>]] = [:]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.bindings.contains(where: { $0.accessorBlock != nil }) {
            reportUses(
                in: node,
                named: node.bindings.first?.pattern
                    .as(IdentifierPatternSyntax.self)?.identifier.text)
            return .skipChildren
        }
        guard !node.attributes.hasResultBuilder,
              !node.modifiers.contains(anyOf: [.static, .class]),
              context.viewEntry(forMember: node) != nil else { return .skipChildren }
        let generics = node.enclosingGenericParameterNames

        for binding in node.bindings where binding.accessorBlock == nil {
            guard let type = binding.typeAnnotation?.type,
                  let function = closureType(type, in: node),
                  !Self.returnsGenericParameter(function, generics),
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { continue }
            diagnose(.closureInput(name), on: node)
        }
        return .skipChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        reportUses(in: node, named: node.name.text)
        return .skipChildren
    }

    /// Reports the member `node` when it reaches a closure input, and each reference in it to one
    private func reportUses(
        in node: some WithModifiersSyntax & DeclSyntaxProtocol,
        named name: String?
    ) {
        guard let name,
              !node.modifiers.contains(anyOf: [.static, .class]),
              let typeName = TypeMemberIndex.enclosingTypeName(of: node),
              let entry = context.viewEntry(forMember: node) else { return }
        let reach = reachability(of: entry, named: typeName, at: node)
        let inputs = closureInputs(of: entry, in: node)
        guard let reached = reach[name], let first = reached.min() else { return }
        diagnose(.closureScope(name, first), on: node)

        for reference in TypeMemberIndex.references(in: node, of: entry)
            where inputs.contains(reference.name)
        {
            diagnose(.closureUse(reference.name), on: reference.node.selfQualifiedUse)
        }
    }

    /// The closure inputs that each method or computed property of `entry` reaches
    ///
    /// A member reaches an input when it refers to the input, or when it refers to another member
    /// that reaches it.
    private func reachability(
        of entry: TypeMemberIndex.TypeEntry,
        named typeName: String,
        at node: some SyntaxProtocol
    ) -> [String: Set<String>] {
        if let cached = reachCache[typeName] { return cached }
        let inputs = closureInputs(of: entry, in: node)
        var references: [String: Set<String>] = [:]

        for (name, overloads) in entry.members {
            for member in overloads where member.kind != .storedProperty && !member.isStatic {
                guard let body = member.body else { continue }
                references[name, default: []].formUnion(
                    TypeMemberIndex.references(in: body, of: entry).map(\.name)
                )
            }
        }
        var reach = references.mapValues { $0.intersection(inputs) }
        var changed = !inputs.isEmpty

        while changed {
            changed = false

            for (name, referenced) in references {
                var current = reach[name] ?? []
                let before = current.count

                for other in referenced where other != name {
                    current.formUnion(reach[other] ?? [])
                }

                if current.count != before {
                    reach[name] = current
                    changed = true
                }
            }
        }
        let result = reach.filter { !$0.value.isEmpty }
        reachCache[typeName] = result
        return result
    }

    /// The names of the stored closure inputs of `entry`
    private func closureInputs(
        of entry: TypeMemberIndex.TypeEntry,
        in node: some SyntaxProtocol
    ) -> Set<String> {
        var names: Set<String> = []

        for (name, overloads) in entry.members {
            for member in overloads where member.kind == .storedProperty && !member.isStatic {
                guard let variable = member.declaration.as(VariableDeclSyntax.self),
                    !variable.attributes.hasResultBuilder else { continue }
                let generics = variable.enclosingGenericParameterNames

                for binding in variable.bindings where binding.accessorBlock == nil {
                    guard binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
                        .text
                        == name,
                          let type = binding.typeAnnotation?.type,
                          let function = closureType(type, in: node),
                          !Self.returnsGenericParameter(function, generics) else { continue }
                    names.insert(name)
                }
            }
        }
        return names
    }

    /// The function type of `type`, directly or through a same-file typealias
    ///
    /// Optional and attribute layers around the alias name are removed, and an alias of an alias
    /// resolves up to a fixed depth.
    private func closureType(
        _ type: TypeSyntax,
        in node: some SyntaxProtocol,
        depth: Int = 0
    ) -> FunctionTypeSyntax? {
        if let function = type.functionType { return function }
        guard depth < 8 else { return nil }
        var base = type.unwrappingOptional

        if let attributed = base.as(AttributedTypeSyntax.self) {
            base = attributed.baseType.unwrappingOptional
        }
        guard let name = base.as(IdentifierTypeSyntax.self)?.name.text,
              let target = context.typeMembers(around: node).typeAliases[name] else { return nil }
        return closureType(target, in: node, depth: depth + 1)
    }

    private static func returnsGenericParameter(
        _ function: FunctionTypeSyntax,
        _ generics: Set<String>
    ) -> Bool {
        guard let name = function.returnClause.type.simpleTypeName else { return false }
        return generics.contains(name)
    }
}

fileprivate extension Finding.Message {
    static func closureInput(_ name: String) -> Finding.Message {
        """
        '\(name)' stores a closure input. SwiftUI cannot compare a closure, so the view evaluates \
        'body' on each parent update. Pass the value it reads, a focused binding such as \
        '$model[isFavorite: id]', or an @Observable model
        """
    }

    static func closureUse(_ name: String) -> Finding.Message {
        """
        This code uses the stored closure input '\(name)'. SwiftUI cannot compare a closure, so \
        the view cannot skip 'body'. Pass a value, a focused binding or an @Observable model \
        instead
        """
    }

    static func closureScope(_ member: String, _ name: String) -> Finding.Message {
        """
        '\(member)' depends on the stored closure input '\(name)'. SwiftUI cannot compare a \
        closure, so each parent update evaluates this view again
        """
    }
}
