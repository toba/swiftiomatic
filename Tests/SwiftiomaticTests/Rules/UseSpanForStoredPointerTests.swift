import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseSpanForStoredPointerTests: RuleTesting {
    private static func message(_ pointer: String, _ span: String) -> String {
        "a stored '\(pointer)' outlives nothing the compiler can see — store a '\(span)', mark the type '~Escapable', and annotate 'init' with '@_lifetime(borrow source)'"
    }

    private static func bareMessage(_ pointer: String, _ span: String) -> String {
        "a stored '\(pointer)' outlives nothing the compiler can see, and it carries no count — pair it with its count in one '\(span)', mark the type '~Escapable', and annotate 'init' with '@_lifetime(borrow source)'"
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
              let count: Int
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.bareMessage("UnsafePointer", "Span"))]
        )
    }

    @Test func storedMutableBufferPointerFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Sink {
              var slots: 1️⃣UnsafeMutableBufferPointer<Int>

              func fill(_ value: Int) {
                slots[0] = value
              }
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
                FindingSpec("1️⃣", message: Self.bareMessage("UnsafeMutableRawPointer", "RawSpan"))
            ]
        )
    }

    @Test func conformingTypeNotFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct SQLiteFunctionDecoder: QueryDecoder {
              let arguments: UnsafeMutablePointer<OpaquePointer?>?
              let argumentCount: Int32
              var currentIndex: Int32 = 0
            }
            """,
            findings: []
        )
    }

    @Test func subclassNotFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            final class Window: NSWindow {
              let bytes: UnsafeRawBufferPointer
            }
            """,
            findings: []
        )
    }

    @Test func suppressedConformanceStillFlagged() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Lexer: ~Copyable {
              private let bytes: 1️⃣UnsafeRawBufferPointer
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("UnsafeRawBufferPointer", "RawSpan"))]
        )
    }

    @Test func readOnlyMutablePointerNamesSpan() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Cursor {
              let head: 1️⃣UnsafeMutablePointer<UInt8>
              let count: Int

              func first() -> UInt8 {
                head[0]
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.bareMessage("UnsafeMutablePointer", "Span"))]
        )
    }

    @Test func readOnlyMutableBufferPointerNamesSpan() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Sink {
              var slots: 1️⃣UnsafeMutableBufferPointer<Int>
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("UnsafeMutableBufferPointer", "Span"))
            ]
        )
    }

    @Test func writeThroughPointeeNamesMutableSpan() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Box {
              let value: 1️⃣UnsafeMutablePointer<Int>

              func bump() {
                value.pointee += 1
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.bareMessage("UnsafeMutablePointer", "MutableSpan"))
            ]
        )
    }

    @Test func writeThroughSelfSubscriptNamesMutableSpan() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Sink {
              var slots: 1️⃣UnsafeMutableBufferPointer<Int>

              func fill(_ value: Int) {
                self.slots[0] = value
              }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("UnsafeMutableBufferPointer", "MutableSpan"))
            ]
        )
    }

    @Test func mutatingPointerCallNamesMutableSpan() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Writer {
              let base: 1️⃣UnsafeMutableRawPointer

              func store(_ value: Int) {
                base.storeBytes(of: value, as: Int.self)
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.bareMessage("UnsafeMutableRawPointer", "MutableRawSpan"))
            ]
        )
    }

    @Test func readThroughSubscriptNamesSpan() {
        assertLint(
            UseSpanForStoredPointer.self,
            """
            struct Decoder {
              let arguments: 1️⃣UnsafeMutablePointer<Int>?
              let argumentCount: Int32

              func value(at index: Int) -> Int? {
                arguments?[index]
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.bareMessage("UnsafeMutablePointer", "Span"))]
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
