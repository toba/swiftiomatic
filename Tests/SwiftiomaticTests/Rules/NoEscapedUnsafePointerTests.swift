import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoEscapedUnsafePointerTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "the pointer from '\(name)' is valid only inside the closure. Returning it is a lifetime bug. Do the work inside the closure, or use a 'Span'"
    }

    @Test func shorthandArgumentFlagged() {
        assertLint(
            NoEscapedUnsafePointer.self,
            """
            self.bytes = source.1️⃣withUnsafeBytes { $0 }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("withUnsafeBytes"))]
        )
    }

    @Test func baseAddressFlagged() {
        assertLint(
            NoEscapedUnsafePointer.self,
            """
            let a = values.1️⃣withUnsafeBufferPointer { $0.baseAddress }
            let b = values.2️⃣withUnsafeMutableBufferPointer { $0.baseAddress! }
            let c = data.3️⃣withUnsafeMutableBytes { return $0.baseAddress }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("withUnsafeBufferPointer")),
                FindingSpec("2️⃣", message: Self.message("withUnsafeMutableBufferPointer")),
                FindingSpec("3️⃣", message: Self.message("withUnsafeMutableBytes")),
            ]
        )
    }

    @Test func namedParameterFlagged() {
        assertLint(
            NoEscapedUnsafePointer.self,
            """
            let a = values.1️⃣withUnsafeBufferPointer { buffer in buffer.baseAddress! }
            let b = 2️⃣withUnsafePointer(to: &value) { (pointer: UnsafePointer<Int>) in pointer }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("withUnsafeBufferPointer")),
                FindingSpec("2️⃣", message: Self.message("withUnsafePointer")),
            ]
        )
    }

    @Test func closureAsLastArgumentFlagged() {
        assertLint(
            NoEscapedUnsafePointer.self,
            """
            let p = 1️⃣withUnsafeMutablePointer(to: &value, { $0 })
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("withUnsafeMutablePointer"))]
        )
    }

    @Test func valueComputedFromPointerNotFlagged() {
        assertLint(
            NoEscapedUnsafePointer.self,
            """
            let word = data.withUnsafeBytes { $0.load(as: UInt32.self) }
            let count = values.withUnsafeBufferPointer { $0.count }
            let sum = values.withUnsafeBufferPointer { buffer in buffer.reduce(0, +) }
            """,
            findings: []
        )
    }

    @Test func multiStatementBodyNotFlagged() {
        assertLint(
            NoEscapedUnsafePointer.self,
            """
            data.withUnsafeBytes { raw in
              consume(raw)
              return raw.count
            }
            """,
            findings: []
        )
    }

    @Test func otherNameNotFlagged() {
        assertLint(
            NoEscapedUnsafePointer.self,
            """
            let first = values.map { $0 }
            let other = values.withContiguousStorageIfAvailable { $0 }
            """,
            findings: []
        )
    }

    @Test func otherIdentifierNotFlagged() {
        assertLint(
            NoEscapedUnsafePointer.self,
            """
            let a = values.withUnsafeBufferPointer { _ in fallback }
            let b = values.withUnsafeBufferPointer { buffer in other.baseAddress }
            """,
            findings: []
        )
    }
}
