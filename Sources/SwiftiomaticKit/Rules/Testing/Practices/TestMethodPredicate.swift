import SwiftSyntax

extension FunctionDeclSyntax {
  package var isDiscoverableTestMethod: Bool {
    name.text.hasPrefix("test")
      && signature.parameterClause.parameters.isEmpty
      && signature.returnClause == nil
      && !modifiers.contains(keyword: .static)
  }
}
