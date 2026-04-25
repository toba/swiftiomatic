@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

// MARK: - Inline Mode Tests

@Suite
struct NestedCallLayoutInlineTests: RuleTesting {

  private var inlineConfig: Configuration {
    var config = Configuration.forTesting(enabledRule: NestedCallLayout.key)
    config[NestedCallLayout.self] = {
      var c = NestedCallLayoutConfiguration()
      c.mode = .inline
      return c
    }()
    return config
  }

  @Test func fullyNestedCollapsesToOneLine() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        result = 1️⃣ExprSyntax(
            ForceUnwrapExprSyntax(
                expression: result,
                trailingTrivia: trivia
            )
        )
        """,
      expected: """
        result = ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse nested call to fit on one line"),
      ],
      configuration: inlineConfig)
  }

  @Test func alreadyInlineUnchanged() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        result = ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))
        """,
      expected: """
        result = ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))
        """,
      configuration: inlineConfig)
  }

  @Test func tooLongForOneLineUsesOuterInlineInnerWrapped() {
    var config = inlineConfig
    config[LineLength.self] = 60

    assertFormatting(
      NestedCallLayout.self,
      input: """
        result = 1️⃣ExprSyntax(
            ForceUnwrapExprSyntax(
                expression: result,
                trailingTrivia: trivia
            )
        )
        """,
      expected: """
        result = ExprSyntax(ForceUnwrapExprSyntax(
            expression: result,
            trailingTrivia: trivia
        ))
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse nested call to fit on one line"),
      ],
      configuration: config)
  }

  @Test func tooLongForOuterInlineUsesFullyWrapped() {
    // Strategy 3: linePrefix (16) + outerPrefix (24) = 40 > 35 (strategy 2 fails),
    // but baseIndent (0) + indent (4) + innerInline (18) = 22 <= 35 (strategy 3 fits).
    var config = inlineConfig
    config[LineLength.self] = 35

    assertFormatting(
      NestedCallLayout.self,
      input: """
        someVariable = 1️⃣VeryLongOuterName(
            Short(
                a: 1,
                b: 2
            )
        )
        """,
      expected: """
        someVariable = VeryLongOuterName(
            Short(a: 1, b: 2)
        )
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse nested call to fit on one line"),
      ],
      configuration: config)
  }

  @Test func labelWidthIncludedInStrategySelection() {
    // "let x = " = 8 chars column offset.
    // buildFullyInlineText = "Outer(Inner(value: 1))" = 22 chars (no label).
    // Actual with label    = "Outer(label: Inner(value: 1))" = 29 chars.
    // 8 + 22 = 30 <= 35 — Strategy 1 chosen without label accounting.
    // 8 + 29 = 37 > 35  — Strategy 1 should NOT be chosen.
    // Strategy 2 prefix with label = "Outer(label: Inner(" = 20 + 8 = 28 <= 35, fits.
    var config = inlineConfig
    config[LineLength.self] = 35

    assertFormatting(
      NestedCallLayout.self,
      input: """
        let x = 1️⃣Outer(
            label: Inner(
                value: 1
            )
        )
        """,
      expected: """
        let x = Outer(label: Inner(
            value: 1
        ))
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse nested call to fit on one line"),
      ],
      configuration: config)
  }

  @Test func nothingFitsStaysFullyNested() {
    var config = inlineConfig
    config[LineLength.self] = 30

    assertFormatting(
      NestedCallLayout.self,
      input: """
        result = ExprSyntax(
            ForceUnwrapExprSyntax(
                expression: result,
                trailingTrivia: trivia
            )
        )
        """,
      expected: """
        result = ExprSyntax(
            ForceUnwrapExprSyntax(
                expression: result,
                trailingTrivia: trivia
            )
        )
        """,
      configuration: config)
  }

  @Test func indentedContextCollapsesCorrectly() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        do {
            result = 1️⃣ExprSyntax(
                ForceUnwrapExprSyntax(
                    expression: result,
                    trailingTrivia: trivia
                )
            )
        }
        """,
      expected: """
        do {
            result = ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse nested call to fit on one line"),
      ],
      configuration: inlineConfig)
  }

  @Test func innerCallWithTrailingClosureNotCollapsed() {
    // Regression: NestedCallLayout previously rebuilt nested calls using only
    // `arguments`, silently deleting `trailingClosure` bodies. The rule must
    // bail on calls that carry a trailing closure since the rebuild paths
    // don't preserve them.
    let input = """
      let x = MemberBlockItemListSyntax(
          items.map { item in
              return item
          })
      """
    assertFormatting(
      NestedCallLayout.self,
      input: input,
      expected: input,
      configuration: inlineConfig)
  }

  @Test func outerCallWithTrailingClosureNotCollapsed() {
    let input = """
      let x = Foo(
          Bar()
      ) { result in
          handle(result)
      }
      """
    assertFormatting(
      NestedCallLayout.self,
      input: input,
      expected: input,
      configuration: inlineConfig)
  }

  @Test func nonNestedCallUnchanged() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        let x = foo(
            bar: 1,
            baz: 2
        )
        """,
      expected: """
        let x = foo(
            bar: 1,
            baz: 2
        )
        """,
      configuration: inlineConfig)
  }

  @Test func labeledOuterArgumentPreservesLabelFullyInline() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        let x = 1️⃣Outer(
            label: Inner(
                value: 1
            )
        )
        """,
      expected: """
        let x = Outer(label: Inner(value: 1))
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse nested call to fit on one line"),
      ],
      configuration: inlineConfig)
  }

  @Test func labeledOuterArgumentPreservesLabelStrategy2() {
    // Fully inline ≈ 113 chars (> 100), so Strategy 1 doesn't fit.
    // Strategy 2 prefix "let x = IdentifierTypeSyntax(name: TokenSyntax(" = 48 chars, fits.
    assertFormatting(
      NestedCallLayout.self,
      input: """
        let x = 1️⃣IdentifierTypeSyntax(
            name: TokenSyntax(
                .identifier("Entry"),
                trailingTrivia: .space,
                presence: .present
            )
        )
        """,
      expected: """
        let x = IdentifierTypeSyntax(name: TokenSyntax(
            .identifier("Entry"),
            trailingTrivia: .space,
            presence: .present
        ))
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse nested call to fit on one line"),
      ],
      configuration: inlineConfig)
  }

  @Test func tripleNestedCollapsesInward() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        let x = 1️⃣A(
            B(
                C(
                    value: 1
                )
            )
        )
        """,
      expected: """
        let x = A(B(C(value: 1)))
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse nested call to fit on one line"),
      ],
      configuration: inlineConfig)
  }

  @Test func hugsMultilineChainArgument() {
    // Issue enu-4zl: outer call's sole arg is a multi-line method chain.
    // The opening paren should hug the chain's first token, and the chain
    // should be re-indented to baseIndent + indentUnit.
    assertFormatting(
      NestedCallLayout.self,
      input: """
        return 1️⃣.init(
                    tryNode
                        .with(\\.questionOrExclamationMark, nil)
                        .with(\\.tryKeyword, tryNode.tryKeyword.with(\\.trailingTrivia, bangTrailingTrivia))
                )
        """,
      expected: """
        return .init(tryNode
            .with(\\.questionOrExclamationMark, nil)
            .with(\\.tryKeyword, tryNode.tryKeyword.with(\\.trailingTrivia, bangTrailingTrivia))
        )
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse nested call to fit on one line"),
      ],
      configuration: inlineConfig)
  }

  @Test func hugsMultilineNestedCallArgument() {
    // Issue enu-4zl: outer call's sole arg is a multi-line nested call whose
    // own args don't fit on one line. The inner call should be hugged to the
    // opening paren and its content re-indented.
    assertFormatting(
      NestedCallLayout.self,
      input: """
        return 1️⃣ExprSyntax(
                                OptionalChainingExprSyntax(
                                    expression: typedNode.expression,
                                    questionMark: .postfixQuestionMarkToken(
                                        leadingTrivia: typedNode.exclamationMark.leadingTrivia,
                                        trailingTrivia: typedNode.exclamationMark.trailingTrivia
                                    )
                                ))
        """,
      expected: """
        return ExprSyntax(OptionalChainingExprSyntax(
            expression: typedNode.expression,
            questionMark: .postfixQuestionMarkToken(
                leadingTrivia: typedNode.exclamationMark.leadingTrivia,
                trailingTrivia: typedNode.exclamationMark.trailingTrivia
            )
        ))
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse nested call to fit on one line"),
      ],
      configuration: inlineConfig)
  }

  @Test func hugsMultilineNestedCallWithDeepContent() {
    // Issue enu-4zl: outer call's sole arg is a multi-line call with deeply
    // nested content (collections, etc.). All inner content should re-indent
    // proportionally so relative structure is preserved.
    assertFormatting(
      NestedCallLayout.self,
      input: """
        1️⃣ExprSyntax(
                        MacroExpansionExprSyntax(
                            pound: .poundToken(),
                            macroName: .identifier("require"),
                            leftParen: .leftParenToken(),
                            arguments: LabeledExprListSyntax([
                                LabeledExprSyntax(expression: innerExpr)
                            ]),
                            rightParen: .rightParenToken(trailingTrivia: trailingTrivia)
                        ))
        """,
      expected: """
        ExprSyntax(MacroExpansionExprSyntax(
            pound: .poundToken(),
            macroName: .identifier("require"),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax([
                LabeledExprSyntax(expression: innerExpr)
            ]),
            rightParen: .rightParenToken(trailingTrivia: trailingTrivia)
        ))
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse nested call to fit on one line"),
      ],
      configuration: inlineConfig)
  }
}

// MARK: - Wrap Mode Tests

@Suite
struct NestedCallLayoutWrapTests: RuleTesting {

  private var wrapConfig: Configuration {
    var config = Configuration.forTesting(enabledRule: NestedCallLayout.key)
    config[NestedCallLayout.self] = {
      var c = NestedCallLayoutConfiguration()
      c.mode = .wrap
      return c
    }()
    return config
  }

  @Test func fullyInlineExpandsToNested() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        result = 1️⃣ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))
        """,
      expected: """
        result = ExprSyntax(
            ForceUnwrapExprSyntax(
                expression: result,
                trailingTrivia: trivia
            )
        )
        """,
      findings: [
        FindingSpec("1️⃣", message: "expand nested call onto separate lines"),
      ],
      configuration: wrapConfig)
  }

  @Test func outerInlineInnerWrappedExpands() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        result = 1️⃣ExprSyntax(ForceUnwrapExprSyntax(
            expression: result,
            trailingTrivia: trivia
        ))
        """,
      expected: """
        result = ExprSyntax(
            ForceUnwrapExprSyntax(
                expression: result,
                trailingTrivia: trivia
            )
        )
        """,
      findings: [
        FindingSpec("1️⃣", message: "expand nested call onto separate lines"),
      ],
      configuration: wrapConfig)
  }

  @Test func fullyWrappedExpands() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        result = 1️⃣ExprSyntax(
            ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia)
        )
        """,
      expected: """
        result = ExprSyntax(
            ForceUnwrapExprSyntax(
                expression: result,
                trailingTrivia: trivia
            )
        )
        """,
      findings: [
        FindingSpec("1️⃣", message: "expand nested call onto separate lines"),
      ],
      configuration: wrapConfig)
  }

  @Test func alreadyFullyNestedUnchanged() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        result = ExprSyntax(
            ForceUnwrapExprSyntax(
                expression: result,
                trailingTrivia: trivia
            )
        )
        """,
      expected: """
        result = ExprSyntax(
            ForceUnwrapExprSyntax(
                expression: result,
                trailingTrivia: trivia
            )
        )
        """,
      configuration: wrapConfig)
  }

  @Test func labeledOuterArgumentPreservesLabelOnExpand() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        let x = 1️⃣Outer(label: Inner(value: 1))
        """,
      expected: """
        let x = Outer(
            label: Inner(
                value: 1
            )
        )
        """,
      findings: [
        FindingSpec("1️⃣", message: "expand nested call onto separate lines"),
      ],
      configuration: wrapConfig)
  }

  @Test func nonNestedCallUnchanged() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        let x = foo(bar: 1, baz: 2)
        """,
      expected: """
        let x = foo(bar: 1, baz: 2)
        """,
      configuration: wrapConfig)
  }

  @Test func indentedContextExpands() {
    assertFormatting(
      NestedCallLayout.self,
      input: """
        func test() {
            result = 1️⃣ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))
        }
        """,
      expected: """
        func test() {
            result = ExprSyntax(
                ForceUnwrapExprSyntax(
                    expression: result,
                    trailingTrivia: trivia
                )
            )
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "expand nested call onto separate lines"),
      ],
      configuration: wrapConfig)
  }
}
