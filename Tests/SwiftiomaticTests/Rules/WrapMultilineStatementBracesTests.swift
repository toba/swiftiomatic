@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapMultilineStatementBracesTests: RuleTesting {

  // MARK: - If statements

  @Test func multilineIfBraceOnNextLine() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        if firstConditional,
           array.contains(where: { secondConditional }) 1️⃣{
            print("statement body")
        }
        """,
      expected: """
        if firstConditional,
           array.contains(where: { secondConditional })
        {
            print("statement body")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "move opening brace to its own line for multiline statement")])
  }

  @Test func singleLineIfBraceNotWrapped() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        if firstConditional {
            print("statement body")
        }
        """,
      expected: """
        if firstConditional {
            print("statement body")
        }
        """)
  }

  @Test func innerMultilineIfBraceOnNextLine() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        if outerConditional {
            if firstConditional,
               array.contains(where: { secondConditional }) 1️⃣{
                print("statement body")
            }
        }
        """,
      expected: """
        if outerConditional {
            if firstConditional,
               array.contains(where: { secondConditional })
            {
                print("statement body")
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "move opening brace to its own line for multiline statement")])
  }

  @Test func multilineIfBraceAlreadyWrapped() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        if firstConditional,
           secondConditional
        {
            print("body")
        }
        """,
      expected: """
        if firstConditional,
           secondConditional
        {
            print("body")
        }
        """)
  }

  // MARK: - Guard statements

  @Test func multilineGuardBraceOnNextLine() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        guard firstConditional,
              array.contains(where: { secondConditional }) else 1️⃣{
            print("statement body")
        }
        """,
      expected: """
        guard firstConditional,
              array.contains(where: { secondConditional }) else
        {
            print("statement body")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "move opening brace to its own line for multiline statement")])
  }

  @Test func singleLineGuardBraceNotWrapped() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        guard firstConditional else {
            print("statement body")
        }
        """,
      expected: """
        guard firstConditional else {
            print("statement body")
        }
        """)
  }

  @Test func guardElseOnOwnLineBraceNotWrapped() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        guard let foo = bar,
              bar == baz
        else {
            print("statement body")
        }
        """,
      expected: """
        guard let foo = bar,
              bar == baz
        else {
            print("statement body")
        }
        """)
  }

  // MARK: - For loops

  @Test func multilineForLoopBraceOnNextLine() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        for foo in
            [1, 2] 1️⃣{
            print(foo)
        }
        """,
      expected: """
        for foo in
            [1, 2]
        {
            print(foo)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "move opening brace to its own line for multiline statement")])
  }

  @Test func multilineForWhereLoopBraceOnNextLine() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        for foo in bar
            where foo != baz 1️⃣{
            print(foo)
        }
        """,
      expected: """
        for foo in bar
            where foo != baz
        {
            print(foo)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "move opening brace to its own line for multiline statement")])
  }

  @Test func multilineForLoopWithArrayLiteralNotWrapped() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        for foo in [
            1,
            2,
        ] {
            print(foo)
        }
        """,
      expected: """
        for foo in [
            1,
            2,
        ] {
            print(foo)
        }
        """)
  }

  // MARK: - Functions

  @Test func multilineFuncBraceOnNextLine() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        func method(
            foo: Int,
            bar: Int) 1️⃣{
            print("function body")
        }
        """,
      expected: """
        func method(
            foo: Int,
            bar: Int)
        {
            print("function body")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "move opening brace to its own line for multiline statement")])
  }

  @Test func multilineInitBraceOnNextLine() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        init(foo: Int,
             bar: Int) 1️⃣{
            print("function body")
        }
        """,
      expected: """
        init(foo: Int,
             bar: Int)
        {
            print("function body")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "move opening brace to its own line for multiline statement")])
  }

  // MARK: - Type declarations

  @Test func multilineClassBraceAlreadyWrapped() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        class Foo: BarProtocol,
            BazProtocol
        {
            init() {}
        }
        """,
      expected: """
        class Foo: BarProtocol,
            BazProtocol
        {
            init() {}
        }
        """)
  }

  @Test func multilineClassBraceWraps() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        class Foo: BarProtocol,
            BazProtocol 1️⃣{
            init() {}
        }
        """,
      expected: """
        class Foo: BarProtocol,
            BazProtocol
        {
            init() {}
        }
        """,
      findings: [FindingSpec("1️⃣", message: "move opening brace to its own line for multiline statement")])
  }

  // MARK: - Single-line bodies

  @Test func multilineGuardSingleLineBodyNotWrapped() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        guard let foo = bar,
              let baz = quux else { return }
        """,
      expected: """
        guard let foo = bar,
              let baz = quux else { return }
        """)
  }

  // MARK: - Extension and protocol declarations

  @Test func multilineExtensionBraceWraps() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        extension Foo: BarProtocol,
            BazProtocol 1️⃣{
            func bar() {}
        }
        """,
      expected: """
        extension Foo: BarProtocol,
            BazProtocol
        {
            func bar() {}
        }
        """,
      findings: [FindingSpec("1️⃣", message: "move opening brace to its own line for multiline statement")])
  }

  // MARK: - Closures should not be wrapped

  @Test func multilineIfWithClosureConditionNotWrappingInnerClosure() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        if let object = Object([
            foo,
            bar,
        ]) {
            print("statement body")
        }
        """,
      expected: """
        if let object = Object([
            foo,
            bar,
        ]) {
            print("statement body")
        }
        """)
  }

  // MARK: - Function with return type

  @Test func multilineFuncWithReturnTypeBraceWraps() {
    assertFormatting(
      WrapMultilineStatementBraces.self,
      input: """
        func method(
            foo: Int,
            bar: Int) -> String 1️⃣{
            "result"
        }
        """,
      expected: """
        func method(
            foo: Int,
            bar: Int) -> String
        {
            "result"
        }
        """,
      findings: [FindingSpec("1️⃣", message: "move opening brace to its own line for multiline statement")])
  }
}
