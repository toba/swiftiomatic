import SwiftSyntax
import SwiftSyntaxBuilder

struct NimbleOperatorRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = NimbleOperatorConfiguration()
}

extension NimbleOperatorRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension NimbleOperatorRule {}

extension NimbleOperatorRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard predicateDescription(for: node) != nil else {
        return
      }
      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard let expectation = node.expectation(),
        let predicate = predicatesMapping[expectation.operatorExpr.baseName.text],
        let operatorExpr = expectation.operatorExpr(for: predicate),
        let expectedValueExpr = expectation.expectedValueExpr(for: predicate)
      else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let elements = ExprListSyntax(
        [
          expectation.baseExpr.with(\.trailingTrivia, .space),
          operatorExpr.with(\.trailingTrivia, .space),
          expectedValueExpr.with(\.trailingTrivia, node.trailingTrivia),
        ].map(ExprSyntax.init),
      )
      return super.visit(SequenceExprSyntax(elements: elements))
    }
  }

  fileprivate typealias MatcherFunction = String

  fileprivate static let predicatesMapping: [MatcherFunction: PredicateDescription] = [
    "equal": (to: "==", toNot: "!=", .withArguments),
    "beIdenticalTo": (to: "===", toNot: "!==", .withArguments),
    "beGreaterThan": (to: ">", toNot: nil, .withArguments),
    "beGreaterThanOrEqualTo": (to: ">=", toNot: nil, .withArguments),
    "beLessThan": (to: "<", toNot: nil, .withArguments),
    "beLessThanOrEqualTo": (to: "<=", toNot: nil, .withArguments),
    "beTrue": (
      to: "==", toNot: "!=",
      .nullary(analogueValue: BooleanLiteralExprSyntax(booleanLiteral: true)),
    ),
    "beFalse": (
      to: "==", toNot: "!=",
      .nullary(analogueValue: BooleanLiteralExprSyntax(booleanLiteral: false)),
    ),
    "beNil": (
      to: "==", toNot: "!=",
      .nullary(analogueValue: NilLiteralExprSyntax(nilKeyword: .keyword(.nil))),
    ),
  ]

  fileprivate static func predicateDescription(for node: FunctionCallExprSyntax)
    -> PredicateDescription?
  {
    guard let expectation = node.expectation() else {
      return nil
    }
    return Self.predicatesMapping[expectation.operatorExpr.baseName.text]
  }
}

extension FunctionCallExprSyntax {
  fileprivate func expectation() -> Expectation? {
    guard trailingClosure == nil,
      arguments.count == 1,
      let memberExpr = calledExpression.as(MemberAccessExprSyntax.self),
      let kind = Expectation.Kind(rawValue: memberExpr.declName.baseName.text),
      let baseExpr = memberExpr.base?.as(FunctionCallExprSyntax.self),
      baseExpr.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "expect",
      let predicateExpr = arguments.first?.expression.as(FunctionCallExprSyntax.self),
      let operatorExpr = predicateExpr.calledExpression.as(DeclReferenceExprSyntax.self)
    else {
      return nil
    }

    let expected = predicateExpr.arguments.first?.expression
    return Expectation(
      kind: kind, baseExpr: baseExpr, operatorExpr: operatorExpr, expected: expected,
    )
  }
}

private typealias PredicateDescription = (to: String, toNot: String?, arity: Arity)

private enum Arity {
  case nullary(analogueValue: any ExprSyntaxProtocol)
  case withArguments
}

private struct Expectation {
  let kind: Kind
  let baseExpr: FunctionCallExprSyntax
  let operatorExpr: DeclReferenceExprSyntax
  let expected: ExprSyntax?

  enum Kind {
    case positive
    case negative

    init?(rawValue: String) {
      switch rawValue {
      case "to":
        self = .positive
      case "toNot", "notTo":
        self = .negative
      default:
        return nil
      }
    }
  }

  func expectedValueExpr(for predicate: PredicateDescription) -> ExprSyntax? {
    switch predicate.arity {
    case .withArguments:
      expected
    case .nullary(let analogueValue):
      ExprSyntax(analogueValue)
    }
  }

  func operatorExpr(for predicate: PredicateDescription) -> BinaryOperatorExprSyntax? {
    let operatorStr =
      switch kind {
      case .negative:
        predicate.toNot
      case .positive:
        predicate.to
      }
    return operatorStr.map(BinaryOperatorExprSyntax.init)
  }
}
