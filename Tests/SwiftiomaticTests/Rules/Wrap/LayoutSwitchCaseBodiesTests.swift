@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

// MARK: - Wrap Mode Tests

@Suite
struct LayoutSwitchCaseBodiesTests: RuleTesting {

  @Test func inlineCaseWraps() {
    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        switch piece {
        1️⃣case .backslashes, .pounds: piece.write(to: &result)
        2️⃣default: break
        }
        """,
      expected: """
        switch piece {
        case .backslashes, .pounds:
            piece.write(to: &result)
        default:
            break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap switch case body onto a new line"),
        FindingSpec("2️⃣", message: "wrap switch case body onto a new line"),
      ])
  }

  @Test func alreadyWrappedUnchanged() {
    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        switch foo {
        case .bar:
            print("hello")
        default:
            break
        }
        """,
      expected: """
        switch foo {
        case .bar:
            print("hello")
        default:
            break
        }
        """)
  }

  @Test func multiStatementAlreadyWrappedUnchanged() {
    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        switch foo {
        case .bar:
            let x = 1
            print(x)
        default:
            break
        }
        """,
      expected: """
        switch foo {
        case .bar:
            let x = 1
            print(x)
        default:
            break
        }
        """)
  }

  @Test func nestedSwitchWraps() {
    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        func test() {
            switch value {
            1️⃣case .a: doSomething()
            case .b:
                doOther()
            }
        }
        """,
      expected: """
        func test() {
            switch value {
            case .a:
                doSomething()
            case .b:
                doOther()
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap switch case body onto a new line")])
  }

  @Test func emptyCaseUnchanged() {
    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        switch foo {
        case .bar:
            break
        }
        """,
      expected: """
        switch foo {
        case .bar:
            break
        }
        """)
  }
}

// MARK: - Adaptive Mode Tests

@Suite
struct LayoutSwitchCaseBodiesAdaptiveTests: RuleTesting {

  private var adaptiveConfig: Configuration {
    var config = Configuration.forTesting(enabledRule: LayoutSwitchCaseBodies.key)
    config[LayoutSwitchCaseBodies.self] = {
      var c = LayoutSwitchCaseBodiesConfiguration()
      c.mode = .adaptive
      return c
    }()
    return config
  }

  @Test func singleStatementInlines() {
    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        switch piece {
        1️⃣case .backslashes:
            piece.write(to: &result)
        2️⃣default:
            break
        }
        """,
      expected: """
        switch piece {
        case .backslashes: piece.write(to: &result)
        default: break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "place switch case body on same line as label"),
        FindingSpec("2️⃣", message: "place switch case body on same line as label"),
      ],
      configuration: adaptiveConfig)
  }

  @Test func multiStatementStaysWrapped() {
    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        switch foo {
        case .bar:
            let x = 1
            print(x)
        1️⃣default:
            break
        }
        """,
      expected: """
        switch foo {
        case .bar:
            let x = 1
            print(x)
        default: break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "place switch case body on same line as label"),
      ],
      configuration: adaptiveConfig)
  }

  @Test func longLineStaysWrapped() {
    var config = adaptiveConfig
    config[LineLength.self] = 40

    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        switch foo {
        case .bar:
            doSomethingVeryLongThatWontFit()
        1️⃣default:
            break
        }
        """,
      expected: """
        switch foo {
        case .bar:
            doSomethingVeryLongThatWontFit()
        default: break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "place switch case body on same line as label"),
      ],
      configuration: config)
  }

  @Test func alreadyInlineUnchanged() {
    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        switch foo {
        case .bar: print("hello")
        default: break
        }
        """,
      expected: """
        switch foo {
        case .bar: print("hello")
        default: break
        }
        """,
      configuration: adaptiveConfig)
  }

  @Test func mixedInliningAdaptsPerCase() {
    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        switch value {
        1️⃣case .short:
            x()
        case .long:
            let result = computeSomething()
            process(result)
        2️⃣default:
            break
        }
        """,
      expected: """
        switch value {
        case .short: x()
        case .long:
            let result = computeSomething()
            process(result)
        default: break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "place switch case body on same line as label"),
        FindingSpec("2️⃣", message: "place switch case body on same line as label"),
      ],
      configuration: adaptiveConfig)
  }

  @Test func multiPatternBodyInlinesOnLastPattern() {
    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        switch token {
        1️⃣case .docBlockComment,
             .docLineComment,
             .newlines(1),
             .carriageReturns(1),
             .carriageReturnLineFeeds(1),
             .spaces,
             .tabs:
            false
        }
        """,
      expected: """
        switch token {
        case .docBlockComment,
             .docLineComment,
             .newlines(1),
             .carriageReturns(1),
             .carriageReturnLineFeeds(1),
             .spaces,
             .tabs: false
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "place switch case body on same line as label"),
      ],
      configuration: adaptiveConfig)
  }

  @Test func nestedIndentationInlines() {
    assertFormatting(
      LayoutSwitchCaseBodies.self,
      input: """
        func test() {
            switch value {
            1️⃣case .a:
                doSomething()
            2️⃣default:
                break
            }
        }
        """,
      expected: """
        func test() {
            switch value {
            case .a: doSomething()
            default: break
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "place switch case body on same line as label"),
        FindingSpec("2️⃣", message: "place switch case body on same line as label"),
      ],
      configuration: adaptiveConfig)
  }
}
