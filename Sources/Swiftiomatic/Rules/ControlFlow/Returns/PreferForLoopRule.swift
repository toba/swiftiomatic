import SwiftSyntax

struct PreferForLoopRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = PreferForLoopConfiguration()
}

extension PreferForLoopRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PreferForLoopRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      // Looking for `.forEach { ... }` or `.forEach({ ... })`
      guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
        memberAccess.declName.baseName.text == "forEach"
      else { return }

      // Must have a trailing closure or a single closure argument
      let hasClosure =
        node.trailingClosure != nil
        || (node.arguments.count == 1
          && node.arguments.first?.expression.is(ClosureExprSyntax.self) == true)
      guard hasClosure else { return }

      // Skip if part of a chain (e.g. items.filter { ... }.forEach { ... })
      if let base = memberAccess.base,
        base.as(FunctionCallExprSyntax.self)?.calledExpression.as(MemberAccessExprSyntax.self)
          != nil
      {
        return
      }

      violations.append(memberAccess.declName.positionAfterSkippingLeadingTrivia)
    }
  }
}
