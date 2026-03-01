import SwiftSyntax

struct RedundantNilCoalescingRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RedundantNilCoalescingConfiguration()

  static let description = RuleDescription(
    identifier: "redundant_nil_coalescing",
    name: "Redundant Nil Coalescing",
    description: "nil coalescing operator is only evaluated if the lhs is nil"
      + ", coalescing operator with nil as rhs is redundant",
    isOptIn: true,
    nonTriggeringExamples: [
      Example("var myVar: Int?; myVar ?? 0")
    ],
    triggeringExamples: [
      Example("var myVar: Int? = nil; myVar ↓?? nil")
    ],
    corrections: [
      Example("var myVar: Int? = nil; let foo = myVar ↓?? nil"):
        Example("var myVar: Int? = nil; let foo = myVar")
    ],
  )
}

extension RedundantNilCoalescingRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension RedundantNilCoalescingRule {}

extension RedundantNilCoalescingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TokenSyntax) {
      if node.tokenKind.isNilCoalescingOperator,
        node.nextToken(viewMode: .sourceAccurate)?.tokenKind == .keyword(.nil)
      {
        violations.append(node.position)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: ExprListSyntax) -> ExprListSyntax {
      guard
        node.count > 2,
        let lastExpression = node.last,
        lastExpression.is(NilLiteralExprSyntax.self),
        let secondToLastExpression = node.dropLast().last?
          .as(BinaryOperatorExprSyntax.self),
        secondToLastExpression.operator.tokenKind.isNilCoalescingOperator
      else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newNode = ExprListSyntax(node.dropLast(2)).with(\.trailingTrivia, [])
      return super.visit(newNode)
    }
  }
}

extension TokenKind {
  fileprivate var isNilCoalescingOperator: Bool {
    self == .binaryOperator("??")
  }
}
