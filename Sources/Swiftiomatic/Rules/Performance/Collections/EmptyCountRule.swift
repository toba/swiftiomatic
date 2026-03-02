import SwiftLexicalLookup
import SwiftSyntax
import SwiftSyntaxBuilder

struct EmptyCountRule {
  var options = EmptyCountOptions()

  static let configuration = EmptyCountConfiguration()
}

extension EmptyCountRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension EmptyCountRule {
  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.foldedSyntaxTree
  }
}

extension EmptyCountRule {}

extension EmptyCountRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InfixOperatorExprSyntax) {
      guard let binaryOperator = node.binaryOperator, binaryOperator.isComparison else {
        return
      }

      if let (_, position) =
        node
        .countNodeAndPosition(onlyAfterDot: configuration.onlyAfterDot)
      {
        violations.append(position)
      }
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
      node.isTipsRuleMacro ? .skipChildren : .visitChildren
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
      guard let binaryOperator = node.binaryOperator, binaryOperator.isComparison else {
        return super.visit(node)
      }

      if let (count, _) =
        node
        .countNodeAndPosition(onlyAfterDot: configuration.onlyAfterDot)
      {
        let newNode =
          if let count = count.as(MemberAccessExprSyntax.self) {
            ExprSyntax(count.with(\.declName.baseName, "isEmpty").trimmed)
          } else {
            ExprSyntax(
              count.as(DeclReferenceExprSyntax.self)?.with(
                \.baseName,
                "isEmpty",
              ).trimmed)
          }
        guard let newNode else {
          return super.visit(node)
        }
        numberOfCorrections += 1
        return
          if ["!=", "<", ">"].contains(binaryOperator)
        {
          newNode.negated
            .withTrivia(from: node)
        } else {
          newNode
            .withTrivia(from: node)
        }
      }
      return super.visit(node)
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
      if node.isTipsRuleMacro {
        ExprSyntax(node)
      } else {
        super.visit(node)
      }
    }
  }
}

extension ExprSyntax {
  fileprivate var isNonLocalCountIdentifier: Bool {
    guard let declRef = `as`(DeclReferenceExprSyntax.self),
      declRef.argumentNames == nil,
      declRef.baseName.tokenKind == .identifier("count")
    else {
      return false
    }
    let result = lookup(Identifier(canonicalName: "count"))
    return result.isEmpty
      || !result.contains { result in
        switch result {
        case .fromScope: true
        default: false
        }
      }
  }

  fileprivate func countCallPosition(onlyAfterDot: Bool) -> AbsolutePosition? {
    if let expr = `as`(MemberAccessExprSyntax.self) {
      if expr.declName.argumentNames == nil,
        expr.declName.baseName.tokenKind == .identifier("count")
      {
        return expr.declName.baseName.positionAfterSkippingLeadingTrivia
      }
      return nil
    }
    if !onlyAfterDot, isNonLocalCountIdentifier {
      return positionAfterSkippingLeadingTrivia
    }
    return nil
  }
}

extension TokenSyntax {
  fileprivate var binaryOperator: String? {
    switch tokenKind {
    case .binaryOperator(let str):
      return str
    default:
      return nil
    }
  }
}

extension MacroExpansionExprSyntax {
  fileprivate var isTipsRuleMacro: Bool {
    macroName.text == "Rule" && additionalTrailingClosures.isEmpty && arguments.count == 1
      && trailingClosure
        .map { $0.statements.onlyElement?.item.is(ReturnStmtSyntax.self) == false }
        ?? false
  }
}

extension ExprSyntaxProtocol {
  fileprivate var negated: ExprSyntax {
    ExprSyntax(PrefixOperatorExprSyntax(operator: .prefixOperator("!"), expression: self))
  }
}

extension SyntaxProtocol {
  fileprivate func withTrivia(from node: some SyntaxProtocol) -> Self {
    with(\.leadingTrivia, node.leadingTrivia)
      .with(\.trailingTrivia, node.trailingTrivia)
  }
}

extension InfixOperatorExprSyntax {
  fileprivate func countNodeAndPosition(onlyAfterDot: Bool) -> (ExprSyntax, AbsolutePosition)? {
    if let intExpr = rightOperand.as(IntegerLiteralExprSyntax.self), intExpr.isZero,
      let position = leftOperand.countCallPosition(onlyAfterDot: onlyAfterDot)
    {
      return (leftOperand, position)
    }
    if let intExpr = leftOperand.as(IntegerLiteralExprSyntax.self), intExpr.isZero,
      let position = rightOperand.countCallPosition(onlyAfterDot: onlyAfterDot)
    {
      return (rightOperand, position)
    }
    return nil
  }

  fileprivate var binaryOperator: String? {
    `operator`.as(BinaryOperatorExprSyntax.self)?.operator.binaryOperator
  }
}

extension String {
  private static let operators: Set = ["==", "!=", ">", ">=", "<", "<="]
  fileprivate var isComparison: Bool {
    String.operators.contains(self)
  }
}
