@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferLastWhereTests: RuleTesting {

    @Test func filterLastTriggers() {
        assertLint(
            PreferLastWhere.self,
            """
            _ = myList.1️⃣filter { $0 % 2 == 0 }.last
            _ = myList.2️⃣filter({ $0 % 2 == 0 }).last
            _ = myList.map { $0 + 1 }.3️⃣filter({ $0 % 2 == 0 }).last
            _ = myList.map { $0 + 1 }.4️⃣filter({ $0 % 2 == 0 }).last?.something()
            _ = myList.5️⃣filter(someFunction).last
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'last(where:)' over 'filter(_:).last'"),
                FindingSpec("2️⃣", message: "prefer 'last(where:)' over 'filter(_:).last'"),
                FindingSpec("3️⃣", message: "prefer 'last(where:)' over 'filter(_:).last'"),
                FindingSpec("4️⃣", message: "prefer 'last(where:)' over 'filter(_:).last'"),
                FindingSpec("5️⃣", message: "prefer 'last(where:)' over 'filter(_:).last'"),
            ]
        )
    }

    @Test func nonTriggering() {
        assertLint(
            PreferLastWhere.self,
            #"""
            _ = myList.last(where: { $0 % 2 == 0 })
            _ = match(pattern: pattern).filter { $0.last == .identifier }
            _ = (myList.filter { $0 == 1 }.suffix(2)).last
            _ = collection.filter("stringCol = '3'").last
            """#,
            findings: []
        )
    }
}
