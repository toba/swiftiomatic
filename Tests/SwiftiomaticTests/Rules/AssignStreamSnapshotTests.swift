import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct AssignStreamSnapshotTests: RuleTesting {
    private static func message(_ snapshot: String) -> String {
        "'streamResponse' yields cumulative snapshots; assign '\(snapshot)' instead of appending it"
    }

    @Test func plusEqualsFlagged() {
        assertLint(
            AssignStreamSnapshot.self,
            """
            func run() async throws {
                for try await snapshot in session.streamResponse(to: prompt) {
                    1️⃣text += snapshot.content
                }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("snapshot"))]
        )
    }

    @Test func appendFlagged() {
        assertLint(
            AssignStreamSnapshot.self,
            """
            func run() async throws {
                let stream = session.streamResponse(to: prompt, generating: Itinerary.self)
                for try await partial in self.session.streamResponse(to: prompt) {
                    await MainActor.run {
                        1️⃣output.append(partial.content)
                        2️⃣parts.append(contentsOf: [partial.content])
                    }
                }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("partial")),
                FindingSpec("2️⃣", message: Self.message("partial")),
            ]
        )
    }

    @Test func assignmentNotFlagged() {
        assertLint(
            AssignStreamSnapshot.self,
            """
            func run() async throws {
                for try await snapshot in session.streamResponse(to: prompt) {
                    text = snapshot.content
                    count += 1
                    log.append("tick")
                }
            }
            """,
            findings: []
        )
    }

    @Test func otherStreamNotFlagged() {
        assertLint(
            AssignStreamSnapshot.self,
            """
            func run() async throws {
                for try await chunk in client.streamDeltas(to: prompt) {
                    text += chunk.text
                }
                for try await line in url.lines {
                    lines.append(line)
                }
            }
            """,
            findings: []
        )
    }

    @Test func memberNamedLikeSnapshotNotFlagged() {
        assertLint(
            AssignStreamSnapshot.self,
            """
            func run() async throws {
                for try await snapshot in session.streamResponse(to: prompt) {
                    text = snapshot.content
                    history.append(state.snapshot)
                }
            }
            """,
            findings: []
        )
    }
}
