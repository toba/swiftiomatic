import SwiftSyntax

extension TypeSyntax {
    /// The last name component of a type reference, or `nil` when the type carries no name.
    ///
    /// `Foo` , `Foo<Bar>` and `Outer.Foo` all answer `Foo` . An attributed type answers the name of
    /// the type it wraps. A tuple, a function type and a composition answer `nil` .
    ///
    /// Use this to key a lookup by the spelling a declaration in the same file would carry.
    var simpleName: String? {
        if let attributed = self.as(AttributedTypeSyntax.self) {
            return attributed.baseType.simpleName
        }
        if let identifier = self.as(IdentifierTypeSyntax.self) { return identifier.name.text }
        if let member = self.as(MemberTypeSyntax.self) { return member.name.text }
        return nil
    }
}
