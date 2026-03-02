import SwiftSyntax

struct ClosureSpacingRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ClosureSpacingConfiguration()
}

extension ClosureSpacingRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension ClosureSpacingRule {}

extension ClosureSpacingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClosureExprSyntax) {
      if node.shouldCheckForClosureSpacingRule(locationConverter: locationConverter),
        node.violations.hasViolations
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
      var node = node
      node.statements = visit(node.statements)

      guard node.shouldCheckForClosureSpacingRule(locationConverter: locationConverter) else {
        return super.visit(node)
      }

      let violations = node.violations
      if violations.leftBraceLeftSpace {
        node.leftBrace = node.leftBrace.with(\.leadingTrivia, .spaces(1))
      }
      if violations.leftBraceRightSpace {
        node.leftBrace = node.leftBrace.with(\.trailingTrivia, .spaces(1))
      }
      if violations.rightBraceLeftSpace {
        node.rightBrace = node.rightBrace.with(\.leadingTrivia, .spaces(1))
      }
      if violations.rightBraceRightSpace {
        node.rightBrace = node.rightBrace.with(\.trailingTrivia, .spaces(1))
      }
      if violations.hasViolations {
        numberOfCorrections += 1
      }
      return super.visit(node)
    }
  }
}

// MARK: - Private Helpers

private struct ClosureSpacingRuleClosureViolations {
  let leftBraceLeftSpace: Bool
  let leftBraceRightSpace: Bool
  let rightBraceLeftSpace: Bool
  let rightBraceRightSpace: Bool

  var hasViolations: Bool {
    leftBraceLeftSpace || leftBraceRightSpace || rightBraceLeftSpace || rightBraceRightSpace
  }
}

extension ClosureExprSyntax {
  fileprivate var violations: ClosureSpacingRuleClosureViolations {
    ClosureSpacingRuleClosureViolations(
      leftBraceLeftSpace: !leftBrace.hasSingleSpaceToItsLeft
        && !leftBrace.hasAllowedNoSpaceLeftToken && !leftBrace.hasLeadingNewline,
      leftBraceRightSpace: !leftBrace.hasSingleSpaceToItsRight,
      rightBraceLeftSpace: !rightBrace.hasSingleSpaceToItsLeft,
      rightBraceRightSpace: !rightBrace.hasSingleSpaceToItsRight
        && !rightBrace.hasAllowedNoSpaceRightToken && !rightBrace.hasTrailingLineComment,
    )
  }

  fileprivate func shouldCheckForClosureSpacingRule(locationConverter: SourceLocationConverter)
    -> Bool
  {
    guard parent?.is(PostfixOperatorExprSyntax.self) == false,  // Workaround for Regex literals
      (rightBrace.position.utf8Offset - leftBrace.position.utf8Offset) > 1,  // Allow '{}'
      case let startLine = startLocation(converter: locationConverter).line,
      case let endLine = endLocation(converter: locationConverter).line,
      startLine == endLine  // Only check single-line closures
    else {
      return false
    }

    return true
  }
}

extension TokenSyntax {
  fileprivate var hasSingleSpaceToItsLeft: Bool {
    if case .spaces(1) = Array(leadingTrivia).last {
      return true
    }
    if let previousToken = previousToken(viewMode: .sourceAccurate),
      case .spaces(1) = Array(previousToken.trailingTrivia).last
    {
      return true
    }
    return false
  }

  fileprivate var hasSingleSpaceToItsRight: Bool {
    if case .spaces(1) = trailingTrivia.first {
      return true
    }
    if let nextToken = nextToken(viewMode: .sourceAccurate),
      case .spaces(1) = nextToken.leadingTrivia.first
    {
      return true
    }
    return false
  }

  fileprivate var hasLeadingNewline: Bool {
    leadingTrivia.contains { piece in
      if case .newlines = piece {
        return true
      }
      return false
    }
  }

  fileprivate var hasTrailingLineComment: Bool {
    trailingTrivia.contains { piece in
      if case .lineComment = piece {
        return true
      }
      return false
    }
  }

  fileprivate var hasAllowedNoSpaceLeftToken: Bool {
    let previousTokenKind = parent?.previousToken(viewMode: .sourceAccurate)?.tokenKind
    return previousTokenKind == .leftParen || previousTokenKind == .leftSquare
  }

  fileprivate var hasAllowedNoSpaceRightToken: Bool {
    let allowedKinds = [
      TokenKind.colon,
      .comma,
      .endOfFile,
      .exclamationMark,
      .leftParen,
      .leftSquare,
      .period,
      .postfixQuestionMark,
      .rightParen,
      .rightSquare,
      .semicolon,
    ]
    if case .newlines = trailingTrivia.first {
      return true
    }
    if case .newlines = nextToken(viewMode: .sourceAccurate)?.leadingTrivia.first {
      return true
    }
    if let nextToken = nextToken(viewMode: .sourceAccurate),
      allowedKinds.contains(nextToken.tokenKind)
    {
      return true
    }
    return false
  }
}
