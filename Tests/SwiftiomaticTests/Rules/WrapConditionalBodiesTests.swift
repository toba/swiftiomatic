@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapConditionalBodiesTests: RuleTesting {

  // MARK: - Guard statements

  @Test func guardReturnWraps() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        guard let foo = bar else 1️⃣{ return }
        """,
      expected: """
        guard let foo = bar else {
            return
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }

  @Test func guardReturnWithValueWraps() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        guard let foo = bar else 1️⃣{ return baz }
        """,
      expected: """
        guard let foo = bar else {
            return baz
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }

  @Test func emptyGuardBodyUnchanged() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        guard let foo = bar else { }
        """,
      expected: """
        guard let foo = bar else { }
        """)
  }

  @Test func emptyGuardBodyNoSpaceUnchanged() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        guard let foo = bar else {}
        """,
      expected: """
        guard let foo = bar else {}
        """)
  }

  @Test func guardAlreadyWrappedUnchanged() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        guard let foo = bar else {
            return
        }
        """,
      expected: """
        guard let foo = bar else {
            return
        }
        """)
  }

  @Test func guardContinueWraps() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        guard let foo = bar else 1️⃣{continue}
        """,
      expected: """
        guard let foo = bar else {
            continue
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }

  @Test func guardBodyWithClosingBraceOnNewlineWraps() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        guard foo else 1️⃣{ return
        }
        """,
      expected: """
        guard foo else {
            return
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }

  // MARK: - If/else statements

  @Test func ifElseReturnsWrap() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        if foo 1️⃣{ return bar } else if baz 2️⃣{ return qux } else 3️⃣{ return quux }
        """,
      expected: """
        if foo {
            return bar
        } else if baz {
            return qux
        } else {
            return quux
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("2️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("3️⃣", message: "wrap conditional body onto a new line"),
      ])
  }

  @Test func ifElseBodiesWrap() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        if foo 1️⃣{ bar } else if baz 2️⃣{ qux } else 3️⃣{ quux }
        """,
      expected: """
        if foo {
            bar
        } else if baz {
            qux
        } else {
            quux
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("2️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("3️⃣", message: "wrap conditional body onto a new line"),
      ])
  }

  @Test func emptyIfElseBodiesUnchanged() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        if foo { } else if baz { } else { }
        """,
      expected: """
        if foo { } else if baz { } else { }
        """)
  }

  @Test func alreadyWrappedIfElseUnchanged() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        if foo {
            return bar
        } else {
            return baz
        }
        """,
      expected: """
        if foo {
            return bar
        } else {
            return baz
        }
        """)
  }

  // MARK: - Nested conditionals

  @Test func nestedGuardElseIfWraps() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        guard let foo = bar else 1️⃣{ if qux 2️⃣{ return quux } else 3️⃣{ return quuz } }
        """,
      expected: """
        guard let foo = bar else {
            if qux {
                return quux
            } else {
                return quuz
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("2️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("3️⃣", message: "wrap conditional body onto a new line"),
      ])
  }

  @Test func nestedGuardElseGuardWraps() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        guard let foo = bar else 1️⃣{ guard qux else 2️⃣{ return quux } }
        """,
      expected: """
        guard let foo = bar else {
            guard qux else {
                return quux
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("2️⃣", message: "wrap conditional body onto a new line"),
      ])
  }

  // MARK: - Indented contexts

  @Test func indentedGuardWraps() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        func test() {
            guard let foo = bar else 1️⃣{ return }
        }
        """,
      expected: """
        func test() {
            guard let foo = bar else {
                return
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }

  @Test func indentedIfElseWraps() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        func test() {
            if foo 1️⃣{ return bar } else 2️⃣{ return baz }
        }
        """,
      expected: """
        func test() {
            if foo {
                return bar
            } else {
                return baz
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("2️⃣", message: "wrap conditional body onto a new line"),
      ])
  }

  // MARK: - Semicolon-delimited statements

  @Test func guardWithSemicolonDelimitedStatements() {
    assertFormatting(
      WrapConditionalBodies.self,
      input: """
        guard let foo = bar else 1️⃣{ var baz = 0; let boo = 1; fatalError() }
        """,
      expected: """
        guard let foo = bar else {
            var baz = 0; let boo = 1; fatalError()
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }
}
