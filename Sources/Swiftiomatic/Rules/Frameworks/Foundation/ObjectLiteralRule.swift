import SwiftSyntax

struct ObjectLiteralRule {
  var options = ObjectLiteralOptions<Self>()

  static let configuration = ObjectLiteralConfiguration()
}

extension ObjectLiteralRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ObjectLiteralRule {}

extension ObjectLiteralRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard configuration.colorLiteral || configuration.imageLiteral else {
        return
      }

      let name = node.calledExpression.trimmedDescription
      if configuration.imageLiteral, isImageNamedInit(node: node, name: name) {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      } else if configuration.colorLiteral, isColorInit(node: node, name: name) {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }

    private func isImageNamedInit(node: FunctionCallExprSyntax, name: String) -> Bool {
      guard inits(forClasses: ["UIImage", "NSImage"]).contains(name),
        node.arguments.compactMap(\.label?.text) == ["named"],
        let argument = node.arguments.first?.expression.as(StringLiteralExprSyntax.self),
        argument.isConstantString
      else {
        return false
      }

      return true
    }

    private func isColorInit(node: FunctionCallExprSyntax, name: String) -> Bool {
      guard inits(forClasses: ["UIColor", "NSColor"]).contains(name),
        case let argumentsNames = node.arguments.compactMap(\.label?.text),
        argumentsNames == ["red", "green", "blue", "alpha"]
          || argumentsNames == [
            "white",
            "alpha",
          ]
      else {
        return false
      }

      return node.arguments.allSatisfy(\.expression.canBeExpressedAsColorLiteralParams)
    }

    private func inits(forClasses names: [String]) -> [String] {
      names.flatMap { name in
        [
          name,
          name + ".init",
        ]
      }
    }
  }
}

extension StringLiteralExprSyntax {
  fileprivate var isConstantString: Bool {
    segments.allSatisfy { $0.is(StringSegmentSyntax.self) }
  }
}

extension ExprSyntax {
  fileprivate var canBeExpressedAsColorLiteralParams: Bool {
    if `is`(FloatLiteralExprSyntax.self) || `is`(IntegerLiteralExprSyntax.self)
      || `is`(BinaryOperatorExprSyntax.self)
    {
      return true
    }

    if let expr = `as`(SequenceExprSyntax.self) {
      return expr.elements.allSatisfy(\.canBeExpressedAsColorLiteralParams)
    }

    return false
  }
}
