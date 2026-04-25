@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoOptionalCollectionTests: RuleTesting {

    @Test func optionalArrayTriggers() {
        assertLint(
            NoOptionalCollection.self,
            """
            var xs: 1️⃣[Int]? = nil
            func f() -> 2️⃣Array<String>? { nil }
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer a non-optional collection (use 'isEmpty' to check for absence) over an optional one"),
                FindingSpec("2️⃣", message: "prefer a non-optional collection (use 'isEmpty' to check for absence) over an optional one"),
            ]
        )
    }

    @Test func optionalDictionaryTriggers() {
        assertLint(
            NoOptionalCollection.self,
            """
            var m: 1️⃣[String: Int]? = nil
            var n: 2️⃣Dictionary<String, Int>? = nil
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer a non-optional collection (use 'isEmpty' to check for absence) over an optional one"),
                FindingSpec("2️⃣", message: "prefer a non-optional collection (use 'isEmpty' to check for absence) over an optional one"),
            ]
        )
    }

    @Test func optionalSetTriggers() {
        assertLint(
            NoOptionalCollection.self,
            """
            var s: 1️⃣Set<Int>? = nil
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer a non-optional collection (use 'isEmpty' to check for absence) over an optional one")
            ]
        )
    }

    @Test func nonOptionalCollectionAccepted() {
        assertLint(
            NoOptionalCollection.self,
            """
            var xs: [Int] = []
            var m: [String: Int] = [:]
            var s: Set<Int> = []
            var maybeInt: Int? = nil
            """,
            findings: []
        )
    }
}
