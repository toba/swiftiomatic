import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoDroppedCaughtErrorTests: RuleTesting {
    private static let message =
        "keep the caught error in the error this 'catch' throws; store it in the new error or log it"

    @Test func implicitErrorDropped() {
        assertLint(
            NoDroppedCaughtError.self,
            """
            func load() throws(FontError) -> Table {
                do {
                    return try Parser.parse()
                } catch {
                    1️⃣throw FontError.invalidMathTable
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func boundErrorDropped() {
        assertLint(
            NoDroppedCaughtError.self,
            """
            func decode() throws {
                do {
                    try run()
                } catch let failure as DecodingError {
                    1️⃣throw AppError.decode
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func everyThrowInBranchesIsFlagged() {
        assertLint(
            NoDroppedCaughtError.self,
            """
            func run() throws {
                do {
                    try work()
                } catch {
                    if retry {
                        1️⃣throw AppError.retryFailed
                    } else {
                        2️⃣throw AppError.failed
                    }
                }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message),
                FindingSpec("2️⃣", message: Self.message),
            ]
        )
    }

    @Test func errorKeptDoesNotTrigger() {
        assertLint(
            NoDroppedCaughtError.self,
            """
            func run() throws {
                do { try work() } catch { throw AppError.failed(underlying: error) }
                do { try work() } catch { throw error }
                do { try work() } catch let e as URLError { throw AppError.network(e) }
                do { try work() } catch {
                    logger.error("work failed: \\(error)")
                    throw AppError.failed
                }
            }
            """,
            findings: []
        )
    }

    @Test func catchWithoutBindingDoesNotTrigger() {
        assertLint(
            NoDroppedCaughtError.self,
            """
            func run() throws {
                do { try work() } catch StoreError.notFound { throw AppError.missing }
                do { try work() } catch is CancellationError { throw AppError.cancelled }
            }
            """,
            findings: []
        )
    }

    @Test func throwInNestedScopeDoesNotTrigger() {
        assertLint(
            NoDroppedCaughtError.self,
            """
            func run() throws {
                do {
                    try work()
                } catch {
                    let fallback = { () throws in throw AppError.fallback }
                    func retry() throws { throw AppError.retry }
                    do { try fallback() } catch let inner { throw AppError.wrapped(inner) }
                    throw AppError.failed(error)
                }
            }
            """,
            findings: []
        )
    }

    @Test func memberWithSameNameIsNotAReference() {
        assertLint(
            NoDroppedCaughtError.self,
            """
            func run() throws {
                do {
                    try work()
                } catch {
                    1️⃣throw AppError.error
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }
}
