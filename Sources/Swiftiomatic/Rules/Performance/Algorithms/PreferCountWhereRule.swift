import SwiftSyntax

struct PreferCountWhereRule {
    static let id = "prefer_count_where"
    static let name = "Prefer count(where:)"
    static let summary = "Use `count(where:)` instead of `filter(_:).count` for better performance"
    static var nonTriggeringExamples: [Example] {
        [
              Example("let count = array.count"),
              Example("let count = array.count(where: { $0 > 0 })"),
              Example("let filtered = array.filter { $0 > 0 }"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("let count = array.↓filter { $0 > 0 }.count"),
              Example("let count = array.↓filter({ $0 > 0 }).count"),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension PreferCountWhereRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PreferCountWhereRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      // Looking for `.count` access on a `.filter(...)` call
      guard node.declName.baseName.text == "count" else { return }

      // The base should be a function call to `filter`
      guard let filterCall = node.base?.as(FunctionCallExprSyntax.self),
        let memberAccess = filterCall.calledExpression.as(MemberAccessExprSyntax.self),
        memberAccess.declName.baseName.text == "filter"
      else { return }

      violations.append(
        memberAccess.declName.positionAfterSkippingLeadingTrivia,
      )
    }
  }
}
