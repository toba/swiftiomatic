import SwiftSyntax

/// Flag a view input whose type is a large struct declared in the same file.
///
/// SwiftUI compares a value input as a whole. When a view stores a model with many properties and
/// reads only a few of them, a change to any other property still makes the input look changed, and
/// SwiftUI evaluates the view's `body` again. Pass only the properties the view reads.
///
/// A struct counts as large when it and its same-file extensions declare at least five stored
/// instance properties. A `View` type is not a model, and neither is a type that names a generic
/// parameter of the view. A property the view owns, such as `@State` , is not an input.
///
/// Lint: A stored input of a view type has the type of a same-file struct with five or more stored
/// instance properties.
final class FlagWholeValueModelViewInput: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    /// The number of stored instance properties at which a struct counts as a large model
    private static let largeModelPropertyCount = 5

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard context.viewEntry(forMember: node) != nil else { return .skipChildren }
        let generics = node.enclosingGenericParameterNames
        let types = context.typeMembers(around: node).types

        for input in node.viewInputs {
            guard let typeName = input.type.simpleTypeName, !generics.contains(typeName),
                  let entry = types[typeName], entry.kind == .struct, !entry.isView
            else { continue }
            let count = entry.storedInstancePropertyCount
            guard count >= Self.largeModelPropertyCount else { continue }
            diagnose(.wholeValueInput(input.name, typeName, count), on: node)
        }
        return .skipChildren
    }
}

fileprivate extension Finding.Message {
    static func wholeValueInput(_ name: String, _ type: String, _ count: Int) -> Finding.Message {
        """
        '\(name)' stores the whole value model '\(type)' (\(count) stored properties) as an \
        input. A change to any property updates this view. Pass only the properties the view reads
        """
    }
}
