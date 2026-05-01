@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct IndentSwitchCasesTests: RuleTesting {

    private func config(style: IndentSwitchCasesConfiguration.Style) -> Configuration {
        var config = Configuration.forTesting
        config[IndentSwitchCases.self].style = style
        config.enableRule(named: IndentSwitchCases.key)
        return config
    }

    // MARK: - Flush style (default)

    @Test func flushDedentsCaseLabels() {
        assertFormatting(
            IndentSwitchCases.self,
            input: """
                switch mode {
                  1️⃣case .wrap:
                    return wrapGuard(node)
                  2️⃣case .inline:
                    return inlineGuard(node)
                }
                """,
            expected: """
                switch mode {
                case .wrap:
                  return wrapGuard(node)
                case .inline:
                  return inlineGuard(node)
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "align 'case' with 'switch' keyword"),
                FindingSpec("2️⃣", message: "align 'case' with 'switch' keyword"),
            ],
            configuration: config(style: .flush)
        )
    }

    @Test func flushAlreadyAligned() {
        assertFormatting(
            IndentSwitchCases.self,
            input: """
                switch mode {
                case .wrap:
                  return wrapGuard(node)
                case .inline:
                  return inlineGuard(node)
                }
                """,
            expected: """
                switch mode {
                case .wrap:
                  return wrapGuard(node)
                case .inline:
                  return inlineGuard(node)
                }
                """,
            findings: [],
            configuration: config(style: .flush)
        )
    }

    @Test func flushDefaultCase() {
        assertFormatting(
            IndentSwitchCases.self,
            input: """
                switch value {
                  1️⃣case .a:
                    doSomething()
                  2️⃣default:
                    break
                }
                """,
            expected: """
                switch value {
                case .a:
                  doSomething()
                default:
                  break
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "align 'case' with 'switch' keyword"),
                FindingSpec("2️⃣", message: "align 'case' with 'switch' keyword"),
            ],
            configuration: config(style: .flush)
        )
    }

    @Test func flushNestedSwitch() {
        assertFormatting(
            IndentSwitchCases.self,
            input: """
                func format() -> StmtSyntax {
                  switch mode {
                    1️⃣case .wrap:
                      return wrapGuard()
                    2️⃣case .inline:
                      return inlineGuard()
                  }
                }
                """,
            expected: """
                func format() -> StmtSyntax {
                  switch mode {
                  case .wrap:
                    return wrapGuard()
                  case .inline:
                    return inlineGuard()
                  }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "align 'case' with 'switch' keyword"),
                FindingSpec("2️⃣", message: "align 'case' with 'switch' keyword"),
            ],
            configuration: config(style: .flush)
        )
    }

    // MARK: - Indented style

    @Test func indentedAddsCaseIndentation() {
        assertFormatting(
            IndentSwitchCases.self,
            input: """
                switch mode {
                1️⃣case .wrap:
                  return wrapGuard()
                2️⃣case .inline:
                  return inlineGuard()
                }
                """,
            expected: """
                switch mode {
                  case .wrap:
                    return wrapGuard()
                  case .inline:
                    return inlineGuard()
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "indent 'case' one level from 'switch' keyword"),
                FindingSpec("2️⃣", message: "indent 'case' one level from 'switch' keyword"),
            ],
            configuration: config(style: .indented)
        )
    }

    @Test func indentedAlreadyIndented() {
        assertFormatting(
            IndentSwitchCases.self,
            input: """
                switch mode {
                  case .wrap:
                    return wrapGuard()
                  case .inline:
                    return inlineGuard()
                }
                """,
            expected: """
                switch mode {
                  case .wrap:
                    return wrapGuard()
                  case .inline:
                    return inlineGuard()
                }
                """,
            findings: [],
            configuration: config(style: .indented)
        )
    }

    @Test func indentedNestedSwitch() {
        assertFormatting(
            IndentSwitchCases.self,
            input: """
                func format() -> StmtSyntax {
                  switch mode {
                  1️⃣case .wrap:
                    return wrapGuard()
                  2️⃣case .inline:
                    return inlineGuard()
                  }
                }
                """,
            expected: """
                func format() -> StmtSyntax {
                  switch mode {
                    case .wrap:
                      return wrapGuard()
                    case .inline:
                      return inlineGuard()
                  }
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "indent 'case' one level from 'switch' keyword"),
                FindingSpec("2️⃣", message: "indent 'case' one level from 'switch' keyword"),
            ],
            configuration: config(style: .indented)
        )
    }

    @Test func indentedDefaultCase() {
        assertFormatting(
            IndentSwitchCases.self,
            input: """
                switch value {
                1️⃣case .a:
                  doSomething()
                2️⃣default:
                  break
                }
                """,
            expected: """
                switch value {
                  case .a:
                    doSomething()
                  default:
                    break
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "indent 'case' one level from 'switch' keyword"),
                FindingSpec("2️⃣", message: "indent 'case' one level from 'switch' keyword"),
            ],
            configuration: config(style: .indented)
        )
    }

    @Test func switchExpression() {
        assertFormatting(
            IndentSwitchCases.self,
            input: """
                let x = switch mode {
                  1️⃣case .a:
                    1
                  2️⃣case .b:
                    2
                }
                """,
            expected: """
                let x = switch mode {
                case .a:
                  1
                case .b:
                  2
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "align 'case' with 'switch' keyword"),
                FindingSpec("2️⃣", message: "align 'case' with 'switch' keyword"),
            ],
            configuration: config(style: .flush)
        )
    }

    @Test func multipleStatementBody() {
        assertFormatting(
            IndentSwitchCases.self,
            input: """
                switch action {
                  1️⃣case .engage:
                    spinUp()
                    activate()
                  2️⃣case .disengage:
                    deactivate()
                }
                """,
            expected: """
                switch action {
                case .engage:
                  spinUp()
                  activate()
                case .disengage:
                  deactivate()
                }
                """,
            findings: [
                FindingSpec("1️⃣", message: "align 'case' with 'switch' keyword"),
                FindingSpec("2️⃣", message: "align 'case' with 'switch' keyword"),
            ],
            configuration: config(style: .flush)
        )
    }
}
