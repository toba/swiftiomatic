import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoEmptyBlockTests: RuleTesting {
    private static let functionMessage =
        "empty function body; add a statement or a comment that explains the no-op"
    private static let initializerMessage =
        "empty initializer body; add a statement or a comment that explains the no-op"
    private static let statementMessage =
        "empty statement block; add a statement or a comment that explains the no-op"
    private static let closureMessage =
        "empty closure; add a statement or a comment that explains the no-op"

    @Test func warnsEmptyFunctionBody() {
        assertLint(
            NoEmptyBlock.self,
            """
            func spaced() 1️⃣{
            }
            func compact() 2️⃣{}
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.functionMessage),
                FindingSpec("2️⃣", message: Self.functionMessage),
            ]
        )
    }

    @Test func warnsEmptyInitializerAndDeinitializerBody() {
        assertLint(
            NoEmptyBlock.self,
            """
            class C {
              init() 1️⃣{
              }
              deinit 2️⃣{
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.initializerMessage),
                FindingSpec("2️⃣", message: Self.initializerMessage),
            ]
        )
    }

    @Test func warnsEmptyStatementBlocks() {
        assertLint(
            NoEmptyBlock.self,
            """
            func f(flag: Bool, items: [Int]) {
              if flag 1️⃣{
              } else 2️⃣{
              }
              for item in items 3️⃣{
              }
              while flag 4️⃣{
              }
              repeat 5️⃣{
              } while flag
              do 6️⃣{
              } catch 7️⃣{
              }
              defer 8️⃣{
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.statementMessage),
                FindingSpec("2️⃣", message: Self.statementMessage),
                FindingSpec("3️⃣", message: Self.statementMessage),
                FindingSpec("4️⃣", message: Self.statementMessage),
                FindingSpec("5️⃣", message: Self.statementMessage),
                FindingSpec("6️⃣", message: Self.statementMessage),
                FindingSpec("7️⃣", message: Self.statementMessage),
                FindingSpec("8️⃣", message: Self.statementMessage),
            ]
        )
    }

    @Test func warnsEmptyClosure() {
        assertLint(
            NoEmptyBlock.self,
            """
            func f(action: () -> Void) {
              f 1️⃣{
              }
              f(action: 2️⃣{})
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.closureMessage),
                FindingSpec("2️⃣", message: Self.closureMessage),
            ]
        )
    }

    @Test func allowsBlocksHoldingOnlyAComment() {
        assertLint(
            NoEmptyBlock.self,
            """
            func lineComment() {
              // nothing to do
            }
            func blockComment() { /* nothing to do */ }
            func trailingComment() {  // nothing to do
            }
            """,
            findings: []
        )
    }

    @Test func allowsBlocksHoldingStatements() {
        assertLint(
            NoEmptyBlock.self,
            """
            func f(flag: Bool) {
              if flag {
                print("yes")
              }
            }
            """,
            findings: []
        )
    }

    @Test func skipsAccessorAndTypeBodies() {
        assertLint(
            NoEmptyBlock.self,
            """
            struct S {
              var value: Int = 0 {
                willSet {}
                didSet {}
              }
            }
            protocol P {}
            enum E {}
            """,
            findings: []
        )
    }

    @Test func allowsCompactBlocksWhenConfigured() {
        assertLint(
            NoEmptyBlock.self,
            """
            func compact() {}
            func spaced() 1️⃣{ }
            func multiline() 2️⃣{
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.functionMessage),
                FindingSpec("2️⃣", message: Self.functionMessage),
            ],
            configuration: Self.config { $0.allowCompactEmptyBlocks = true }
        )
    }

    @Test func skipsDisabledBlockTypes() {
        assertLint(
            NoEmptyBlock.self,
            """
            func f() 1️⃣{
            }
            let noop: () -> Void = {
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.functionMessage)],
            configuration: Self.config { $0.checkClosureBlocks = false }
        )
    }

    private static func config(
        _ change: (inout NoEmptyBlockConfiguration) -> Void
    ) -> Configuration {
        var configuration = Configuration.forTesting
        configuration.disableAllRules()
        var ruleConfig = NoEmptyBlockConfiguration()
        ruleConfig.lint = .warn
        change(&ruleConfig)
        configuration[NoEmptyBlock.self] = ruleConfig
        return configuration
    }
}
