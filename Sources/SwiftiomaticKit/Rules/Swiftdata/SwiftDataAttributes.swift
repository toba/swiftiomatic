import SwiftSyntax

extension AttributeListSyntax {
    /// The first attribute named `name` , written bare or qualified by `module` , or `nil` .
    ///
    /// The SwiftData rules match `@Model` and `@SwiftData.Model` , and `@Observable` and
    /// `@Observation.Observable` .
    func attribute(named name: String, module: String) -> AttributeSyntax? {
        for element in self {
            guard case let .attribute(attr) = element else { continue }

            if let ident = attr.attributeName.as(IdentifierTypeSyntax.self), ident.name.text == name
            {
                return attr
            }
            if let member = attr.attributeName.as(MemberTypeSyntax.self),
                member.name.text == name,
                member.baseType.as(IdentifierTypeSyntax.self)?.name.text == module
            {
                return attr
            }
        }
        return nil
    }
}
