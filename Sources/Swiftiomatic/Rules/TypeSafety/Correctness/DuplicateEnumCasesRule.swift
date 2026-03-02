import SwiftSyntax

struct DuplicateEnumCasesRule {
  var options = SeverityConfiguration<Self>(.error)

  static let configuration = DuplicateEnumCasesConfiguration()
}

extension DuplicateEnumCasesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DuplicateEnumCasesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: EnumDeclSyntax) {
      let enumElements = node.memberBlock.members
        .flatMap { member -> EnumCaseElementListSyntax in
          guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
            return EnumCaseElementListSyntax([])
          }

          return enumCaseDecl.elements
        }

      let elementsByName = enumElements.reduce(into: [String: [AbsolutePosition]]()) {
        elements, element in
        let name = String(element.name.text)
        elements[name, default: []].append(element.positionAfterSkippingLeadingTrivia)
      }

      let duplicatedElementPositions =
        elementsByName
        .filter { $0.value.count > 1 }
        .flatMap(\.value)

      violations.append(contentsOf: duplicatedElementPositions)
    }
  }
}
