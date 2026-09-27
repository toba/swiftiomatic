import SwiftSyntax

extension SyntaxProtocol {
    /// Reports whether this node reads a local value with one of the given names.
    ///
    /// A bare name such as `error` counts. A member with the same spelling, such as the `error` in
    /// `AppError.error`, does not count.
    func referencesLocal(named names: Set<String>) -> Bool {
        tokens(viewMode: .sourceAccurate).contains { token in
            // Check the parent kind first. The check builds no `String` , and most tokens fail
            // it, so few tokens build their text.
            guard let reference = token.parent?.as(DeclReferenceExprSyntax.self),
                  names.contains(token.text)
            else { return false }

            if let member = reference.parent?.as(MemberAccessExprSyntax.self),
               member.declName.id == reference.id { return false }
            return true
        }
    }
}
