import SwiftSyntax

/// Flag a `@Bindable` property that nothing projects with `$` .
///
/// `@Bindable` exists to make bindings to the properties of an `@Observable` model, as in
/// `$model.name` . A view that only reads the model, or only writes to it through the reference,
/// gets the same observation from a plain property. The wrapper then adds a dynamic property to the
/// view and tells the reader that the view edits the model through bindings, which it does not.
///
/// The rule searches the type and its extensions in the same file for a member, and the rest of the
/// enclosing block for a local declaration such as `@Bindable var model = model` . An extension in
/// another file that projects the property is not visible to the rule.
///
/// Lint: A `@Bindable` property or local variable whose `$name` projection does not occur in its
/// scope.
final class NoUnprojectedBindable: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let attribute = node.attributes.attribute(named: "Bindable") else {
            return .visitChildren
        }
        let names = node.bindings.compactMap {
            $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        }
        guard !names.isEmpty else { return .visitChildren }

        let regions: [Syntax]

        if node.parent?.is(MemberBlockItemSyntax.self) == true,
           let typeName = TypeMemberIndex.enclosingTypeName(of: node)
        {
            regions = TypeMemberIndex.declarationRegions(ofMember: node, typeName: typeName)
                .map { Syntax($0) }
        } else if let item = node.parent?.as(CodeBlockItemSyntax.self),
           let list = item.parent?.as(CodeBlockItemListSyntax.self)
        {
            regions = list.filter { $0.position >= item.endPosition }.map { Syntax($0) }
        } else {
            return .visitChildren
        }

        for name in names where !Self.projects(name, in: regions) {
            diagnose(.unprojected(name), on: attribute)
        }
        return .visitChildren
    }

    private static func projects(_ name: String, in regions: [Syntax]) -> Bool {
        let projection = "$\(name)"
        return regions.contains { region in
            region.tokens(viewMode: .sourceAccurate).contains { $0.text == projection }
        }
    }
}

fileprivate extension Finding.Message {
    static func unprojected(_ name: String) -> Finding.Message {
        "'@Bindable' on '\(name)' makes no binding, because nothing reads '$\(name)'. Remove '@Bindable' and store the model as a plain property"
    }
}
