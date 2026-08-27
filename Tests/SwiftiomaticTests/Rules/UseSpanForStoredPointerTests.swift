import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseSpanForStoredPointerTests: RuleTesting {
    private static func message(_ pointer: String, _ span: String) -> String {
        "a stored '\(pointer)' outlives nothing the compiler can see — store a '\(span)', mark the type '~Escapable', and annotate 'init' with '@_lifetime(borrow source)'"
    }

    @Test func storedRawBufferPointerFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Lexer {
              private let bytes: 1️⃣UnsafeRawBufferPointer
              private let owner: Data
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("UnsafeRawBufferPointer", "RawSpan"))]
        )
    }

    @Test func storedTypedPointerFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Cursor {
              let head: 1️⃣UnsafePointer<UInt8>
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("UnsafePointer", "Span"))]
        )
    }

    @Test func storedMutableBufferPointerFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Sink {
              var slots: 1️⃣UnsafeMutableBufferPointer<Int>
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("UnsafeMutableBufferPointer", "MutableSpan"))
            ]
        )
    }

    @Test func storedOptionalPointerFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Reader {
              var base: 1️⃣UnsafeMutableRawPointer?
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("UnsafeMutableRawPointer", "MutableRawSpan"))
            ]
        )
    }

    @Test func parameterNotFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            func parse(_ bytes: UnsafeRawBufferPointer) {
              consume(bytes)
            }
            """,
            findings: []
        )
    }

    @Test func localVariableNotFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Lexer {
              func scan(_ data: Data) {
                let local: UnsafeRawBufferPointer = view(of: data)
                consume(local)
              }
            }
            """,
            findings: []
        )
    }

    @Test func computedPropertyNotFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Lexer {
              var bytes: UnsafeRawBufferPointer { view(of: owner) }
            }
            """,
            findings: []
        )
    }

    @Test func ownedMemoryNotFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            final class Arena {
              private let storage: UnsafeMutableRawPointer

              init(size: Int) {
                storage = .allocate(byteCount: size, alignment: 8)
              }

              deinit {
                storage.deallocate()
              }
            }
            """,
            findings: []
        )
    }

    @Test func nonPointerPropertyNotFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Lexer {
              private let bytes: RawSpan
              private let count: Int
            }
            """,
            findings: []
        )
    }
}
