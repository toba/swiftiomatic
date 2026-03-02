import SwiftSyntax

struct UnavailableFunctionRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = UnavailableFunctionConfiguration()
}

extension UnavailableFunctionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension UnavailableFunctionRule {}

extension UnavailableFunctionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      guard !node.returnsNever,
        !node.attributes.hasUnavailableAttribute,
        node.body.containsTerminatingCall,
        !node.body.containsReturn
      else {
        return
      }

      violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      guard !node.attributes.hasUnavailableAttribute,
        node.body.containsTerminatingCall,
        !node.body.containsReturn
      else {
        return
      }

      violations.append(node.initKeyword.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension FunctionDeclSyntax {
  fileprivate var returnsNever: Bool {
    if let expr = signature.returnClause?.type.as(IdentifierTypeSyntax.self) {
      return expr.name.text == "Never"
    }
    return false
  }
}

extension AttributeListSyntax {
  fileprivate var hasUnavailableAttribute: Bool {
    contains { elem in
      guard let attr = elem.as(AttributeSyntax.self),
        let arguments = attr.arguments?.as(AvailabilityArgumentListSyntax.self)
      else {
        return false
      }

      let attributeName = attr.attributeNameText
      return attributeName == "available"
        && arguments.contains { arg in
          arg.argument.as(TokenSyntax.self)?.tokenKind.isUnavailableKeyword == true
        }
    }
  }
}

extension CodeBlockSyntax? {
  fileprivate var containsTerminatingCall: Bool {
    guard let statements = self?.statements else {
      return false
    }

    let terminatingFunctions: Set = [
      "abort",
      "fatalError",
      "preconditionFailure",
    ]

    return statements.contains { item in
      guard let function = item.item.as(FunctionCallExprSyntax.self),
        let identifierExpr = function.calledExpression.as(DeclReferenceExprSyntax.self)
      else {
        return false
      }

      return terminatingFunctions.contains(identifierExpr.baseName.text)
    }
  }

  fileprivate var containsReturn: Bool {
    guard let statements = self?.statements else {
      return false
    }

    return ReturnFinderVisitor(viewMode: .sourceAccurate)
      .walk(tree: statements, handler: \.containsReturn)
  }
}

private final class ReturnFinderVisitor: SyntaxVisitor {
  private(set) var containsReturn = false

  override func visitPost(_: ReturnStmtSyntax) {
    containsReturn = true
  }

  override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }

  override func visit(_: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }
}
