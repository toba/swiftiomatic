import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagDiscardedResultTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "the result of '\(name)()' is discarded; mark the function '@discardableResult' if callers often ignore its result"
    }

    @Test func discardOfFunctionDeclaredInFile() {
        assertLint(
            FlagDiscardedResult.self,
            """
            struct Parser {
                mutating func nextCharacter() -> Character {
                    index += 1
                    return string[index]
                }

                mutating func skipBracket() {
                    1️⃣_ = nextCharacter()
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("nextCharacter"))]
        )
    }

    @Test func discardOfSelfCallDeclaredElsewhere() {
        assertLint(
            FlagDiscardedResult.self,
            """
            extension Parser {
                mutating func skip() {
                    1️⃣_ = self.readCommand()
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("readCommand"))]
        )
    }

    @Test func repeatedBareDiscardDeclaredElsewhere() {
        assertLint(
            FlagDiscardedResult.self,
            """
            extension Parser {
                mutating func readOptions() {
                    1️⃣_ = nextCharacter()  // consume '['
                    if hasCharacters { 2️⃣_ = try nextCharacter() }
                }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("nextCharacter")),
                FindingSpec("2️⃣", message: Self.message("nextCharacter")),
            ]
        )
    }

    @Test func singleBareDiscardDeclaredElsewhereIsIgnored() {
        assertLint(
            FlagDiscardedResult.self,
            """
            func shutdown(fd: Int32) {
                _ = close(fd)
            }
            """,
            findings: []
        )
    }

    @Test func discardableResultFunctionIsIgnored() {
        assertLint(
            FlagDiscardedResult.self,
            """
            struct Parser {
                @discardableResult
                mutating func nextCharacter() -> Character { string[index] }

                mutating func skip() {
                    _ = nextCharacter()
                    _ = nextCharacter()
                }
            }
            """,
            findings: []
        )
    }

    @Test func otherReceiversAndTypesAreIgnored() {
        assertLint(
            FlagDiscardedResult.self,
            """
            func run() {
                _ = parser.nextCharacter()
                _ = parser.nextCharacter()
                _ = Model()
                _ = Model()
                _ = value
                let x = nextCharacter()
            }
            """,
            findings: []
        )
    }
}
