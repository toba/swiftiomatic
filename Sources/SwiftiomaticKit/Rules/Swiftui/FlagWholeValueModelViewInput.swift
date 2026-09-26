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
/// A type declared in another file has no property count the rule can see. The rule then reports
/// the input when the view reads at least three of its properties and never uses the value as a
/// whole: it does not pass it on, call a method on it, compare it or bind it. Standard library,
/// Foundation and SwiftUI types are exempt, and so is a name that ends in `View` .
///
/// Lint: A stored input of a view type has the type of a same-file struct with five or more stored
/// instance properties, or has a type from another file of which the view reads three or more
/// properties and nothing else.
final class FlagWholeValueModelViewInput: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    /// The number of stored instance properties at which a struct counts as a large model
    private static let largeModelPropertyCount = 5

    /// The number of distinct properties a view reads of an out-of-file type before it reports it
    private static let partialReadCount = 3

    /// Framework value types that a view reads by property as a matter of course
    private static let frameworkTypes: Set<String> = [
        "String", "Substring", "Int", "Double", "Float", "Bool", "Character", "Date", "URL", "UUID",
        "Data", "Decimal", "CGFloat", "CGPoint", "CGSize", "CGRect", "CGVector", "Color", "Font",
        "Image", "Text", "Angle", "Duration", "EdgeInsets", "UnitPoint", "DateComponents",
        "DateInterval", "TimeInterval", "Locale", "Calendar", "TimeZone", "AttributedString",
        "Binding", "Measurement", "PersonNameComponents", "ClosedRange", "Range", "Array",
        "Dictionary", "Set", "Optional", "Result",
    ]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard context.viewEntry(forMember: node) != nil else { return .skipChildren }
        let generics = node.enclosingGenericParameterNames
        let types = context.typeMembers(around: node).types

        for input in node.viewInputs {
            guard let typeName = input.type.simpleTypeName, !generics.contains(typeName)
            else { continue }

            guard let entry = types[typeName] else {
                if let read = partialPropertyReads(of: input.name, typeName: typeName, in: node) {
                    let list = read.sorted().lazy.map { "'\($0)'" }.joined(separator: ", ")
                    diagnose(.partialReadInput(input.name, typeName, list), on: node)
                }
                continue
            }
            guard entry.kind == .struct, !entry.isView else { continue }
            let count = entry.storedInstancePropertyCount
            guard count >= Self.largeModelPropertyCount else { continue }
            diagnose(.wholeValueInput(input.name, typeName, count), on: node)
        }
        return .skipChildren
    }

    /// The properties the view reads of the input `name` , or `nil` when the view uses the value
    /// whole or reads too few properties to report.
    ///
    /// The search covers the view's declaration and its same-file extensions. An initializer only
    /// stores the input, so the search skips it.
    private func partialPropertyReads(
        of name: String,
        typeName: String,
        in node: VariableDeclSyntax
    ) -> Set<String>? {
        guard !Self.frameworkTypes.contains(typeName), !typeName.hasSuffix("View"),
              let viewEntry = context.viewEntry(forMember: node),
              let viewName = TypeMemberIndex.enclosingTypeName(of: node) else { return nil }
        var read = Set<String>()
        let regions = TypeMemberIndex.declarationRegions(ofMember: node, typeName: viewName)

        for region in regions {
            for item in region.memberBlock.members where !item.decl.is(InitializerDeclSyntax.self) {
                for reference in TypeMemberIndex.references(in: item.decl, of: viewEntry)
                where reference.name == name {
                    guard let property = Self.propertyRead(from: reference.node) else { return nil }
                    read.insert(property)
                }
            }
        }
        return read.count >= Self.partialReadCount ? read : nil
    }

    /// The property name when `reference` is the base of a plain property read such as
    /// `tag.name` or `self.tag?.name` , or `nil` for any other use of the value
    private static func propertyRead(from reference: DeclReferenceExprSyntax) -> String? {
        var base = reference.selfQualifiedUse

        while let next = base.parent,
              next.is(OptionalChainingExprSyntax.self) || next.is(ForceUnwrapExprSyntax.self) {
            base = next
        }
        guard let read = base.parent?.as(MemberAccessExprSyntax.self), read.base?.id == base.id
        else { return nil }

        if let call = read.parent?.as(FunctionCallExprSyntax.self),
           call.calledExpression.id == read.id { return nil }
        return read.declName.baseName.text
    }
}

fileprivate extension Finding.Message {
    static func partialReadInput(_ name: String, _ type: String, _ read: String) -> Finding.Message {
        """
        '\(name)' stores the whole value '\(type)' as an input but reads only \(read). A change \
        to any other property still updates this view. Pass only the properties the view reads
        """
    }

    static func wholeValueInput(_ name: String, _ type: String, _ count: Int) -> Finding.Message {
        """
        '\(name)' stores the whole value model '\(type)' (\(count) stored properties) as an \
        input. A change to any property updates this view. Pass only the properties the view reads
        """
    }
}
