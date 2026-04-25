@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct TupleSizeTests: RuleTesting {
    @Test func passesSmallTuple() {
        assertLint(
            TupleSize.self,
            "let pair: (Int, Int) = (1, 2)",
            findings: []
        )
    }

    @Test func warnsLargeTuple() {
        assertLint(
            TupleSize.self,
            "let big: 1️⃣(Int, Int, Int, Int) = (1, 2, 3, 4)",
            findings: [
                FindingSpec("1️⃣", message: "tuple has 4 elements; limit is 3")
            ]
        )
    }

    @Test func errorsHugeTuple() {
        assertLint(
            TupleSize.self,
            "let huge: 1️⃣(Int, Int, Int, Int, Int) = (1, 2, 3, 4, 5)",
            findings: [
                FindingSpec("1️⃣", message: "tuple has 5 elements; limit is 4")
            ]
        )
    }
}
