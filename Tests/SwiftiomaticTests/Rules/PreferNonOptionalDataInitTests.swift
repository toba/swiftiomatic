@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferNonOptionalDataInitTests: RuleTesting {

    @Test func dataUsingUtf8Triggers() {
        assertLint(
            PreferNonOptionalDataInit.self,
            """
            let a = "foo".1️⃣data(using: .utf8)
            let b = string.2️⃣data(using: .utf8)
            let c = obj.property.3️⃣data(using: .utf8)
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'Data(<string>.utf8)' over '<string>.data(using: .utf8)' — UTF-8 encoding cannot fail"),
                FindingSpec("2️⃣", message: "prefer 'Data(<string>.utf8)' over '<string>.data(using: .utf8)' — UTF-8 encoding cannot fail"),
                FindingSpec("3️⃣", message: "prefer 'Data(<string>.utf8)' over '<string>.data(using: .utf8)' — UTF-8 encoding cannot fail"),
            ]
        )
    }

    @Test func nonUtf8EncodingsAccepted() {
        assertLint(
            PreferNonOptionalDataInit.self,
            """
            let a = "foo".data(using: .ascii)
            let b = string.data(using: .unicode)
            let c = string.data(using: .utf16)
            """,
            findings: []
        )
    }

    @Test func nonOptionalDataInitAccepted() {
        assertLint(
            PreferNonOptionalDataInit.self,
            """
            let a = Data("foo".utf8)
            let b = Data(string.utf8)
            """,
            findings: []
        )
    }
}
