import SwiftSyntax

struct PreferCountWhereRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "prefer_count_where",
    name: "Prefer count(where:)",
    description: "Use `count(where:)` instead of `filter(_:).count` for better performance",
    scope: .lint,
    minSwiftVersion: .v6,
    nonTriggeringExamples: [
      Example("let count = array.count"),
      Example("let count = array.count(where: { $0 > 0 })"),
      Example("let filtered = array.filter { $0 > 0 }"),
    ],
    triggeringExamples: [
      Example("let count = array.↓filter { $0 > 0 }.count"),
      Example("let count = array.↓filter({ $0 > 0 }).count"),
    ],
  )
}

extension PreferCountWhereRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension PreferCountWhereRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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
