import SwiftSyntax
import SwiftSyntaxBuilder

struct PreferKeyPathRule {
  var options = PreferKeyPathOptions()

  static let configuration = PreferKeyPathConfiguration()
}

extension PreferKeyPathRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension PreferKeyPathRule {}

extension PreferKeyPathRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClosureExprSyntax) {
      if node
        .isInvalid(restrictToStandardFunctions: configuration.restrictToStandardFunctions)
      {
        return
      }
      if let onlyStmt = node.onlyExprStmt,
        onlyStmt.accesses(identifier: node.onlyParameter)
      {
        if onlyStmt.is(DeclReferenceExprSyntax.self),
          configuration.ignoreIdentityClosures || SwiftVersion.current < .v6
        {
          return
        }

        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard node.additionalTrailingClosures.isEmpty,
        let closure = node.trailingClosure,
        !closure
          .isInvalid(
            restrictToStandardFunctions: configuration
              .restrictToStandardFunctions),
        let expr = closure.onlyExprStmt,
        expr.accesses(identifier: closure.onlyParameter) == true,
        let replacement = expr.asKeyPath(
          ignoreIdentityClosures: configuration.ignoreIdentityClosures,
        ),
        let calleeName = node.calleeName
      else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      var node = node.with(
        \.calledExpression,
        node.calledExpression.with(\.trailingTrivia, []),
      )
      if node.leftParen == nil {
        node = node.with(\.leftParen, .leftParenToken())
      }
      let newArg = LabeledExprSyntax(
        label: argumentLabelByStandardFunction[calleeName, default: nil],
        expression: replacement,
      )
      node = node.with(
        \.arguments, [newArg],
      )
      if node.rightParen == nil {
        node = node.with(\.rightParen, .rightParenToken())
      }
      node =
        node
        .with(\.trailingClosure, nil)
        .with(\.trailingTrivia, node.trailingTrivia)
      return super.visit(node)
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
      if node
        .isInvalid(restrictToStandardFunctions: configuration.restrictToStandardFunctions)
      {
        return super.visit(node)
      }
      if let expr = node.onlyExprStmt,
        expr.accesses(identifier: node.onlyParameter) == true,
        let replacement = expr.asKeyPath(
          ignoreIdentityClosures: configuration.ignoreIdentityClosures,
        )
      {
        numberOfCorrections += 1
        let node =
          replacement
          .with(\.leadingTrivia, node.leadingTrivia)
          .with(\.trailingTrivia, node.trailingTrivia)
        return super.visit(node)
      }
      return super.visit(node)
    }
  }
}

extension ExprSyntax {
  fileprivate func accesses(identifier: String?) -> Bool {
    if let base = `as`(MemberAccessExprSyntax.self)?.base {
      return base.accesses(identifier: identifier)
    }
    if let declRef = `as`(DeclReferenceExprSyntax.self) {
      return declRef.baseName.text == identifier ?? "$0"
    }
    return false
  }
}

extension ClosureExprSyntax {
  fileprivate var onlyParameter: String? {
    switch signature?.parameterClause {
    case .simpleInput(let params):
      return params.onlyElement?.name.text
    case .parameterClause(let params):
      let param = params.parameters.onlyElement
      return param?.secondName?.text ?? param?.firstName.text
    case nil: return nil
    }
  }

  fileprivate var onlyExprStmt: ExprSyntax? {
    if case .expr(let expr) = statements.onlyElement?.item {
      return expr
    }
    return nil
  }

  fileprivate func isInvalid(restrictToStandardFunctions: Bool) -> Bool {
    guard keyPathInParent != \FunctionCallExprSyntax.calledExpression,
      let parent,
      ![.macroExpansionExpr, .multipleTrailingClosureElement].contains(parent.kind),
      previousToken(viewMode: .sourceAccurate)?.text != "??"
    else {
      return true
    }
    if let call = parent.as(LabeledExprSyntax.self)?.parent?.parent?
      .as(FunctionCallExprSyntax.self)
    {
      // Closure is function argument.
      return restrictToStandardFunctions && !call.isStandardFunction
    }
    if let call = parent.as(FunctionCallExprSyntax.self) {
      // Trailing closure.
      return call.additionalTrailingClosures.isNotEmpty
        || restrictToStandardFunctions && !call.isStandardFunction
    }
    return false
  }
}

private let argumentLabelByStandardFunction: [String: String?] = [
  "allSatisfy": nil,
  "contains": "where",
  "compactMap": nil,
  "drop": "while",
  "filter": nil,
  "first": "where",
  "flatMap": nil,
  "map": nil,
  "partition": "by",
  "prefix": "while",
]

extension FunctionCallExprSyntax {
  fileprivate var isStandardFunction: Bool {
    if let calleeName, argumentLabelByStandardFunction.keys.contains(calleeName) {
      return arguments.count + (trailingClosure == nil ? 0 : 1) == 1
    }
    return false
  }

  fileprivate var calleeName: String? {
    (calledExpression.as(DeclReferenceExprSyntax.self)
      ?? calledExpression.as(MemberAccessExprSyntax.self)?.declName)?.baseName.text
  }
}

extension ExprSyntax {
  fileprivate func asKeyPath(ignoreIdentityClosures: Bool) -> ExprSyntax? {
    if let memberAccess = `as`(MemberAccessExprSyntax.self) {
      var this = memberAccess.base
      var elements = [memberAccess.declName]
      while this?.is(DeclReferenceExprSyntax.self) != true {
        if let memberAccess = this?.as(MemberAccessExprSyntax.self) {
          elements.append(memberAccess.declName)
          this = memberAccess.base
        }
      }
      return "\\.\(raw: elements.reversed().map(\.baseName.text).joined(separator: "."))"
        as ExprSyntax
    }

    if !ignoreIdentityClosures, SwiftVersion.current >= .v6,
      `is`(DeclReferenceExprSyntax.self)
    {
      return "\\.self"
    }
    return nil
  }
}
