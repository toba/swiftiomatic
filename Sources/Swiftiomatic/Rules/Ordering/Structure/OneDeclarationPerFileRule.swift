import SwiftSyntax

struct OneDeclarationPerFileRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = OneDeclarationPerFileConfiguration()
}

extension OneDeclarationPerFileRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension OneDeclarationPerFileRule {}

extension OneDeclarationPerFileRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var declarationVisited = false
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: ActorDeclSyntax) {
      appendViolationIfNeeded(node: node.actorKeyword)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      appendViolationIfNeeded(node: node.classKeyword)
    }

    override func visitPost(_ node: StructDeclSyntax) {
      appendViolationIfNeeded(node: node.structKeyword)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      appendViolationIfNeeded(node: node.enumKeyword)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      appendViolationIfNeeded(node: node.protocolKeyword)
    }

    func appendViolationIfNeeded(node: TokenSyntax) {
      if declarationVisited {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
      declarationVisited = true
    }
  }
}
