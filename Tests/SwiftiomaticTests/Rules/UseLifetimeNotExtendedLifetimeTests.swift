import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseLifetimeNotExtendedLifetimeTests: RuleTesting {
    private static let message =
        "'withExtendedLifetime' states the dependency at the call site — move it into the signature with '@_lifetime(borrow source)' so the compiler enforces it for every caller"

    @Test func extendedLifetimeFlagged() {
        assertLint(
            UseLifetimeNotExtendedLifetime.self,
            """
            func read(_ session: Session) {
              1️⃣withExtendedLifetime(session) { parse(pointer) }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func extendedLifetimeWithTrailingClosureFlagged() {
        assertLint(
            UseLifetimeNotExtendedLifetime.self,
            """
            func read(_ session: Session) -> Int {
              1️⃣withExtendedLifetime(session) {
                count(pointer)
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func lifetimeAnnotationNotFlagged() {
        assertLint(
            UseLifetimeNotExtendedLifetime.self,
            """
            @_lifetime(borrow session)
            func view(of session: Session) -> RawSpan {
              session.bytes
            }
            """,
            findings: []
        )
    }

    @Test func memberNamedWithExtendedLifetimeNotFlagged() {
        assertLint(
            UseLifetimeNotExtendedLifetime.self,
            """
            func read(_ session: Session) {
              session.withExtendedLifetime { parse(pointer) }
            }
            """,
            findings: []
        )
    }
}
