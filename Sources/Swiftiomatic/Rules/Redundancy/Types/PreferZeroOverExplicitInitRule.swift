import SwiftSyntax
import SwiftSyntaxBuilder

struct PreferZeroOverExplicitInitRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = PreferZeroOverExplicitInitConfiguration()
}

extension PreferZeroOverExplicitInitRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension PreferZeroOverExplicitInitRule {}

extension PreferZeroOverExplicitInitRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if node.hasViolation {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard node.hasViolation, let name = node.name else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newNode = MemberAccessExprSyntax(name: "zero")
        .with(\.base, "\(raw: name)")
        .with(\.leadingTrivia, node.leadingTrivia)
        .with(\.trailingTrivia, node.trailingTrivia)
      return super.visit(newNode)
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var hasViolation: Bool {
    isCGPointZeroCall || isCGSizeCall || isCGRectCall || isCGVectorCall || isUIEdgeInsetsCall
  }

  fileprivate var isCGPointZeroCall: Bool {
    name == "CGPoint" && argumentNames == ["x", "y"] && argumentsAreAllZero
  }

  fileprivate var isCGSizeCall: Bool {
    name == "CGSize" && argumentNames == ["width", "height"] && argumentsAreAllZero
  }

  fileprivate var isCGRectCall: Bool {
    name == "CGRect" && argumentNames == ["x", "y", "width", "height"] && argumentsAreAllZero
  }

  fileprivate var isCGVectorCall: Bool {
    name == "CGVector" && argumentNames == ["dx", "dy"] && argumentsAreAllZero
  }

  fileprivate var isUIEdgeInsetsCall: Bool {
    name == "UIEdgeInsets" && argumentNames == ["top", "left", "bottom", "right"]
      && argumentsAreAllZero
  }

  fileprivate var name: String? {
    guard let expr = calledExpression.as(DeclReferenceExprSyntax.self) else {
      return nil
    }

    return expr.baseName.text
  }

  fileprivate var argumentNames: [String?] {
    arguments.map(\.label?.text)
  }

  fileprivate var argumentsAreAllZero: Bool {
    arguments.allSatisfy { arg in
      if let intExpr = arg.expression.as(IntegerLiteralExprSyntax.self) {
        return intExpr.isZero
      }
      if let floatExpr = arg.expression.as(FloatLiteralExprSyntax.self) {
        return floatExpr.isZero
      }
      return false
    }
  }
}
