@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseReduceIntoTests: RuleTesting {

    @Test func cowSeedTriggers() {
        assertLint(
            UseReduceInto.self,
            #"""
            let bar = values.1️⃣reduce("abc") { $0 + "\($1)" }
            let _ = values.2️⃣reduce(Array<Int>()) { result, value in result + [value] }
            let _ = values.3️⃣reduce([String: Int]()) { r, v in r }
            let _ = values.4️⃣reduce(Dictionary<String, Int>.init()) { r, v in r }
            let _ = values.5️⃣reduce(Set<Int>()) { acc, v in acc }
            let _ = values.6️⃣reduce([Int](repeating: 0, count: 10)) { r, v in r }
            """#,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'reduce(into:_:)' over 'reduce(_:_:)' for copy-on-write seeds"),
                FindingSpec("2️⃣", message: "prefer 'reduce(into:_:)' over 'reduce(_:_:)' for copy-on-write seeds"),
                FindingSpec("3️⃣", message: "prefer 'reduce(into:_:)' over 'reduce(_:_:)' for copy-on-write seeds"),
                FindingSpec("4️⃣", message: "prefer 'reduce(into:_:)' over 'reduce(_:_:)' for copy-on-write seeds"),
                FindingSpec("5️⃣", message: "prefer 'reduce(into:_:)' over 'reduce(_:_:)' for copy-on-write seeds"),
                FindingSpec("6️⃣", message: "prefer 'reduce(into:_:)' over 'reduce(_:_:)' for copy-on-write seeds"),
            ]
        )
    }

    @Test func nonTriggering() {
        assertLint(
            UseReduceInto.self,
            #"""
            let foo = values.reduce(into: "abc") { $0 += "\($1)" }
            let _ = values.reduce(into: Array<Int>()) { r, v in r.append(v) }
            let _ = values.reduce(MyClass()) { result, value in result }
            """#,
            findings: []
        )
    }
}
