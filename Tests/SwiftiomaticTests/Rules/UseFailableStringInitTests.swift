@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseFailableStringInitTests: RuleTesting {

    @Test func stringDecodingUtf8Triggers() {
        assertLint(
            UseFailableStringInit.self,
            """
            let a = 1️⃣String(decoding: data, as: UTF8.self)
            let b = 2️⃣String.init(decoding: data, as: UTF8.self)
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer failable 'String(bytes:encoding:)' over 'String(decoding:as: UTF8.self)' which silently substitutes invalid bytes"),
                FindingSpec("2️⃣", message: "prefer failable 'String(bytes:encoding:)' over 'String(decoding:as: UTF8.self)' which silently substitutes invalid bytes"),
            ]
        )
    }

    @Test func failableInitAccepted() {
        assertLint(
            UseFailableStringInit.self,
            """
            let a = String(data: data, encoding: .utf8)
            let b = String(bytes: data, encoding: .utf8)
            """,
            findings: []
        )
    }

    @Test func nonUtf8CodecAccepted() {
        assertLint(
            UseFailableStringInit.self,
            """
            let a = String(decoding: data, as: UTF16.self)
            let b = String.init(decoding: data, as: UTF32.self)
            """,
            findings: []
        )
    }

    @Test func nonStringInitAccepted() {
        assertLint(
            UseFailableStringInit.self,
            """
            let a: Int = .init(decoding: data, as: UTF8.self)
            let b = Foo(decoding: data, as: UTF8.self)
            """,
            findings: []
        )
    }
}
