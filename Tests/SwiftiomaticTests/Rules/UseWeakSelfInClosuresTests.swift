@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseWeakSelfInClosuresTests: RuleTesting {

    @Test func unownedCaptureTriggers() {
        assertLint(
            UseWeakSelfInClosures.self,
            """
            foo { [1️⃣unowned self] in _ }
            foo { [2️⃣unowned bar] in _ }
            foo { [bar, 3️⃣unowned self] in _ }
            """,
            findings: [
                FindingSpec("1️⃣", message: "prefer 'weak' over 'unowned' in closure captures to avoid crashes if the referent is deallocated"),
                FindingSpec("2️⃣", message: "prefer 'weak' over 'unowned' in closure captures to avoid crashes if the referent is deallocated"),
                FindingSpec("3️⃣", message: "prefer 'weak' over 'unowned' in closure captures to avoid crashes if the referent is deallocated"),
            ]
        )
    }

    @Test func weakCaptureAccepted() {
        assertLint(
            UseWeakSelfInClosures.self,
            """
            foo { [weak self] in _ }
            foo { [weak bar] in _ }
            foo { bar in _ }
            foo { $0 }
            """,
            findings: []
        )
    }

    @Test func unownedStoredPropertyAccepted() {
        assertLint(
            UseWeakSelfInClosures.self,
            """
            final class Second {
                unowned var value: First
                init(value: First) {
                    self.value = value
                }
            }
            """,
            findings: []
        )
    }
}
