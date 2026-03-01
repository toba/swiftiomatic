import SwiftSyntax

extension ClassDeclSyntax {
  package var containsInheritance: Bool {
    guard let inheritanceList = inheritanceClause?.inheritedTypes else {
      return false
    }
    return inheritanceList.isNotEmpty
  }
}

extension FunctionDeclSyntax {
  package var isSpecFunction: Bool {
    name.tokenKind == .identifier("spec") && signature.parameterClause.parameters.isEmpty
      && modifiers.contains(keyword: .override)
  }
}
