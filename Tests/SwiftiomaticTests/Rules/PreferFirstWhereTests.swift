@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferFirstWhereTests: RuleTesting {

    @Test func filterFirstTriggers() {
        assertLint(
            PreferFirstWhere.self,
            """
            _ = myList.1️⃣filter { $0 % 2 == 0 }.first
            _ = myList.2️⃣filter({ $0 % 2 == 0 }).first
            _ = myList.map { $0 + 1 }.3️⃣filter({ $0 % 2 == 0 }).first
            _ = myList.map { $0 + 1 }.4️⃣filter({ $0 % 2 == 0 }).first?.something()
            _ = myList.5️⃣filter(someFunction).first
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'first(where:)' over 'filter(_:).first'"),
                FindingSpec("2️⃣", message: "prefer 'first(where:)' over 'filter(_:).first'"),
                FindingSpec("3️⃣", message: "prefer 'first(where:)' over 'filter(_:).first'"),
                FindingSpec("4️⃣", message: "prefer 'first(where:)' over 'filter(_:).first'"),
                FindingSpec("5️⃣", message: "prefer 'first(where:)' over 'filter(_:).first'"),
            ]
        )
    }

    @Test func nonTriggering() {
        assertLint(
            PreferFirstWhere.self,
            #"""
            _ = myList.first(where: { $0 % 2 == 0 })
            _ = match(pattern: pattern).filter { $0.first == .identifier }
            _ = (myList.filter { $0 == 1 }.suffix(2)).first
            _ = collection.filter("stringCol = '3'").first
            _ = realm?.objects(User.self).filter(NSPredicate(format: "email ==[c] %@", email)).first
            """#,
            findings: []
        )
    }
}
