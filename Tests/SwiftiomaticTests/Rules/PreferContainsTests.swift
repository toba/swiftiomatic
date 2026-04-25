@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferContainsTests: RuleTesting {

    @Test func filterCountComparedToZeroTriggers() {
        assertLint(
            PreferContains.self,
            """
            _ = myList.1️⃣filter(where: { $0 % 2 == 0 }).count == 0
            _ = myList.2️⃣filter { $0 % 2 == 0 }.count != 0
            _ = myList.3️⃣filter(where: someFunction).count > 0
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'contains(where:)' over comparing 'filter(_:).count' to 0"),
                FindingSpec("2️⃣", message: "prefer 'contains(where:)' over comparing 'filter(_:).count' to 0"),
                FindingSpec("3️⃣", message: "prefer 'contains(where:)' over comparing 'filter(_:).count' to 0"),
            ]
        )
    }

    @Test func filterCountComparedToNonZeroAccepted() {
        assertLint(
            PreferContains.self,
            """
            _ = myList.filter { $0 % 2 == 0 }.count == 1
            _ = myList.filter { $0 % 2 == 0 }.count > 1
            """,
            findings: []
        )
    }

    @Test func filterIsEmptyTriggers() {
        assertLint(
            PreferContains.self,
            """
            _ = myList.1️⃣filter(where: { $0 % 2 == 0 }).isEmpty
            _ = !myList.2️⃣filter { $0 % 2 == 0 }.isEmpty
            _ = myList.3️⃣filter(where: someFunction).isEmpty
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'contains(where:)' over 'filter(_:).isEmpty'"),
                FindingSpec("2️⃣", message: "prefer 'contains(where:)' over 'filter(_:).isEmpty'"),
                FindingSpec("3️⃣", message: "prefer 'contains(where:)' over 'filter(_:).isEmpty'"),
            ]
        )
    }

    @Test func firstNotNilTriggers() {
        assertLint(
            PreferContains.self,
            """
            _ = myList.1️⃣first { $0 % 2 == 0 } != nil
            _ = myList.2️⃣first(where: { $0 % 2 == 0 }) == nil
            _ = myList.map { $0 + 1 }.3️⃣firstIndex(where: { $0 % 2 == 0 }) != nil
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'contains(where:)' over 'first(where:) != nil'"),
                FindingSpec("2️⃣", message: "prefer 'contains(where:)' over 'first(where:) == nil'"),
                FindingSpec("3️⃣", message: "prefer 'contains(where:)' over 'firstIndex(where:) != nil'"),
            ]
        )
    }

    @Test func rangeOfNotNilTriggers() {
        assertLint(
            PreferContains.self,
            #"""
            _ = myString.1️⃣range(of: "Test") != nil
            _ = myString.2️⃣range(of: "Test") == nil
            """#,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'contains' over 'range(of:) != nil'"),
                FindingSpec("2️⃣", message: "prefer 'contains' over 'range(of:) == nil'"),
            ]
        )
    }

    @Test func rangeOfWithRegexOptionsAccepted() {
        assertLint(
            PreferContains.self,
            #"""
            _ = resourceString.range(of: rule.regex, options: .regularExpression) != nil
            """#,
            findings: []
        )
    }

    @Test func nonTriggering() {
        assertLint(
            PreferContains.self,
            #"""
            _ = myList.contains(where: { $0 % 2 == 0 })
            _ = !myList.contains(where: { $0 % 2 == 0 })
            _ = myList.contains(10)
            _ = myList.first { $0 % 2 == 0 }
            _ = myList.first(where: { $0 % 2 == 0 })
            _ = myString.range(of: "Test")
            """#,
            findings: []
        )
    }
}
