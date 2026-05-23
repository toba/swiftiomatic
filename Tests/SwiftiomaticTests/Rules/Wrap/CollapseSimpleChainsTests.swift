@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct CollapseSimpleChainsTests: RuleTesting {

    // MARK: - Collapsing

    @Test func collapsesTwoCallChain() {
        assertFormatting(
            CollapseSimpleChains.self,
            input: """
                try 1️⃣SyncRemindersList
                    .find(1)
                    .delete(from: db)
                """,
            expected: """
                try SyncRemindersList.find(1).delete(from: db)
                """,
            findings: [FindingSpec("1️⃣", message: "collapse chained calls onto a single line")])
    }

    @Test func collapsesThreeCallChain() {
        assertFormatting(
            CollapseSimpleChains.self,
            input: """
                let x = 1️⃣items
                    .filter { $0 > 0 }
                    .map { $0 * 2 }
                    .reduce(0, +)
                """,
            expected: """
                let x = items.filter { $0 > 0 }.map { $0 * 2 }.reduce(0, +)
                """,
            findings: [FindingSpec("1️⃣", message: "collapse chained calls onto a single line")])
    }

    @Test func collapsesSingleDotChain() {
        assertFormatting(
            CollapseSimpleChains.self,
            input: """
                let x = 1️⃣foo
                    .bar()
                """,
            expected: """
                let x = foo.bar()
                """,
            findings: [FindingSpec("1️⃣", message: "collapse chained calls onto a single line")])
    }

    // MARK: - No-ops

    @Test func doesNotCollapseWhenTooLong() {
        assertFormatting(
            CollapseSimpleChains.self,
            input: """
                let x = veryLongBaseExpressionNameHere
                    .firstMethodWithARatherLongName(argument: someValue)
                    .secondMethodWithAnotherLongName(argument: anotherValue)
                """,
            expected: """
                let x = veryLongBaseExpressionNameHere
                    .firstMethodWithARatherLongName(argument: someValue)
                    .secondMethodWithAnotherLongName(argument: anotherValue)
                """)
    }

    @Test func doesNotCollapseAlreadyOnOneLine() {
        assertFormatting(
            CollapseSimpleChains.self,
            input: """
                let x = foo.bar().baz()
                """,
            expected: """
                let x = foo.bar().baz()
                """)
    }

    @Test func doesNotCollapseChainWithLineComment() {
        assertFormatting(
            CollapseSimpleChains.self,
            input: """
                let x = foo
                    .bar() // comment
                    .baz()
                """,
            expected: """
                let x = foo
                    .bar() // comment
                    .baz()
                """)
    }

    @Test func doesNotCollapseChainWithMultilineArgs() {
        assertFormatting(
            CollapseSimpleChains.self,
            input: """
                let x = foo
                    .bar(
                        longArg1,
                        longArg2
                    )
                    .baz()
                """,
            expected: """
                let x = foo
                    .bar(
                        longArg1,
                        longArg2
                    )
                    .baz()
                """)
    }

    @Test func doesNotCollapseChainWithMultilineClosure() {
        assertFormatting(
            CollapseSimpleChains.self,
            input: """
                let x = items
                    .map { item in
                        item.value
                    }
                    .filter { $0 > 0 }
                """,
            expected: """
                let x = items
                    .map { item in
                        item.value
                    }
                    .filter { $0 > 0 }
                """)
    }
}
