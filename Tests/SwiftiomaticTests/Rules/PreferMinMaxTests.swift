@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferMinMaxTests: RuleTesting {

    @Test func sortedFirstTriggers() {
        assertLint(
            PreferMinMax.self,
            """
            _ = myList.sorted().1️⃣first
            _ = myList.sorted(by: { $0.description < $1.description }).2️⃣first
            _ = myList.sorted(by: >).3️⃣first
            _ = myList.map { $0 + 1 }.sorted().4️⃣first
            _ = myList.sorted(by: someFunction).5️⃣first
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'min()' over 'sorted().first'"),
                FindingSpec("2️⃣", message: "prefer 'min()' over 'sorted().first'"),
                FindingSpec("3️⃣", message: "prefer 'min()' over 'sorted().first'"),
                FindingSpec("4️⃣", message: "prefer 'min()' over 'sorted().first'"),
                FindingSpec("5️⃣", message: "prefer 'min()' over 'sorted().first'"),
            ]
        )
    }

    @Test func sortedLastTriggers() {
        assertLint(
            PreferMinMax.self,
            """
            _ = myList.sorted().1️⃣last
            _ = myList.sorted().2️⃣last?.something()
            _ = myList.sorted(by: { $0.description < $1.description }).3️⃣last
            _ = myList.map { $0 + 1 }.sorted().4️⃣last
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'max()' over 'sorted().last'"),
                FindingSpec("2️⃣", message: "prefer 'max()' over 'sorted().last'"),
                FindingSpec("3️⃣", message: "prefer 'max()' over 'sorted().last'"),
                FindingSpec("4️⃣", message: "prefer 'max()' over 'sorted().last'"),
            ]
        )
    }

    @Test func nonTriggering() {
        assertLint(
            PreferMinMax.self,
            #"""
            _ = myList.min()
            _ = myList.min(by: { $0 < $1 })
            _ = myList.max()
            _ = messages.sorted(byKeyPath: #keyPath(Message.timestamp)).last
            _ = messages.sorted(byKeyPath: "timestamp", ascending: false).first
            _ = myList.sorted().firstIndex(of: key)
            _ = myList.sorted().lastIndex(of: key)
            _ = myList.sorted().first(where: someFunction)
            _ = myList.sorted().last { $0 == key }
            """#,
            findings: []
        )
    }
}
