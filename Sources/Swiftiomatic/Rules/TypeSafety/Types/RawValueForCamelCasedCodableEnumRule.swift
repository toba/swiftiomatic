import SwiftSyntax

struct RawValueForCamelCasedCodableEnumRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RawValueForCamelCasedCodableEnumConfiguration()
}

extension RawValueForCamelCasedCodableEnumRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RawValueForCamelCasedCodableEnumRule {}

extension RawValueForCamelCasedCodableEnumRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private let codableTypes = Set(["Codable", "Decodable", "Encodable"])

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
      guard let inheritedTypes = node.inheritanceClause?.inheritedTypes.typeNames,
        !inheritedTypes.isDisjoint(with: codableTypes),
        inheritedTypes.contains("String")
      else {
        return .skipChildren
      }

      return .visitChildren
    }

    override func visitPost(_ node: EnumCaseElementSyntax) {
      guard node.rawValue == nil,
        case let name = node.name.text,
        !name.isUppercase,
        !name.isLowercase
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension InheritedTypeListSyntax {
  fileprivate var typeNames: Set<String> {
    Set(compactMap { $0.type.as(IdentifierTypeSyntax.self) }.map(\.name.text))
  }
}
