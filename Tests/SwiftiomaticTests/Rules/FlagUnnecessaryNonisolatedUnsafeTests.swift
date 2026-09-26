import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagUnnecessaryNonisolatedUnsafeTests: RuleTesting {
    private static let message =
        "'nonisolated(unsafe)' is not needed on a 'let' initialized with a literal — the value is already 'Sendable'"

    @Test func integerLiteralFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            1️⃣nonisolated(unsafe) let maximumRetryCount = 3
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func stringLiteralFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            1️⃣nonisolated(unsafe) let separator = ", "
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func arrayLiteralFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            1️⃣nonisolated(unsafe) let allowedPorts: [Int] = [80, 443]
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func mutableGlobalNotFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            nonisolated(unsafe) var requestCount = 0
            """,
            findings: []
        )
    }

    @Test func constructedValueNotFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            nonisolated(unsafe) let cache = NSCache<NSString, NSData>()
            """,
            findings: []
        )
    }

    @Test func plainLetNotFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            let maximumRetryCount = 3
            """,
            findings: []
        )
    }

    @Test func regexLiteralNotFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            nonisolated(unsafe) let pattern = /[a-z]+/
            """,
            findings: []
        )
    }

    @Test func extendedRegexLiteralNotFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            nonisolated(unsafe) let pattern = #/[a-z]+/#
            """,
            findings: []
        )
    }

    @Test func tryRegexNotFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            nonisolated(unsafe) let pattern = try! Regex("[a-z]+")
            """,
            findings: []
        )
    }

    @Test func annotatedRegexNotFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            nonisolated(unsafe) let pattern: Regex<Substring> = /[a-z]+/
            """,
            findings: []
        )
    }

    @Test func regularExpressionNotFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            nonisolated(unsafe) let pattern = try! NSRegularExpression(pattern: "[a-z]+")
            """,
            findings: []
        )
    }

    @Test func classInstanceNotFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            nonisolated(unsafe) let formatter = DateFormatter()
            """,
            findings: []
        )
    }

    @Test func literalForNonSendableClassNotFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            nonisolated(unsafe) let items: NSMutableArray = [1, 2]
            """,
            findings: []
        )
    }

    @Test func literalForUnknownTypeNotFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            nonisolated(unsafe) let counter: Counter = 0
            """,
            findings: []
        )
    }

    @Test func literalForStandardTypeFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            1️⃣nonisolated(unsafe) let timeout: Double = 2.5
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func literalForOptionalStandardTypeFlagged() {
        assertLint(
            FlagUnnecessaryNonisolatedUnsafe.self,
            """
            1️⃣nonisolated(unsafe) let names: [String: Int]? = ["a": 1]
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }
}
