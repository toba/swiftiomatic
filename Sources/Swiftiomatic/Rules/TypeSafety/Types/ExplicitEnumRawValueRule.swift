import SwiftSyntax

struct ExplicitEnumRawValueRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ExplicitEnumRawValueConfiguration()
}

extension ExplicitEnumRawValueRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ExplicitEnumRawValueRule {}

extension ExplicitEnumRawValueRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: EnumCaseElementSyntax) {
      if node.rawValue == nil, node.enclosingEnum()?.supportsRawValues == true {
        violations.append(node.name.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension SyntaxProtocol {
  fileprivate func enclosingEnum() -> EnumDeclSyntax? {
    if let node = `as`(EnumDeclSyntax.self) {
      return node
    }

    return parent?.enclosingEnum()
  }
}
