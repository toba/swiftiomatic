import SwiftSyntax

/// Flag a stored property of function type in a `View` or `ViewModifier` type.
///
/// SwiftUI compares the stored inputs of a view to decide whether to evaluate its `body` again. It
/// cannot compare two closures, so a view that stores one looks changed on every update of its
/// parent. Store the value the closure computes, or keep the action at the call site.
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
                  let function = type.functionType,
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
        let reach = reachability(of: entry, named: typeName)
        let inputs = Self.closureInputs(of: entry)
        guard let reached = reach[name], let first = reached.min() else { return }
        diagnose(.closureScope(name, first), on: node)

        for reference in TypeMemberIndex.references(in: node, of: entry)
        where inputs.contains(reference.name) {
            diagnose(.closureUse(reference.name), on: reference.node.selfQualifiedUse)
        }
    }

    /// The closure inputs that each method or computed property of `entry` reaches
    ///
    /// A member reaches an input when it refers to the input, or when it refers to another member
    /// that reaches it.
    private func reachability(
        of entry: TypeMemberIndex.TypeEntry,
        named typeName: String
    ) -> [String: Set<String>] {
        if let cached = reachCache[typeName] { return cached }
        let inputs = Self.closureInputs(of: entry)
        var references: [String: Set<String>] = [:]

        for (name, overloads) in entry.members {
            for member in overloads where member.kind != .storedProperty && !member.isStatic {
                guard let body = member.body else { continue }
                references[name, default: []].formUnion(
                    TypeMemberIndex.references(in: body, of: entry).map(\.name))
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
    private static func closureInputs(of entry: TypeMemberIndex.TypeEntry) -> Set<String> {
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
                          let function = type.functionType,
                          !returnsGenericParameter(function, generics) else { continue }
                    names.insert(name)
                }
            }
        }
        return names
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
        '\(name)' stores a closure input. SwiftUI cannot compare a closure, so the view cannot \
        skip 'body'. Store the value, or keep the action at the call site
        """
    }

    static func closureUse(_ name: String) -> Finding.Message {
        """
        This code uses the stored closure input '\(name)'. SwiftUI cannot compare a closure, so \
        the view cannot skip 'body'. Pass a value or a binding instead
        """
    }

    static func closureScope(_ member: String, _ name: String) -> Finding.Message {
        """
        '\(member)' depends on the stored closure input '\(name)'. SwiftUI cannot compare a \
        closure, so each parent update evaluates this view again
        """
    }
}
