package import Testing
package import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagNonEquatableObservablePropertyTests: RuleTesting {
    private static func message(_ name: String, _ type: String) -> String {
        "'\(name)' stores '\(type)', which is not 'Equatable', so each assignment notifies the views that read it, also when the value did not change. Give '\(type)' a meaningful 'Equatable' conformance"
    }

    @Test func guidanceIsConsider() {
        #expect(FlagNonEquatableObservableProperty.guidance == .consider)
    }

    /// The Thesis `SearchState` shape: the element type is declared in another file.
    @Test func otherFileNonEquatableTypeFlagged() {
        assertLint(
            FlagNonEquatableObservableProperty.self,
            """
            @Observable final class SearchState {
              1️⃣var results: [NodeDescriptor] = []
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("results", "NodeDescriptor"))],
            otherFiles: [
                "/tmp/Core/NodeDescriptor.swift": """
                public struct NodeDescriptor: Identifiable {
                  public var id: Int
                  public var title: String
                }
                """
            ]
        )
    }

    /// The Thesis `ActivityCenter` and musup `PlayerController` shapes.
    @Test func nonEquatableSameFileTypesFlagged() {
        assertLint(
            FlagNonEquatableObservableProperty.self,
            """
            struct ActivityTask: Identifiable {
              let id: UUID
              var title: String
            }

            final class Token {}

            struct Session {
              let player: Player
            }

            @Observable @MainActor final class ActivityCenter {
              1️⃣private(set) var tasks: [ActivityTask] = []
              2️⃣private var keyedTokens: [String: Token] = [:]
              3️⃣private var session: Session?
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("tasks", "ActivityTask")),
                FindingSpec("2️⃣", message: Self.message("keyedTokens", "Token")),
                FindingSpec("3️⃣", message: Self.message("session", "Session")),
            ]
        )
    }

    @Test func equatableUnknownAndIgnoredPropertiesNotFlagged() {
        assertLint(
            FlagNonEquatableObservableProperty.self,
            """
            struct Sighting: Hashable { let id: UUID }
            struct Row { let id: Int }
            extension Row: Equatable {}
            enum Mode { case idle, busy }
            enum Phase { case loading(Int), done }
            extension Phase: Comparable {}
            @Observable final class Child {}

            @Observable final class Model {
              var sightings: [Sighting] = []
              var rows: Set<Row> = []
              var mode: Mode = .idle
              var phase: Phase?
              var child: Child?
              var results: [NodeDescriptor] = []
              var name = ""
              let fixed: Row
              @ObservationIgnored var cache: Row?
              static var shared: Row?
              var count: Int { rows.count }
            }

            final class Plain {
              var row: Row?
            }
            """,
            findings: []
        )
    }
}
