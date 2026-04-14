@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapLoopBodiesTests: RuleTesting {

  // MARK: - For loops

  @Test func forLoopWraps() {
    assertFormatting(
      WrapLoopBodies.self,
      input: """
        for foo in bar 1️⃣{ print(foo) }
        """,
      expected: """
        for foo in bar {
            print(foo)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap loop body onto a new line")])
  }

  @Test func forLoopAlreadyWrappedUnchanged() {
    assertFormatting(
      WrapLoopBodies.self,
      input: """
        for foo in bar {
            print(foo)
        }
        """,
      expected: """
        for foo in bar {
            print(foo)
        }
        """)
  }

  @Test func emptyForLoopUnchanged() {
    assertFormatting(
      WrapLoopBodies.self,
      input: """
        for foo in bar { }
        """,
      expected: """
        for foo in bar { }
        """)
  }

  @Test func indentedForLoopWraps() {
    assertFormatting(
      WrapLoopBodies.self,
      input: """
        func test() {
            for foo in bar 1️⃣{ print(foo) }
        }
        """,
      expected: """
        func test() {
            for foo in bar {
                print(foo)
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap loop body onto a new line")])
  }

  @Test func forLoopWithWhereWraps() {
    assertFormatting(
      WrapLoopBodies.self,
      input: """
        for foo in bar where foo > 0 1️⃣{ print(foo) }
        """,
      expected: """
        for foo in bar where foo > 0 {
            print(foo)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap loop body onto a new line")])
  }

  // MARK: - While loops

  @Test func whileLoopWraps() {
    assertFormatting(
      WrapLoopBodies.self,
      input: """
        while let foo = bar.next() 1️⃣{ print(foo) }
        """,
      expected: """
        while let foo = bar.next() {
            print(foo)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap loop body onto a new line")])
  }

  @Test func whileLoopAlreadyWrappedUnchanged() {
    assertFormatting(
      WrapLoopBodies.self,
      input: """
        while condition {
            doSomething()
        }
        """,
      expected: """
        while condition {
            doSomething()
        }
        """)
  }

  // MARK: - Repeat-while loops

  @Test func repeatWhileLoopWraps() {
    assertFormatting(
      WrapLoopBodies.self,
      input: """
        repeat 1️⃣{ print(foo) } while condition()
        """,
      expected: """
        repeat {
            print(foo)
        } while condition()
        """,
      findings: [FindingSpec("1️⃣", message: "wrap loop body onto a new line")])
  }

  @Test func repeatWhileAlreadyWrappedUnchanged() {
    assertFormatting(
      WrapLoopBodies.self,
      input: """
        repeat {
            print(foo)
        } while condition()
        """,
      expected: """
        repeat {
            print(foo)
        } while condition()
        """)
  }

  // MARK: - Nested loops

  @Test func nestedForLoopsWrap() {
    assertFormatting(
      WrapLoopBodies.self,
      input: """
        for x in xs 1️⃣{ for y in ys 2️⃣{ print(x, y) } }
        """,
      expected: """
        for x in xs {
            for y in ys {
                print(x, y)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap loop body onto a new line"),
        FindingSpec("2️⃣", message: "wrap loop body onto a new line"),
      ])
  }
}
