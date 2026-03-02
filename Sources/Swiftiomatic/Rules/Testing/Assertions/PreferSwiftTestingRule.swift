import SwiftSyntax

struct PreferSwiftTestingRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = PreferSwiftTestingConfiguration()
}

extension PreferSwiftTestingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PreferSwiftTestingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClassDeclSyntax) {
      // Check if class inherits from XCTestCase
      guard let inheritanceClause = node.inheritanceClause,
        inheritanceClause.inheritedTypes.contains(where: {
          $0.type.trimmedDescription == "XCTestCase"
        })
      else { return }

      violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
    }
  }
}
