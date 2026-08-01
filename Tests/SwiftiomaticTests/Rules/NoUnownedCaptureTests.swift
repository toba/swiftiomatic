import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoUnownedCaptureTests: RuleTesting {
    private func config(allowExplicitUnsafeUnowned: Bool) -> Configuration {
        let ruleName = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(
            NoUnownedCapture.self)]
            ?? "noUnownedCapture"
        var c = Configuration.forTesting(enabledRule: ruleName)
        c[NoUnownedCapture.self] = NoUnownedCaptureConfiguration()
        c[NoUnownedCapture.self].allowExplicitUnsafeUnowned = allowExplicitUnsafeUnowned
        return c
    }

    private static let message =
        "avoid `unowned` in a closure capture list; if the referent is deallocated before the closure runs, access crashes (or reads freed memory with `unowned(unsafe)`) — prefer `[weak …]` and guard the optional"

    @Test func bareUnownedSelfFlagged() {
        assertLint(
            NoUnownedCapture.self,
            """
            foo { [1️⃣unowned self] in _ = self }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func bareUnownedNameFlagged() {
        assertLint(
            NoUnownedCapture.self,
            """
            foo { [1️⃣unowned bar] in _ = bar }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func unownedSafeFlagged() {
        // `unowned(safe)` traps just like bare `unowned` — always reported.
        assertLint(
            NoUnownedCapture.self,
            """
            foo { [1️⃣unowned(safe) self] in _ = self }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func unownedInMixedListFlagged() {
        assertLint(
            NoUnownedCapture.self,
            """
            foo { [bar, 1️⃣unowned self] in _ = self }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func unownedUnsafeFlaggedByDefault() {
        assertLint(
            NoUnownedCapture.self,
            """
            foo { [1️⃣unowned(unsafe) self] in _ = self }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func unownedUnsafeAllowedWhenConfigured() {
        // Spelling `(unsafe)` in full is a deliberate opt-in; not reported when the flag is set.
        assertLint(
            NoUnownedCapture.self,
            """
            foo { [unowned(unsafe) self] in _ = self }
            """,
            findings: [],
            configuration: config(allowExplicitUnsafeUnowned: true)
        )
    }

    @Test func unownedSafeStillFlaggedWhenUnsafeAllowed() {
        // The allow flag only exempts `(unsafe)` — `unowned(safe)` remains a violation.
        assertLint(
            NoUnownedCapture.self,
            """
            foo { [1️⃣unowned(safe) self] in _ = self }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)],
            configuration: config(allowExplicitUnsafeUnowned: true)
        )
    }

    @Test func bareUnownedStillFlaggedWhenUnsafeAllowed() {
        assertLint(
            NoUnownedCapture.self,
            """
            foo { [1️⃣unowned self] in _ = self }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)],
            configuration: config(allowExplicitUnsafeUnowned: true)
        )
    }

    @Test func weakCaptureNotFlagged() {
        assertLint(
            NoUnownedCapture.self,
            """
            foo { [weak self] in _ = self }
            """,
            findings: []
        )
    }

    @Test func plainCaptureNotFlagged() {
        assertLint(
            NoUnownedCapture.self,
            """
            foo { [self] in _ = self }
            """,
            findings: []
        )
    }

    @Test func noCaptureListNotFlagged() {
        assertLint(
            NoUnownedCapture.self,
            """
            foo { bar in _ = bar }
            """,
            findings: []
        )
    }
}
