import SwiftSyntax

struct LegacyConstructorRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = LegacyConstructorConfiguration()

  private static let constructorsToArguments = [
    "CGRectMake": ["x", "y", "width", "height"],
    "CGPointMake": ["x", "y"],
    "CGSizeMake": ["width", "height"],
    "CGVectorMake": ["dx", "dy"],
    "NSMakePoint": ["x", "y"],
    "NSMakeSize": ["width", "height"],
    "NSMakeRect": ["x", "y", "width", "height"],
    "NSMakeRange": ["location", "length"],
    "UIEdgeInsetsMake": ["top", "left", "bottom", "right"],
    "NSEdgeInsetsMake": ["top", "left", "bottom", "right"],
    "UIOffsetMake": ["horizontal", "vertical"],
  ]

  private static let constructorsToCorrectedNames = [
    "CGRectMake": "CGRect",
    "CGPointMake": "CGPoint",
    "CGSizeMake": "CGSize",
    "CGVectorMake": "CGVector",
    "NSMakePoint": "NSPoint",
    "NSMakeSize": "NSSize",
    "NSMakeRect": "NSRect",
    "NSMakeRange": "NSRange",
    "UIEdgeInsetsMake": "UIEdgeInsets",
    "NSEdgeInsetsMake": "NSEdgeInsets",
    "UIOffsetMake": "UIOffset",
  ]
}

extension LegacyConstructorRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension LegacyConstructorRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
        constructorsToCorrectedNames[identifierExpr.baseName.text] != nil
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
        case let identifier = identifierExpr.baseName.text,
        let correctedName = constructorsToCorrectedNames[identifier],
        let args = constructorsToArguments[identifier]
      else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let arguments = LabeledExprListSyntax(
        node.arguments.enumerated().map { index, elem in
          elem
            .with(\.label, .identifier(args[index]))
            .with(\.colon, .colonToken(trailingTrivia: .space))
        },
      )
      let newExpression = identifierExpr.with(
        \.baseName,
        .identifier(
          correctedName,
          leadingTrivia: identifierExpr.baseName.leadingTrivia,
          trailingTrivia: identifierExpr.baseName.trailingTrivia,
        ),
      )
      let newNode =
        node
        .with(\.calledExpression, ExprSyntax(newExpression))
        .with(\.arguments, arguments)
      return super.visit(newNode)
    }
  }
}
