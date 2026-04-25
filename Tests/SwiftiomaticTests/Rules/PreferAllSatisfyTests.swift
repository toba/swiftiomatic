@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferAllSatisfyTests: RuleTesting {

    @Test func reduceTrueTriggers() {
        assertLint(
            PreferAllSatisfy.self,
            """
            let allNines = nums.1️⃣reduce(true) { $0.0 && $0.1 == 9 }
            let allValid = validators.2️⃣reduce(true, { $0 && $1(input) })
            let _ = nums.3️⃣reduce(into: true) { (r: inout Bool, s) in r = r && (s == 3) }
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'allSatisfy' over 'reduce(true)'"),
                FindingSpec("2️⃣", message: "prefer 'allSatisfy' over 'reduce(true)'"),
                FindingSpec("3️⃣", message: "prefer 'allSatisfy' over 'reduce(true)'"),
            ]
        )
    }

    @Test func reduceFalseTriggers() {
        assertLint(
            PreferAllSatisfy.self,
            """
            let anyNines = nums.1️⃣reduce(false) { $0.0 || $0.1 == 9 }
            let anyValid = validators.2️⃣reduce(false, { $0 || $1(input) })
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'contains' over 'reduce(false)'"),
                FindingSpec("2️⃣", message: "prefer 'contains' over 'reduce(false)'"),
            ]
        )
    }

    @Test func nonTriggering() {
        assertLint(
            PreferAllSatisfy.self,
            """
            _ = nums.reduce(0) { $0.0 + $0.1 }
            _ = nums.reduce(0.0) { $0.0 + $0.1 }
            _ = nums.reduce(initial: true) { $0.0 && $0.1 == 3 }
            """,
            findings: []
        )
    }
}
