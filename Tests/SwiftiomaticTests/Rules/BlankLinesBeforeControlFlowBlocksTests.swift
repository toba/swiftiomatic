@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct BlankLinesBeforeControlFlowBlocksTests: RuleTesting {

  @Test func insertsBlankBeforeForLoop() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let items = getItems()
            1️⃣for item in items {
                process(item)
            }
        }
        """,
      expected: """
        func test() {
            let items = getItems()

            for item in items {
                process(item)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }

  @Test func insertsBlankBeforeWhileLoop() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            var count = 0
            1️⃣while count < 10 {
                count += 1
            }
        }
        """,
      expected: """
        func test() {
            var count = 0

            while count < 10 {
                count += 1
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }

  @Test func insertsBlankBeforeIfStatement() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let x = getValue()
            1️⃣if x > 0 {
                print("positive")
            }
        }
        """,
      expected: """
        func test() {
            let x = getValue()

            if x > 0 {
                print("positive")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }

  @Test func insertsBlankBeforeSwitchStatement() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let value = getValue()
            1️⃣switch value {
            case .a:
                print("a")
            case .b:
                print("b")
            }
        }
        """,
      expected: """
        func test() {
            let value = getValue()

            switch value {
            case .a:
                print("a")
            case .b:
                print("b")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }

  @Test func insertsBlankBeforeDoStatement() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let url = getURL()
            1️⃣do {
                let data = try fetchData(url)
                process(data)
            } catch {
                print(error)
            }
        }
        """,
      expected: """
        func test() {
            let url = getURL()

            do {
                let data = try fetchData(url)
                process(data)
            } catch {
                print(error)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }

  @Test func insertsBlankBeforeDeferStatement() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let resource = acquire()
            1️⃣defer {
                release(resource)
            }
        }
        """,
      expected: """
        func test() {
            let resource = acquire()

            defer {
                release(resource)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }

  @Test func insertsBlankBeforeRepeatWhile() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            var count = 0
            1️⃣repeat {
                count += 1
            } while count < 10
        }
        """,
      expected: """
        func test() {
            var count = 0

            repeat {
                count += 1
            } while count < 10
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }

  @Test func noBlankBeforeSingleLineControlFlow() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let x = 1
            if x > 0 { print("positive") }
        }
        """,
      expected: """
        func test() {
            let x = 1
            if x > 0 { print("positive") }
        }
        """,
      findings: []
    )
  }

  @Test func noBlankWhenFirstStatement() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            for item in items {
                process(item)
            }
        }
        """,
      expected: """
        func test() {
            for item in items {
                process(item)
            }
        }
        """,
      findings: []
    )
  }

  @Test func alreadyHasBlankLine() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let items = getItems()

            for item in items {
                process(item)
            }
        }
        """,
      expected: """
        func test() {
            let items = getItems()

            for item in items {
                process(item)
            }
        }
        """,
      findings: []
    )
  }

  @Test func multipleControlFlowStatements() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let x = getValue()
            1️⃣for item in items {
                process(item)
            }
            2️⃣if x > 0 {
                print("positive")
            }
        }
        """,
      expected: """
        func test() {
            let x = getValue()

            for item in items {
                process(item)
            }

            if x > 0 {
                print("positive")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
        FindingSpec("2️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }

  @Test func insertsBlankInsideSwitchCase() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            switch value {
            case .a:
                let x = compute()
                1️⃣if x > 0 {
                    process(x)
                }
            case .b:
                let y = prepare()
                2️⃣for item in items {
                    handle(item)
                }
            default:
                break
            }
        }
        """,
      expected: """
        func test() {
            switch value {
            case .a:
                let x = compute()

                if x > 0 {
                    process(x)
                }
            case .b:
                let y = prepare()

                for item in items {
                    handle(item)
                }
            default:
                break
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
        FindingSpec("2️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }

  @Test func closingBraceAsBlankLineSkipsInsertion() {
    var config = Configuration.forTesting(enabledRule: BlankLinesBeforeControlFlowBlocks.self.key)
    config[ClosingBraceAsBlankLine.self] = true

    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            if condition {
                doSomething()
            }
            for item in items {
                process(item)
            }
        }
        """,
      expected: """
        func test() {
            if condition {
                doSomething()
            }
            for item in items {
                process(item)
            }
        }
        """,
      findings: [],
      configuration: config
    )
  }

  @Test func closingBraceAsBlankLineDefaultStillInserts() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            if condition {
                doSomething()
            }
            1️⃣for item in items {
                process(item)
            }
        }
        """,
      expected: """
        func test() {
            if condition {
                doSomething()
            }

            for item in items {
                process(item)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }

  @Test func closingBraceAsBlankLineNonBracePrevious() {
    var config = Configuration.forTesting(enabledRule: BlankLinesBeforeControlFlowBlocks.self.key)
    config[ClosingBraceAsBlankLine.self] = true

    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let x = getValue()
            1️⃣for item in items {
                process(item)
            }
        }
        """,
      expected: """
        func test() {
            let x = getValue()

            for item in items {
                process(item)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
      ],
      configuration: config
    )
  }

  @Test func emptyCodeBlock() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func foo() {}
        """,
      expected: """
        func foo() {}
        """,
      findings: []
    )
  }

  @Test func emptyCodeBlockInStruct() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        struct Foo {
            var x = 1
            init() {}
        }
        """,
      expected: """
        struct Foo {
            var x = 1
            init() {}
        }
        """,
      findings: []
    )
  }

  @Test func commentAsBlankLineSkipsInsertion() {
    var config = Configuration.forTesting(enabledRule: BlankLinesBeforeControlFlowBlocks.self.key)
    config[CommentAsBlankLine.self] = true

    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let items = getItems()
            // iterate over all items
            for item in items {
                process(item)
            }
        }
        """,
      expected: """
        func test() {
            let items = getItems()
            // iterate over all items
            for item in items {
                process(item)
            }
        }
        """,
      findings: [],
      configuration: config
    )
  }

  @Test func commentAsBlankLineDefaultStillInserts() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let items = getItems()
            // iterate over all items
            1️⃣for item in items {
                process(item)
            }
        }
        """,
      expected: """
        func test() {
            let items = getItems()

            // iterate over all items
            for item in items {
                process(item)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }

  @Test func nestedControlFlow() {
    assertFormatting(
      BlankLinesBeforeControlFlowBlocks.self,
      input: """
        func test() {
            let items = getItems()
            1️⃣for item in items {
                let value = item.value
                2️⃣if value > 0 {
                    print(value)
                }
            }
        }
        """,
      expected: """
        func test() {
            let items = getItems()

            for item in items {
                let value = item.value

                if value > 0 {
                    print(value)
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line before control flow statement"),
        FindingSpec("2️⃣", message: "insert blank line before control flow statement"),
      ]
    )
  }
}
