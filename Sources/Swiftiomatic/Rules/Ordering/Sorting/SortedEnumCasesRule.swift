import Foundation
import SwiftSyntax

struct SortedEnumCasesRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SortedEnumCasesConfiguration()
}

extension SortedEnumCasesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SortedEnumCasesRule {}

extension SortedEnumCasesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .allExcept(EnumDeclSyntax.self)
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
      guard !node.attributes.contains(attributeNamed: "frozen") else {
        return .skipChildren
      }

      let cases = node.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
      let sortedCases =
        cases
        .sorted(by: {
          let lhs = $0.elements.first!.name.text
          let rhs = $1.elements.first!.name.text
          return lhs.caseInsensitiveCompare(rhs) == .orderedAscending
        })

      for (sortedCase, currentCase) in zip(sortedCases, cases)
      where sortedCase.elements.first?.name.text != currentCase.elements.first?.name.text {
        violations.append(currentCase.positionAfterSkippingLeadingTrivia)
      }

      return .visitChildren
    }

    override func visitPost(_ node: EnumCaseDeclSyntax) {
      let sortedElements = node.elements.sorted(by: {
        $0.name.text.caseInsensitiveCompare($1.name.text) == .orderedAscending
      })

      for (sortedElement, currentElement) in zip(sortedElements, node.elements)
      where sortedElement.name.text != currentElement.name.text {
        violations.append(currentElement.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
