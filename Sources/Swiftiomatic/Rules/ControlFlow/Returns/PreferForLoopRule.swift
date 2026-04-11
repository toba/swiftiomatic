import SwiftSyntax

struct PreferForLoopRule {
  static let id = "prefer_for_loop"
  static let name = "Prefer For Loop"
  static let summary =
    "`.forEach { }` calls can be replaced with `for ... in` loops for better readability"
  static let scope: Scope = .suggest
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        for item in items {
          process(item)
        }
        """,
      ),
      Example("items.map { $0.name }"),
      Example("items.filter { $0.isActive }.forEach { process($0) }"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        items.↓forEach { item in
          process(item)
        }
        """,
      ),
      Example(
        """
        items.↓forEach {
          process($0)
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
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
        base.as(FunctionCallExprSyntax.self)?.calledExpression
          .as(MemberAccessExprSyntax.self)
          != nil
      {
        return
      }

      violations.append(memberAccess.declName.positionAfterSkippingLeadingTrivia)
    }
  }
}
