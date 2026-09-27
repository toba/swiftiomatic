import SwiftSyntax

/// Flag an `.onChange(of:)` or a `.task(id:)` whose key is a whole collection that the view
/// stores.
///
/// SwiftUI compares the old key with the new key on each update of the view. A key that is an
/// array, a set, a dictionary or a query result compares every element, so the cost grows with the
/// data. A small key costs almost nothing to compare. Examples are a revision counter, the count,
/// or the IDs and the fields that the work reads. The small key must change each time the work must
/// run, or the work runs on stale data.
///
/// When the work derives state from the collection, it can also move into the code that changes
/// the collection. Then no change key is necessary.
///
/// The rule reports the key and the declaration of the collection. It reports a key that is a bare
/// name or `self.name` of a stored property of the view. The property counts as a collection when
/// its type is an array, dictionary or set type, or a query result type such as `FetchedResults`
/// , or when its wrapper is a query wrapper such as `@Query` or `@FetchAll` . A key that reads a
/// member, such as `items.count` , is not reported.
///
/// Lint: An `.onChange(of:)` or a `.task(id:)` observes a stored collection of the view as a
/// whole.
final class NoWholeCollectionChangeKey: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    /// The declarations that the rule already reported in this file
    private var reportedSources: Set<SyntaxIdentifier> = []

    /// The modifier names and the argument labels that carry a change key
    private static let keyLabels: [String: String] = ["onChange": "of", "task": "id"]

    /// The property wrappers whose value is the result of a query
    private static let queryWrappers: Set<String> = [
        "Query", "FetchAll", "FetchRequest", "SectionedFetchRequest",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let modifier = node.modifierName,
              let label = Self.keyLabels[modifier],
              let key = node.arguments.first(where: { $0.label?.text == label })?.expression,
              let name = key.selfMemberReference?.baseName.text,
              let entry = context.typeMembers(around: node).enclosingType(of: node),
              entry.isView,
              !TypeMemberIndex.references(in: key, of: entry).isEmpty,
              let member = entry.members[name]?.first(where: {
                  $0.kind == .storedProperty && !$0.isStatic
              }),
              let declaration = member.declaration.as(VariableDeclSyntax.self),
              let binding = Self.collectionBinding(named: name, in: declaration)
        else { return .visitChildren }

        if reportedSources.insert(declaration.id).inserted {
            diagnose(.wholeCollectionSource(name), on: binding.pattern)
        }
        diagnose(
            .wholeCollectionKey(modifier: modifier, label: label, key: key.trimmedDescription),
            on: key)
        return .visitChildren
    }

    /// The binding named `name` in `declaration` when its value is a collection
    private static func collectionBinding(
        named name: String,
        in declaration: VariableDeclSyntax
    ) -> PatternBindingSyntax? {
        guard let binding = declaration.bindings.first(where: {
            $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name
        }) else { return nil }

        if let wrapper = declaration.attributes.firstAttributeName,
           queryWrappers.contains(wrapper) { return binding }
        if let type = binding.typeAnnotation?.type {
            return type.isCollectionType ? binding : nil
        }

        guard let value = binding.initializer?.value else { return nil }
        let constructed = value.as(FunctionCallExprSyntax.self)?.calledExpression ?? value
        let isCollection = constructed.is(ArrayExprSyntax.self)
            || constructed.is(DictionaryExprSyntax.self)
            || constructed.as(GenericSpecializationExprSyntax.self)
                .flatMap { $0.expression.as(DeclReferenceExprSyntax.self)?.baseName.text }
                .map(TypeSyntax.collectionTypeNames.contains) == true
        return isCollection ? binding : nil
    }
}

fileprivate extension Finding.Message {
    static func wholeCollectionKey(modifier: String, label: String, key: String) -> Finding.Message
    {
        """
        '.\(modifier)(\(label): \(key))' compares the whole collection '\(key)' on each update. \
        Observe a small key that changes whenever the work must run, such as a revision or a \
        count and IDs
        """
    }

    static func wholeCollectionSource(_ name: String) -> Finding.Message {
        """
        '\(name)' is a collection that a change key compares whole. Give it a small key, or \
        update the dependent state where '\(name)' changes
        """
    }
}
