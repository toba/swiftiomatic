import SwiftSyntax

struct TrailingClosureRule {
    private static let onlySingleMutedConfig = ["only_single_muted_parameter": true]
    static let id = "trailing_closure"
    static let name = "Trailing Closure"
    static let summary = "Trailing closure syntax should be used whenever possible"
    static let isCorrectable = true
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("foo.map { $0 + 1 }"),
              Example("foo.bar()"),
              Example("foo.reduce(0) { $0 + 1 }"),
              Example("if let foo = bar.map({ $0 + 1 }) { }"),
              Example("foo.something(param1: { $0 }, param2: { $0 + 1 })"),
              Example("offsets.sorted { $0.offset < $1.offset }"),
              Example("foo.something({ return 1 }())"),
              Example("foo.something({ return $0 }(1))"),
              Example("foo.something(0, { return 1 }())"),
              Example("for x in list.filter({ $0.isValid }) {}"),
              Example("if list.allSatisfy({ $0.isValid }) {}"),
              Example("foo(param1: 1, param2: { _ in true }, param3: 0)"),
              Example("foo(param1: 1, param2: { _ in true }) { $0 + 1 }"),
              Example("foo(param1: { _ in false }, param2: { _ in true })"),
              Example("foo(param1: { _ in false }, param2: { _ in true }, param3: { _ in false })"),
              Example(
                """
                if f({ true }), g({ true }) {
                    print("Hello")
                }
                """,
              ),
              Example(
                """
                for i in h({ [1,2,3] }) {
                    print(i)
                }
                """,
              ),
              Example("foo.reduce(0, combine: { $0 + 1 })", configuration: Self.onlySingleMutedConfig),
              Example(
                "offsets.sorted(by: { $0.offset < $1.offset })",
                configuration: Self.onlySingleMutedConfig,
              ),
              Example("foo.something(0, { $0 + 1 })", configuration: Self.onlySingleMutedConfig),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("foo.map(↓{ $0 + 1 })"),
              Example("foo.reduce(0, combine: ↓{ $0 + 1 })"),
              Example("offsets.sorted(by: ↓{ $0.offset < $1.offset })"),
              Example("foo.something(0, ↓{ $0 + 1 })"),
              Example("foo.something(param1: { _ in true }, param2: 0, param3: ↓{ _ in false })"),
              Example(
                """
                for n in list {
                    n.forEach(↓{ print($0) })
                }
                """, isExcludedFromDocumentation: true,
              ),
              Example("foo.map(↓{ $0 + 1 })", configuration: Self.onlySingleMutedConfig),
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example("foo.map(↓{ $0 + 1 })"):
                Example("foo.map { $0 + 1 }"),
              Example("foo.reduce(0, combine: ↓{ $0 + 1 })"):
                Example("foo.reduce(0) { $0 + 1 }"),
              Example("offsets.sorted(by: ↓{ $0.offset < $1.offset })"):
                Example("offsets.sorted { $0.offset < $1.offset }"),
              Example("foo.something(0, ↓{ $0 + 1 })"):
                Example("foo.something(0) { $0 + 1 }"),
              Example("foo.something(param1: { _ in true }, param2: 0, param3: ↓{ _ in false })"):
                Example("foo.something(param1: { _ in true }, param2: 0) { _ in false }"),
              Example("f(a: ↓{ g(b: ↓{ 1 }) })"):
                Example("f { g { 1 }}"),
              Example(
                """
                for n in list {
                    n.forEach(↓{ print($0) })
                }
                """,
              ): Example(
                """
                for n in list {
                    n.forEach { print($0) }
                }
                """,
              ),
              Example(
                """
                f(a: 1,
                b: 2,
                c: { 3 })
                """,
              ): Example(
                """
                f(a: 1,
                b: 2) { 3 }
                """,
              ),
              Example("foo.map(↓{ $0 + 1 })", configuration: Self.onlySingleMutedConfig):
                Example("foo.map { $0 + 1 }", configuration: Self.onlySingleMutedConfig),
              Example("f(↓{ g(↓{ 1 }) })", configuration: Self.onlySingleMutedConfig):
                Example("f { g { 1 }}", configuration: Self.onlySingleMutedConfig),
              Example(
                """
                for n in list {
                    n.forEach(↓{ print($0) })
                }
                """, configuration: Self.onlySingleMutedConfig,
              ): Example(
                """
                for n in list {
                    n.forEach { print($0) }
                }
                """,
              ),
              Example(
                """
                f(a: 1, // comment
                b: 2, /* comment */ c: { 3 })
                """,
              ): Example(
                """
                f(a: 1, // comment
                b: 2) /* comment */ { 3 }
                """,
              ),
              Example(
                """
                f(a: 2, c: /* comment */ { 3 } /* comment */)
                """,
              ): Example(
                """
                f(a: 2) /* comment */ { 3 } /* comment */
                """,
              ),
              Example(
                """
                f(a: 2, /* comment */ c /* comment */ : /* comment */ { 3 } /* comment */)
                """,
              ): Example(
                """
                f(a: 2) /* comment */ { 3 } /* comment */
                """,
              ),
              Example(
                """
                f(a: 2, /* comment1 */ c /* comment2 */ : /* comment3 */ { 3 } /* comment4 */)
                """,
              ): Example(
                """
                f(a: 2) /* comment1 */ /* comment2 */ /* comment3 */ { 3 } /* comment4 */
                """,
              ),
              Example(
                """
                let dataSource = RxTableViewSectionedReloadDataSource(
                    configureCell: { cell in // sm:disable:this trailing_closure
                        return cell
                    }
                )
                """,
              ): Example(
                """
                let dataSource = RxTableViewSectionedReloadDataSource(
                    configureCell: { cell in // sm:disable:this trailing_closure
                        return cell
                    }
                )
                """,
              ),
            ]
    }
  var options = TrailingClosureOptions()

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
