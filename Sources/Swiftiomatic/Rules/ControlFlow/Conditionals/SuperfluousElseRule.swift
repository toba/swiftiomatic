import SwiftBasicFormat
import SwiftSyntax

struct SuperfluousElseRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SuperfluousElseConfiguration()
}

extension SuperfluousElseRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension SuperfluousElseRule {}

extension SuperfluousElseRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: IfExprSyntax) {
      if let elseKeyword = node.superfluousElse {
        violations.append(elseKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override init(configuration: OptionsType, file: SwiftSource) {
      super.init(configuration: configuration, file: file)
      numberOfCorrections +=
        Visitor(configuration: configuration, file: file)
        .walk(file: file) { $0.violations.map(\.position) }
        .count(where: {
          !$0.isContainedIn(
            regions: disabledRegions,
            locationConverter: locationConverter,
          )
        })
    }

    override func visitAny(_ node: Syntax) -> Syntax? {
      numberOfCorrections == 0 ? node : nil  // Avoid skipping all `if` expressions in a code block.
    }

    override func visit(_ list: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
      var newStatements = CodeBlockItemListSyntax()
      var ifExprRewritten = false
      for item in list {
        guard
          let ifExpr = item.item.as(ExpressionStmtSyntax.self)?.expression
            .as(IfExprSyntax.self),
          let elseKeyword = ifExpr.superfluousElse,
          !elseKeyword.isContainedIn(
            regions: disabledRegions,
            locationConverter: locationConverter,
          )
        else {
          newStatements.append(item)
          continue
        }
        ifExprRewritten = true
        let (newIfStm, removedItems) = modify(ifExpr: ifExpr)
        newStatements.append(
          CodeBlockItemSyntax(
            item: CodeBlockItemSyntax.Item(ExpressionStmtSyntax(expression: newIfStm)),
          ),
        )
        newStatements.append(contentsOf: removedItems)
      }
      return ifExprRewritten ? visit(newStatements) : super.visit(newStatements)
    }

    private func modify(ifExpr: IfExprSyntax) -> (
      newIfExpr: IfExprSyntax, removedItems: [CodeBlockItemSyntax],
    ) {
      let ifExprWithoutElse = removeElse(from: ifExpr)
      if case .codeBlock(let block) = ifExpr.elseBody {
        let indenter = CodeIndentingRewriter(style: .unindentSpaces(4))
        let unindentedBlock = indenter.rewrite(block).cast(CodeBlockSyntax.self)
        let items = unindentedBlock.statements.with(
          \.trailingTrivia,
          unindentedBlock.rightBrace.leadingTrivia.withTrailingEmptyLineRemoved,
        )
        return (ifExprWithoutElse, Array(items))
      }
      if case .ifExpr(let nestedIfExpr) = ifExpr.elseBody {
        let unindentedIfExpr = nestedIfExpr.with(
          \.leadingTrivia,
          Trivia(
            pieces: [.newlines(1)]
              + (ifExpr.leadingTrivia.indentation(isOnNewline: true) ?? Trivia()),
          ),
        )
        let item = CodeBlockItemSyntax(
          item:
            CodeBlockItemSyntax
            .Item(ExpressionStmtSyntax(expression: unindentedIfExpr)),
        )
        return (ifExprWithoutElse, [item])
      }
      return (ifExpr, [])
    }

    private func removeElse(from ifExpr: IfExprSyntax) -> IfExprSyntax {
      ifExpr
        .with(
          \.body,
          ifExpr.body.with(
            \.rightBrace,
            ifExpr.body.rightBrace.with(\.trailingTrivia, Trivia()),
          ),
        )
        .with(\.elseKeyword, nil)
        .with(\.elseBody, nil)
    }
  }
}

extension IfExprSyntax {
  fileprivate var superfluousElse: TokenSyntax? {
    guard elseKeyword != nil,
      conditions.onlyElement?.condition.is(AvailabilityConditionSyntax.self) != true,
      lastStatementExitsScope(in: body)
    else {
      return nil
    }
    if let parent = parent?.as(IfExprSyntax.self) {
      return parent.superfluousElse != nil ? elseKeyword : nil
    }
    return elseKeyword
  }

  private var returnsInAllBranches: Bool {
    guard lastStatementExitsScope(in: body) else {
      return false
    }
    if case .ifExpr(let nestedIfExpr) = elseBody {
      return nestedIfExpr.returnsInAllBranches
    }
    if case .codeBlock(let block) = elseBody {
      return lastStatementExitsScope(in: block)
    }
    return false
  }

  private func lastStatementExitsScope(in block: CodeBlockSyntax) -> Bool {
    guard let lastItem = block.statements.last?.item else {
      return false
    }
    if [.returnStmt, .throwStmt, .continueStmt, .breakStmt].contains(lastItem.kind) {
      return true
    }
    if let exprStmt = lastItem.as(ExpressionStmtSyntax.self),
      let lastIfExpr = exprStmt.expression.as(IfExprSyntax.self)
    {
      return lastIfExpr.returnsInAllBranches
    }
    return false
  }
}
