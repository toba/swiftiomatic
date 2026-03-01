import SwiftSyntax

struct SpaceAroundGenericsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SpaceAroundGenericsConfiguration()

  static let description = RuleDescription(
    identifier: "space_around_generics",
    name: "Space Around Generics",
    description: "There should be no space between an identifier and opening angle bracket",
    scope: .format,
    nonTriggeringExamples: [
      Example("let a: Array<Int> = []"),
      Example("func foo<T>() {}"),
      Example("class Foo<T> {}"),
    ],
    triggeringExamples: [
      Example("let a: Array↓ <Int> = []"),
      Example("func foo↓ <T>() {}"),
    ],
    corrections: [
      Example("let a: Array↓ <Int> = []"): Example("let a: Array<Int> = []")
    ],
  )
}

extension SpaceAroundGenericsRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension SpaceAroundGenericsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
      guard token.tokenKind == .leftAngle else { return .visitChildren }

      // Check if preceded by a space after an identifier
      guard let prevToken = token.previousToken(viewMode: .sourceAccurate),
        prevToken.tokenKind.isIdentifierOrKeyword
      else { return .visitChildren }

      if prevToken.trailingTrivia.containsHorizontalWhitespace {
        violations.append(prevToken.endPositionBeforeTrailingTrivia)
      }
      return .visitChildren
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
      guard token.tokenKind == .leftAngle else { return super.visit(token) }
      guard let prevToken = token.previousToken(viewMode: .sourceAccurate),
        prevToken.tokenKind.isIdentifierOrKeyword
      else { return super.visit(token) }

      if token.leadingTrivia.containsHorizontalWhitespace {
        numberOfCorrections += 1
        return super.visit(token.with(\.leadingTrivia, Trivia()))
      }
      return super.visit(token)
    }
  }
}

extension TokenKind {
  fileprivate var isIdentifierOrKeyword: Bool {
    switch self {
    case .identifier: true
    case .keyword: true
    default: false
    }
  }
}
