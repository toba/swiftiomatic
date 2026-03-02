import SwiftSyntax

struct RedundantSetAccessControlRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RedundantSetAccessControlConfiguration()
}

extension RedundantSetAccessControlRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantSetAccessControlRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [FunctionDeclSyntax.self]
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      let modifiers = node.modifiers
      guard let setAccessor = modifiers.setAccessor else {
        return
      }

      let uniqueModifiers = Set(modifiers.map(\.name.tokenKind))
      if uniqueModifiers.count != modifiers.count {
        violations.append(modifiers.positionAfterSkippingLeadingTrivia)
        return
      }

      if setAccessor.name.tokenKind == .keyword(.fileprivate),
        modifiers.getAccessor == nil,
        let closestDeclModifiers = node.closestDecl()?.modifiers
      {
        let closestDeclIsFilePrivate = closestDeclModifiers.contains {
          $0.name.tokenKind == .keyword(.fileprivate)
        }

        if closestDeclIsFilePrivate {
          violations.append(modifiers.positionAfterSkippingLeadingTrivia)
          return
        }
      }

      if setAccessor.name.tokenKind == .keyword(.internal),
        modifiers.getAccessor == nil,
        let closesDecl = node.closestDecl(),
        let closestDeclModifiers = closesDecl.modifiers
      {
        let closestDeclIsInternal =
          closestDeclModifiers.isEmpty
          || closestDeclModifiers.contains {
            $0.name.tokenKind == .keyword(.internal)
          }

        if closestDeclIsInternal {
          violations.append(modifiers.positionAfterSkippingLeadingTrivia)
          return
        }
      }
    }
  }
}

extension SyntaxProtocol {
  fileprivate func closestDecl() -> DeclSyntax? {
    if let decl = parent?.as(DeclSyntax.self) {
      return decl
    }

    return parent?.closestDecl()
  }
}

extension DeclSyntax {
  fileprivate var modifiers: DeclModifierListSyntax? {
    asProtocol((any WithModifiersSyntax).self)?.modifiers
  }
}

extension DeclModifierListSyntax {
  fileprivate var setAccessor: DeclModifierSyntax? {
    first { $0.detail?.detail.tokenKind == .identifier("set") }
  }

  fileprivate var getAccessor: DeclModifierSyntax? {
    first { $0.detail == nil }
  }
}
