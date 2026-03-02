import SwiftSyntax

struct NoEmptyBlockRule {
  var options = NoEmptyBlockOptions()

  static let configuration = NoEmptyBlockConfiguration()
}

extension NoEmptyBlockRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NoEmptyBlockRule {}

extension NoEmptyBlockRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: CodeBlockSyntax) {
      if let codeBlockType = node.codeBlockType,
        configuration.enabledBlockTypes.contains(codeBlockType)
      {
        validate(node: node)
      }
    }

    override func visitPost(_ node: ClosureExprSyntax) {
      if configuration.enabledBlockTypes.contains(.closureBlocks),
        node.signature?.inKeyword.trailingTrivia.containsComments != true
      {
        validate(node: node)
      }
    }

    func validate(node: some BracedSyntax & WithStatementsSyntax) {
      guard node.statements.isEmpty,
        !node.leftBrace.trailingTrivia.containsComments,
        !node.rightBrace.leadingTrivia.containsComments
      else {
        return
      }
      violations.append(node.leftBrace.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension CodeBlockSyntax {
  fileprivate var codeBlockType: NoEmptyBlockOptions.CodeBlockType? {
    switch parent?.kind {
    case .functionDecl, .accessorDecl:
      .functionBodies
    case .initializerDecl, .deinitializerDecl:
      .initializerBodies
    case .forStmt, .doStmt, .whileStmt, .repeatStmt, .ifExpr, .catchClause, .deferStmt:
      .statementBlocks
    case .closureExpr:
      .closureBlocks
    case .guardStmt:
      // No need to handle this case since Empty Block of `guard` is compile error.
      nil
    default:
      nil
    }
  }
}
