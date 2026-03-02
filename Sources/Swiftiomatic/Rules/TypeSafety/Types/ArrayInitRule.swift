import SwiftSyntax

struct ArrayInitRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ArrayInitConfiguration()
}

extension ArrayInitRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ArrayInitRule {}

extension ArrayInitRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
        memberAccess.declName.baseName.text == "map",
        let (closureParam, closureStatement) = node.singleClosure(),
        closureStatement.returnsInput(closureParam)
      else {
        return
      }

      violations.append(memberAccess.declName.baseName.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate func singleClosure() -> (String?, CodeBlockItemSyntax)? {
    let closure: ClosureExprSyntax
    if let expression = arguments.onlyElement?.expression.as(ClosureExprSyntax.self) {
      closure = expression
    } else if arguments.isEmpty, let expression = trailingClosure {
      closure = expression
    } else {
      return nil
    }

    if let closureStatement = closure.statements.onlyElement {
      return (closure.signature?.singleInputParamText(), closureStatement)
    }
    return nil
  }
}

extension CodeBlockItemSyntax {
  fileprivate func returnsInput(_ closureParam: String?) -> Bool {
    let expectedReturnIdentifier = closureParam ?? "$0"
    let identifier =
      item.as(DeclReferenceExprSyntax.self)
      ?? item.as(ReturnStmtSyntax.self)?.expression?.as(DeclReferenceExprSyntax.self)
    return identifier?.baseName.text == expectedReturnIdentifier
  }
}

extension ClosureSignatureSyntax {
  fileprivate func singleInputParamText() -> String? {
    if let list = parameterClause?.as(ClosureShorthandParameterListSyntax.self),
      list.count == 1
    {
      return list.onlyElement?.name.text
    }
    if let clause = parameterClause?.as(ClosureParameterClauseSyntax.self),
      clause.parameters.count == 1,
      clause.parameters.first?.secondName == nil
    {
      return clause.parameters.first?.firstName.text
    }
    return nil
  }
}
