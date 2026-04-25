@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferFlatMapTests: RuleTesting {

    @Test func mapReduceEmptyPlusTriggers() {
        assertLint(
            PreferFlatMap.self,
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
            PreferFlatMap.self,
            """
            let foo = bar.map { $0.count }.reduce(0, +)
            let foo = bar.flatMap { $0.array }
            """,
            findings: []
        )
    }
}
