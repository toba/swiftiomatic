import SwiftiomaticSyntax

struct SpaceInsideBracketsRule {
  static let id = "space_inside_brackets"
  static let name = "Space Inside Brackets"
  static let summary = "There should be no spaces immediately inside square brackets"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("let a = [1, 2, 3]"),
      Example("let b = foo[0]"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("let a = [↓ 1, 2, 3 ]"),
      Example("let b = foo[↓ 0 ]"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("let a = [↓ 1, 2, 3 ]"): Example("let a = [1, 2, 3 ]")
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension SpaceInsideBracketsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension SpaceInsideBracketsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      switch token.tokenKind {
      case .leftSquare:
        // Check if trailing trivia has spaces (no linebreak means inline)
        if token.trailingTrivia.isHorizontalWhitespaceOnly {
          violations.append(token.endPositionBeforeTrailingTrivia)
        }
      case .rightSquare:
        // Check if leading trivia has only spaces (not preceded by linebreak or comment)
        if token.leadingTrivia.isHorizontalWhitespaceOnly {
          violations.append(token.positionAfterSkippingLeadingTrivia)
        }
      default:
        break
      }
      return .visitChildren
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
      switch token.tokenKind {
      case .leftSquare:
        if token.trailingTrivia.isHorizontalWhitespaceOnly {
          numberOfCorrections += 1
          return super.visit(token.with(\.trailingTrivia, Trivia()))
        }
      case .rightSquare:
        if token.leadingTrivia.isHorizontalWhitespaceOnly {
          numberOfCorrections += 1
          return super.visit(token.with(\.leadingTrivia, Trivia()))
        }
      default:
        break
      }
      return super.visit(token)
    }
  }
}
