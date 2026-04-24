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
