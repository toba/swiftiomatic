import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoEnumeratedOffsetIdentityTests: RuleTesting {
    private static let message =
        "'id: \\.offset' ties each row to its position, so an insert, a removal or a move gives rows the wrong identity and state. Use 'id: \\.element.id' and keep the offset for display"

    @Test func guidanceIsShouldNot() { #expect(NoEnumeratedOffsetIdentity.guidance == .shouldNot) }

    /// The Thesis `ReferenceContributorsEditor` and jig `CitationsSheet` shapes.
    @Test func offsetIdentityOverEnumeratedFlagged() {
        assertLint(
            NoEnumeratedOffsetIdentity.self,
            #"""
            struct Editor: View {
              var body: some View {
                ForEach(Array(contributors.enumerated()), 1️⃣id: \.offset) { index, person in
                  Row(person) { contributors.remove(at: index) }
                }
                ForEach(group.alerts.enumerated(), 2️⃣id: \.offset) { _, alert in Text(alert.text) }
                List(Array(steps.enumerated()), 3️⃣id: \.offset) { pair in Text(pair.element) }
              }
            }
            """#,
            findings: [
                FindingSpec("1️⃣", message: Self.message),
                FindingSpec("2️⃣", message: Self.message),
                FindingSpec("3️⃣", message: Self.message),
            ]
        )
    }

    @Test func stableIdentityAndLiteralsNotFlagged() {
        assertLint(
            NoEnumeratedOffsetIdentity.self,
            #"""
            struct Steps: View {
              var body: some View {
                ForEach(Array(steps.enumerated()), id: \.element.id) { offset, step in Text(step.title) }
                ForEach(steps.enumerated(), id: \.element) { offset, step in Text(step) }
                ForEach(Array(["Mon", "Tue", "Wed"].enumerated()), id: \.offset) { _, day in Text(day) }
                ForEach(0..<count, id: \.self) { Text("\($0)") }
                ForEach(markers, id: \.offset) { Text($0.label) }
              }
            }
            """#,
            findings: []
        )
    }
}
