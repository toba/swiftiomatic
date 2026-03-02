import SwiftSyntax

struct TrailingClosureRule {
  var options = TrailingClosureOptions()

  static let configuration = TrailingClosureConfiguration()
}

extension TrailingClosureRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension TrailingClosureRule {}

extension TrailingClosureRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard node.trailingClosure == nil else {
        return
      }

      if configuration.onlySingleMutedParameter {
        if let param = node.singleMutedClosureParameter {
          violations.append(param.positionAfterSkippingLeadingTrivia)
        }
      } else if let param = node.lastDistinctClosureParameter {
        violations.append(param.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visit(_: ConditionElementListSyntax) -> SyntaxVisitorContinueKind {
      .skipChildren
    }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
      walk(node.body)
      return .skipChildren
    }
  }
}

extension TrailingClosureRule {
  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard node.trailingClosure == nil else {
        return super.visit(node)
      }

      if configuration.onlySingleMutedParameter {
        if let param = node.singleMutedClosureParameter,
          !isDisabled(atStartPositionOf: param),
          let converted = node.convertToTrailingClosure()
        {
          numberOfCorrections += 1
          return super.visit(converted)
        }
      } else if let param = node.lastDistinctClosureParameter,
        !isDisabled(atStartPositionOf: param),
        let converted = node.convertToTrailingClosure()
      {
        numberOfCorrections += 1
        return super.visit(converted)
      }
      return super.visit(node)
    }

    override func visit(_ node: ConditionElementListSyntax) -> ConditionElementListSyntax {
      node
    }

    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
      if let body = rewrite(node.body).as(CodeBlockSyntax.self) {
        StmtSyntax(node.with(\.body, body))
      } else {
        StmtSyntax(node)
      }
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var singleMutedClosureParameter: ClosureExprSyntax? {
    if let onlyArgument = arguments.onlyElement, onlyArgument.label == nil {
      return onlyArgument.expression.as(ClosureExprSyntax.self)
    }
    return nil
  }

  fileprivate var lastDistinctClosureParameter: ClosureExprSyntax? {
    // If at least the last two (connected) arguments were ClosureExprSyntax, a violation should not be triggered.
    guard arguments.count > 1,
      arguments.dropFirst(arguments.count - 2).allSatisfy(\.isClosureExpr)
    else {
      return arguments.last?.expression.as(ClosureExprSyntax.self)
    }
    return nil
  }

  fileprivate func dropLastArgument() -> Self {
    with(\.arguments, LabeledExprListSyntax(arguments.dropLast()).dropLastTrailingComma())
      .dropParensIfEmpty()
  }

  fileprivate func dropParensIfEmpty() -> Self {
    if arguments.isEmpty {
      with(\.rightParen, nil)
        .with(\.leftParen, nil)
    } else {
      self
    }
  }

  fileprivate func convertToTrailingClosure() -> Self? {
    guard let lastDistinctClosureParameter else {
      return nil
    }
    let leadingTrivia =
      lastTriviaInArguments?
      .removingLeadingNewlines()
      .appendingMissingSpace() ?? []

    return dropLastArgument()
      .with(
        \.trailingClosure,
        lastDistinctClosureParameter.with(\.leadingTrivia, leadingTrivia),
      )
      .with(\.calledExpression.trailingTrivia, [])
  }

  fileprivate var lastTriviaInArguments: Trivia? {
    guard let lastArgument = arguments.last,
      let previous = lastArgument.previousToken(viewMode: .sourceAccurate)?.trailingTrivia
    else { return nil }

    return
      previous
      .merging(lastArgument.leadingTrivia)
      .merging(triviaOf: lastArgument.label)
      .merging(triviaOf: lastArgument.colon)
  }
}

extension LabeledExprSyntax {
  fileprivate var isClosureExpr: Bool {
    expression.is(ClosureExprSyntax.self)
  }
}

extension LabeledExprListSyntax {
  fileprivate func dropLastTrailingComma() -> Self {
    guard let last else { return [] }

    if last.trailingComma == nil {
      return self
    }
    return LabeledExprListSyntax(dropLast()) + CollectionOfOne(last.with(\.trailingComma, nil))
  }
}

extension Trivia {
  fileprivate var endsWithSpace: Bool {
    if case .spaces = pieces.last {
      return true
    }
    return false
  }

  fileprivate var startsWithNewline: Bool {
    first?.isNewline == true
  }

  fileprivate func appendingMissingSpace() -> Self {
    if endsWithSpace {
      self
    } else {
      merging(.space)
    }
  }

  fileprivate func removingLeadingNewlines() -> Self {
    if startsWithNewline {
      Trivia(pieces: pieces.drop(while: \.isNewline))
    } else {
      self
    }
  }
}
