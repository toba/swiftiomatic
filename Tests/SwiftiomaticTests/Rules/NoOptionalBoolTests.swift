@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoOptionalBoolTests: RuleTesting {

    @Test func optionalBoolAnnotationTriggers() {
        assertLint(
            NoOptionalBool.self,
            """
            var flag: 1️⃣Bool? = nil
            func foo() -> 2️⃣Bool? { nil }
            func bar(_ x: 3️⃣Bool?) {}
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer a non-optional 'Bool' (with a default) or an enum over 'Bool?'"),
                FindingSpec("2️⃣", message: "prefer a non-optional 'Bool' (with a default) or an enum over 'Bool?'"),
                FindingSpec("3️⃣", message: "prefer a non-optional 'Bool' (with a default) or an enum over 'Bool?'"),
            ]
        )
    }

    @Test func optionalSomeBoolTriggers() {
        assertLint(
            NoOptionalBool.self,
            """
            let x = 1️⃣Optional.some(true)
            let y = 2️⃣Optional.some(false)
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer a non-optional 'Bool' (with a default) or an enum over 'Bool?'"),
                FindingSpec("2️⃣", message: "prefer a non-optional 'Bool' (with a default) or an enum over 'Bool?'"),
            ]
        )
    }

    @Test func nonOptionalBoolAccepted() {
        assertLint(
            NoOptionalBool.self,
            """
            var flag: Bool = true
            var maybeInt: Int? = nil
            let x = Optional.some(1)
            """,
            findings: []
        )
    }
}
