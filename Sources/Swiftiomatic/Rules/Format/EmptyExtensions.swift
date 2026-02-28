import Foundation

extension FormatRule {
    /// Remove empty, non-conforming, extensions.
    static let emptyExtensions = FormatRule(
        help: "Remove empty, non-protocol-conforming extensions.",
        orderAfter: [.unusedPrivateDeclarations],
    ) { formatter in
        var emptyExtensions = [TypeDeclaration]()

        for declaration in formatter.parseDeclarations() {
            guard declaration.keyword == "extension",
                  let extensionDeclaration = declaration.asTypeDeclaration,
                  extensionDeclaration.body.isEmpty,
                  // Ensure that it is not a macro
                  !extensionDeclaration.modifiers.contains(where: \.isAttribute)
            else { continue }

            // Ensure that the extension does not conform to any protocols
            guard extensionDeclaration.conformances.isEmpty else { continue }

            emptyExtensions.append(extensionDeclaration)
        }

        for emptyExtension in emptyExtensions {
            emptyExtension.remove()
        }
    } examples: {
        """
        ```diff
        - extension String {}
        -
          extension String: Equatable {}
        ```
        """
    }
}
