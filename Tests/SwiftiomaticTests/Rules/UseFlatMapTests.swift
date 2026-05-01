@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseFlatMapTests: RuleTesting {

    @Test func mapReduceEmptyPlusTriggers() {
        assertLint(
            UseFlatMap.self,
            """
            let foo = bar.map { $0.array }.1️⃣reduce([], +)
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'flatMap' over 'map { ... }.reduce([], +)'"),
            ]
        )
    }

    @Test func nonTriggering() {
        assertLint(
            UseFlatMap.self,
            """
            let foo = bar.map { $0.count }.reduce(0, +)
            let foo = bar.flatMap { $0.array }
            """,
            findings: []
        )
    }
}
