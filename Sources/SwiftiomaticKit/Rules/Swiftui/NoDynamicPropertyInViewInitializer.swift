import SwiftSyntax

/// Flag an initializer that reads, calls a method on, or changes one of its own dynamic properties.
///
/// SwiftUI installs the storage of a dynamic property such as `@State` or `@Environment` after the
/// initializer returns. Inside the initializer, a read sees a default value, and a change such as
/// `citations.update(...)` on a `@State` model goes to a copy that SwiftUI then discards. Store the
/// inputs in the initializer, and do the work in `body` , in `task(id:)` , or in the parent.
///
/// The rule applies to any struct whose stored properties carry a dynamic property wrapper, so it
/// also covers a view that conforms to `View` through a protocol declared in another file. These
/// uses are not flagged:
///
/// - the storage setup `_name = State(initialValue: value)`
/// - an assignment `name = value` that initializes a wrapper with no default value, such as
///   `@State private var size: Double`
/// - a parameter or local that shadows the property name
///
/// Lint: An initializer uses a property that carries `@State` , `@Binding` , `@Environment` ,
/// `@FocusState` , `@AppStorage` or another dynamic property wrapper.
final class NoDynamicPropertyInViewInitializer: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    /// Wrappers whose storage SwiftUI installs after the initializer returns
    private static let dynamicWrappers: Set<String> = [
        "State", "Binding", "Environment", "EnvironmentObject", "StateObject", "FocusState",
        "AccessibilityFocusState", "FocusedValue", "FocusedBinding", "FocusedObject", "AppStorage",
        "SceneStorage", "GestureState", "Namespace", "ScaledMetric", "Query",
    ]

    /// Wrappers with a zero-argument initializer, so an assignment in `init` is always a change
    private static let defaultedWrappers: Set<String> = [
        "FocusState", "AccessibilityFocusState", "Namespace",
    ]

    /// A dynamic property of the enclosing type
    private struct DynamicProperty {
        let wrapper: String
        /// Whether `name = value` in the initializer initializes the wrapper rather than changing
        /// it
        let assignmentInitializes: Bool
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let body = node.body,
              node.parent?.is(MemberBlockItemSyntax.self) == true,
              let entry = context.typeMembers(around: node).enclosingType(of: node),
              entry.kind == .struct || entry.kind == nil else { return .skipChildren }
        let properties = Self.dynamicProperties(of: entry)
        guard !properties.isEmpty else { return .skipChildren }

        var shadowed = Set(
            node.signature.parameterClause.parameters.map { ($0.secondName ?? $0.firstName).text }
        )
        shadowed.formUnion(Self.localNames(in: body))

        for token in body.tokens(viewMode: .sourceAccurate) {
            guard let reference = token.parent?.as(DeclReferenceExprSyntax.self),
                  reference.baseName.id == token.id,
                  // `\.name` names a key path component, not the property
                  reference.parent?.is(KeyPathPropertyComponentSyntax.self) != true
            else { continue }
            let projected = token.text.hasPrefix("$")
            let name = projected ? String(token.text.dropFirst()) : token.text
            guard let property = properties[name] else { continue }

            let use = reference.selfQualifiedUse

            if let access = use.as(MemberAccessExprSyntax.self) {
                // `other.name` and `.name` name a member of something else
                guard access.base?.as(DeclReferenceExprSyntax.self)?.baseName
                    .tokenKind
                    == .keyword(.self)
                else { continue }
            } else if !projected, shadowed.contains(name) { continue }
            if !projected, property.assignmentInitializes, Self.isAssignmentTarget(use) { continue }

            diagnose(.dynamicPropertyInInitializer(name, property.wrapper), on: use)
        }
        return .skipChildren
    }

    /// The dynamic properties of `entry` , keyed by name
    private static func dynamicProperties(
        of entry: TypeMemberIndex.TypeEntry
    ) -> [String: DynamicProperty] {
        var result: [String: DynamicProperty] = [:]

        for (name, overloads) in entry.members {
            for member in overloads where member.kind == .storedProperty && !member.isStatic {
                guard let variable = member.declaration.as(VariableDeclSyntax.self),
                    let wrapper = variable.attributes.firstAttributeName,
                    dynamicWrappers.contains(wrapper) else { continue }
                let binding = variable.bindings.first {
                    $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name
                }
                let hasArguments = variable.attributes.contains {
                    $0.as(AttributeSyntax.self)?.arguments != nil
                }
                result[name] = DynamicProperty(
                    wrapper: wrapper,
                    assignmentInitializes: binding?.initializer == nil && !hasArguments
                        && !defaultedWrappers.contains(wrapper)
                )
            }
        }
        return result
    }

    /// The names that locals, closure parameters and optional bindings declare in `body`
    private static func localNames(in body: CodeBlockSyntax) -> Set<String> {
        var names = Set<String>()

        for token in body.tokens(viewMode: .sourceAccurate) {
            guard case .identifier = token.tokenKind, let parent = token.parent else { continue }

            if parent.is(IdentifierPatternSyntax.self)
                || parent.is(ClosureShorthandParameterSyntax.self)
                || parent.is(ClosureParameterSyntax.self) { names.insert(token.text) }
        }
        return names
    }

    /// Whether `use` is the whole target of a plain `=` assignment
    private static func isAssignmentTarget(_ use: Syntax) -> Bool {
        guard let infix = use.parent?.as(InfixOperatorExprSyntax.self) else { return false }
        return infix.leftOperand.id == use.id && infix.operator.is(AssignmentExprSyntax.self)
    }
}

fileprivate extension Finding.Message {
    static func dynamicPropertyInInitializer(_ name: String, _ wrapper: String) -> Finding.Message {
        "'\(name)' is a '@\(wrapper)' property. The initializer uses it before SwiftUI installs its storage, so it sees a default value and loses any change. Move the work to 'body', 'task(id:)' or the parent"
    }
}
