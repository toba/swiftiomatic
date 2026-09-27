import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseOptionSetForBoolFlagsTests: RuleTesting {
    private static func message(_ name: String, _ count: Int) -> String {
        "'\(name)' takes \(count) 'Bool' parameters; combine the flags into one 'OptionSet' parameter"
    }

    @Test func functionWithThreeBoolParameters() {
        assertLint(
            UseOptionSetForBoolFlags.self,
            """
            private func 1️⃣makeDisplayElement(
                _ display: Display,
                width: CGFloat? = nil,
                breakBefore: Bool = true,
                breakAfter: Bool = true,
                penaltyBefore: Int = 0,
                indivisible: Bool = true
            ) -> Element {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("makeDisplayElement", 3))]
        )
    }

    @Test func initializerAndSubscript() {
        assertLint(
            UseOptionSetForBoolFlags.self,
            """
            struct Style {
                1️⃣init(bold: Bool, italic: Bool, underline: Swift.Bool, strike: Bool) {}
                2️⃣subscript(a: Bool, b: Bool, c: Bool) -> Int { 0 }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("init", 4)),
                FindingSpec("2️⃣", message: Self.message("subscript", 3)),
            ]
        )
    }

    @Test func twoBoolParametersAreIgnored() {
        assertLint(
            UseOptionSetForBoolFlags.self,
            """
            func layout(animated: Bool, cramped: Bool, count: Int) {}
            """,
            findings: []
        )
    }

    @Test func optionalAndClosureBoolsAreIgnored() {
        assertLint(
            UseOptionSetForBoolFlags.self,
            """
            func layout(a: Bool?, b: Bool, c: (Bool) -> Void, d: [Bool], e: Bool) {}
            """,
            findings: []
        )
    }

    @Test func overrideIsIgnored() {
        assertLint(
            UseOptionSetForBoolFlags.self,
            """
            class Child: Base {
                override func update(a: Bool, b: Bool, c: Bool) {}
            }
            """,
            findings: []
        )
    }
}
