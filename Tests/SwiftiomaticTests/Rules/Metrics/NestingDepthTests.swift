@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NestingDepthTests: RuleTesting {
    @Test func passesTopLevelType() {
        assertLint(
            NestingDepth.self,
            """
            struct Outer {
                func ok() {}
            }
            """,
            findings: []
        )
    }

    @Test func warnsDeeplyNestedTypes() {
        assertLint(
            NestingDepth.self,
            """
            struct A {
                1️⃣struct B {
                    2️⃣struct C {}
                }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "type is nested 2 levels deep; limit is 1"),
                FindingSpec("2️⃣", message: "type is nested 3 levels deep; limit is 1"),
            ]
        )
    }

    @Test func warnsDeeplyNestedFunctions() {
        assertLint(
            NestingDepth.self,
            """
            func a() {
                func b() {
                    1️⃣func c() {
                        2️⃣func d() {}
                    }
                }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "function is nested 3 levels deep; limit is 2"),
                FindingSpec("2️⃣", message: "function is nested 4 levels deep; limit is 2"),
            ]
        )
    }

    @Test func resetsBetweenSiblingTypes() {
        assertLint(
            NestingDepth.self,
            """
            struct A {
                1️⃣struct B {}
            }
            struct C {
                2️⃣struct D {}
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "type is nested 2 levels deep; limit is 1"),
                FindingSpec("2️⃣", message: "type is nested 2 levels deep; limit is 1"),
            ]
        )
    }

    @Test func resetsBetweenSiblingFunctions() {
        assertLint(
            NestingDepth.self,
            """
            func a() {
                func b() {
                    1️⃣func c() {}
                }
            }
            func d() {
                func e() {
                    2️⃣func f() {}
                }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "function is nested 3 levels deep; limit is 2"),
                FindingSpec("2️⃣", message: "function is nested 3 levels deep; limit is 2"),
            ]
        )
    }

    @Test func functionInsideTypeOK() {
        assertLint(
            NestingDepth.self,
            """
            struct Outer {
                func method() {
                    func helper() {}
                }
            }
            """,
            findings: []
        )
    }
}
