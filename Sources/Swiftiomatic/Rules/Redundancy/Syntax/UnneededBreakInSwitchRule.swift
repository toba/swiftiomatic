import SwiftBasicFormat
import SwiftSyntax

struct UnneededBreakInSwitchRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = UnneededBreakInSwitchConfiguration()
}

extension UnneededBreakInSwitchRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension UnneededBreakInSwitchRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SwitchCaseSyntax) {
      guard let statement = node.unneededBreak else {
        return
      }
      violations.append(statement.item.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
      let stmts = CodeBlockItemListSyntax(node.statements.dropLast())
      guard let breakStatement = node.unneededBreak, let secondLast = stmts.last else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let trivia = breakStatement.item.leadingTrivia + breakStatement.item.trailingTrivia
      let newNode =
        node
        .with(\.statements, stmts)
        .with(\.statements.trailingTrivia, secondLast.item.trailingTrivia + trivia)
        .trimmed { !$0.isComment }
        .formatted()
        .as(SwitchCaseSyntax.self)!
      return super.visit(newNode)
    }
  }
}

extension SwitchCaseSyntax {
  fileprivate var unneededBreak: CodeBlockItemSyntax? {
    guard statements.count > 1,
      let breakStatement = statements.last?.item.as(BreakStmtSyntax.self),
      breakStatement.label == nil
    else {
      return nil
    }
    return statements.last
  }
}

extension TriviaPiece {
  fileprivate var isComment: Bool {
    switch self {
    case .lineComment, .blockComment, .docLineComment, .docBlockComment:
      return true
    default:
      return false
    }
  }
}
