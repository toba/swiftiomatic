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

extension TypeSyntax {
    /// Tells if `trimmedDescription == text` is true.
    ///
    /// For a plain identifier type with no generic arguments, the compare reads the name token and
    /// builds no description. Other types fall back to `trimmedDescription` . Thus a qualified
    /// type such as `Foundation.XCTestCase` matches only the full text `"Foundation.XCTestCase"` .
    func trimmedDescriptionEquals(_ text: String) -> Bool {
        if let identifier = self.as(IdentifierTypeSyntax.self),
           identifier.genericArgumentClause == nil,
           identifier.unexpectedBeforeName == nil,
           identifier.unexpectedBetweenNameAndGenericArgumentClause == nil,
           identifier.unexpectedAfterGenericArgumentClause == nil
        {
            return identifier.name.text == text
        }
        return trimmedDescription == text
    }
}
