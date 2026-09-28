import SwiftSyntax

/// Flag a `Binding(get:set:)` that a view builds in its body, in a helper, or in a closure.
///
/// A binding built from closures is a new value on each update. SwiftUI cannot compare two closure
/// bindings, so each child view that receives one is always different from its last value and
/// updates each time the parent does. Each evaluation also allocates the two closures again. The
/// closures capture the current values of the view, and the code that they hold is hidden from the
/// owner of the state.
///
/// Project the binding with `$` from the owner of the value. When the binding needs logic, give the
/// owner a labeled subscript or a computed property with a setter, and project through it:
///
/// - On a model: `$model[isSaved: id]` or `$model[isPresenting: \.signInError]`.
/// - On the type of a `@State` or `@Binding` value: `$grantedIDs[contains: id]`.
/// - On an environment model: declare `@Bindable var model = model` in `body` first.
///
/// Keep the closure binding only as a workaround for a framework bug that needs the binding to
/// report a new value although the underlying value did not change. Suppress the finding there and
/// name the bug.
///
/// The rule reports each `Binding(get:set:)` in a member of a type that conforms to `View` or
/// `ViewModifier` , in all its spellings: `Binding(get:set:)`, `Binding(get:) { ... }` and
/// `Binding { ... } set: { ... }`.
///
/// A binding that a model or another type builds in a helper reaches the view the same way. The
/// rule reports the read of such a helper in a view, such as `model.binding(for: id)` , when the
/// helper of that name builds a binding from closures. The match is by member name, because the
/// tree does not tell the type of `model` . The helper can be in another file of the project.
///
/// Lint: A member of a view type builds a `Binding` from get and set closures, or reads a helper of
/// another type that builds one.
final class NoBindingConstructionInView: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .shouldNot }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.constructedTypeName == "Binding",
              Self.hasGetAndSetClosures(node),
              context.typeMembers(around: node).enclosingType(of: node)?.isView == true
        else { return .visitChildren }
        diagnose(.bindingInView, on: node)
        return .visitChildren
    }

    /// Whether each helper declaration builds a binding from closures, by declaration
    private var buildsBinding: [SyntaxIdentifier: Bool] = [:]

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        guard let base = node.base,
              base.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind != .keyword(.self)
        else { return .visitChildren }
        let name = node.declName.baseName.text
        let index = context.typeMembers(around: node)

        // The same-file types need no project index, and the index lists the others by name
        var owners = index.types.local.compactMap { typeName, entry in
            entry.members[name] == nil ? nil : typeName
        }
        for owner in index.typesWithBindingMember(named: name) where !owners.contains(owner) {
            owners.append(owner)
        }
        guard !owners.isEmpty, index.enclosingType(of: node)?.isView == true else {
            return .visitChildren
        }

        for owner in owners.sorted() {
            guard let entry = index.types[owner], !entry.isView else { continue }

            for member in entry.members(named: name) ?? [] where helperBuildsBinding(member) {
                diagnose(.helperBuildsBinding("\(owner).\(name)"), on: node.declName)
                return .visitChildren
            }
        }
        return .visitChildren
    }

    /// Whether the code of `member` builds a `Binding` from get and set closures
    private func helperBuildsBinding(_ member: TypeMemberIndex.Member) -> Bool {
        if let known = buildsBinding[member.declaration.id] { return known }
        let finder = BindingFinder(viewMode: .sourceAccurate)
        finder.walk(member.declaration)
        buildsBinding[member.declaration.id] = finder.found
        return finder.found
    }

    private final class BindingFinder: SyntaxVisitor {
        var found = false

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if node.constructedTypeName == "Binding",
               NoBindingConstructionInView.hasGetAndSetClosures(node) { found = true }
            return found ? .skipChildren : .visitChildren
        }
    }

    /// Whether the call passes a getter and a setter, as labeled arguments or as trailing closures.
    ///
    /// The unlabeled trailing closure is the getter when no `get:` argument precedes it, and the
    /// setter when one does.
    fileprivate static func hasGetAndSetClosures(_ node: FunctionCallExprSyntax) -> Bool {
        let labels = node.arguments.compactMap { $0.label?.text }
        let hasGetArgument = labels.contains("get")
        let hasGet = hasGetArgument || node.trailingClosure != nil
        let hasSet = labels.contains("set")
            || node.additionalTrailingClosures.contains { $0.label.text == "set" }
            || (hasGetArgument && node.trailingClosure != nil)
        return hasGet && hasSet
    }
}

fileprivate extension Finding.Message {
    static func helperBuildsBinding(_ helper: String) -> Finding.Message {
        """
        '\(helper)' builds a 'Binding(get:set:)', which allocates two closures on each update of \
        this view and gives a binding that SwiftUI cannot compare. Project the binding with '$' \
        through a labeled subscript or a property on the owner of the value
        """
    }

    static let bindingInView: Finding.Message = """
        'Binding(get:set:)' built in a view allocates two closures on each update and gives a \
        binding that SwiftUI cannot compare. Project the binding with '$' through a labeled \
        subscript or a property on the owner of the value, such as '$model[isSaved: id]'
        """
}
