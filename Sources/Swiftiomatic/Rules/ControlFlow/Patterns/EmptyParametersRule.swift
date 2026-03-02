import SwiftSyntax

struct EmptyParametersRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = EmptyParametersConfiguration()
}

extension EmptyParametersRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension EmptyParametersRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionTypeSyntax) {
      guard let violationPosition = node.emptyParametersViolationPosition else {
        return
      }

      violations.append(violationPosition)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
      guard node.emptyParametersViolationPosition != nil else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      return super.visit(node.with(\.parameters, TupleTypeElementListSyntax([])))
    }
  }
}

extension FunctionTypeSyntax {
  fileprivate var emptyParametersViolationPosition: AbsolutePosition? {
    guard
      let argument = parameters.onlyElement,
      leftParen.presence == .present,
      rightParen.presence == .present,
      let simpleType = argument.type.as(IdentifierTypeSyntax.self),
      simpleType.typeName == "Void"
    else {
      return nil
    }

    return leftParen.positionAfterSkippingLeadingTrivia
  }
}
