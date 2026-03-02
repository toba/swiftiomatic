import SwiftSyntax

struct IsDisjointRule {
    static let id = "is_disjoint"
    static let name = "Is Disjoint"
    static let summary = "Prefer using `Set.isDisjoint(with:)` over `Set.intersection(_:).isEmpty`"
    static var nonTriggeringExamples: [Example] {
        [
              Example("_ = Set(syntaxKinds).isDisjoint(with: commentAndStringKindsSet)"),
              Example(
                "let isObjc = !objcAttributes.isDisjoint(with: dictionary.enclosedSwiftAttributes)",
              ),
              Example("_ = Set(syntaxKinds).intersection(commentAndStringKindsSet)"),
              Example("_ = !objcAttributes.intersection(dictionary.enclosedSwiftAttributes)"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("_ = Set(syntaxKinds).↓intersection(commentAndStringKindsSet).isEmpty"),
              Example(
                "let isObjc = !objcAttributes.↓intersection(dictionary.enclosedSwiftAttributes).isEmpty",
              ),
            ]
    }
  var options = SeverityOption<Self>(.warning)

}

extension IsDisjointRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension IsDisjointRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      guard
        node.declName.baseName.text == "isEmpty",
        let firstBase = node.base?.asFunctionCall,
        let firstBaseCalledExpression = firstBase.calledExpression
          .as(MemberAccessExprSyntax.self),
        firstBaseCalledExpression.declName.baseName.text == "intersection"
      else {
        return
      }

      violations.append(
        firstBaseCalledExpression.declName.baseName.positionAfterSkippingLeadingTrivia,
      )
    }
  }
}
