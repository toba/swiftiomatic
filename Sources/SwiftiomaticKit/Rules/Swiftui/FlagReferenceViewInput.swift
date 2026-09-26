import SwiftSyntax

/// Flag a view input whose type is an `@Observable` class declared in the same file.
///
/// SwiftUI compares a class input by reference. The parent passes the same reference on each of
/// its updates, so the comparison does not tell SwiftUI whether the values the view reads changed.
/// Observation then tracks every property the view reads through the reference, which ties the view
/// to the model's whole lifetime. Pass the values the view reads, or read the model from the
/// environment, so that the view's inputs describe what it shows.
///
/// A property the view owns, such as `@State` or `@Environment` , is not an input. The rule is
/// syntax-only, so a class declared in another file is unknown to it, and a type that names a
/// generic parameter of the view is never matched.
///
/// Lint: A stored input of a view type has the type of a same-file `@Observable` class.
final class FlagReferenceViewInput: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard context.viewEntry(forMember: node) != nil else { return .skipChildren }
        let generics = node.enclosingGenericParameterNames
        let types = context.typeMembers(around: node).types

        for input in node.viewInputs {
            guard let typeName = input.type.simpleTypeName, !generics.contains(typeName),
                  let entry = types[typeName], entry.kind == .class, entry.isObservable
            else { continue }
            diagnose(.referenceInput(input.name, typeName), on: node)
        }
        return .skipChildren
    }
}

fileprivate extension Finding.Message {
    static func referenceInput(_ name: String, _ type: String) -> Finding.Message {
        """
        '\(name)' stores the '@Observable' class '\(type)' as an input. SwiftUI compares the \
        reference, not the values the view reads. Pass the values the view reads, or read the \
        model from the environment
        """
    }
}
