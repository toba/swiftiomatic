import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoModelReturnFromModelActorTests: RuleTesting {
    private static func message(_ method: String, _ model: String) -> String {
        "'\(method)' returns the '@Model' type '\(model)' from a '@ModelActor'; return 'PersistentIdentifier' values or Sendable copies instead"
    }

    @Test func sameFileModelFlagged() {
        assertLint(
            NoModelReturnFromModelActor.self,
            """
            @Model final class Trip {
                var name: String = ""
            }

            @ModelActor
            actor TripStore {
                func trip(named name: String) throws -> 1️⃣Trip? { nil }
                func allTrips() throws -> 2️⃣[Trip] { [] }
                func firstTrip() -> 3️⃣Trip { fatalError() }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("trip", "Trip")),
                FindingSpec("2️⃣", message: Self.message("allTrips", "Trip")),
                FindingSpec("3️⃣", message: Self.message("firstTrip", "Trip")),
            ]
        )
    }

    @Test func otherFileModelFlagged() {
        assertLint(
            NoModelReturnFromModelActor.self,
            """
            @ModelActor
            actor TripStore {
                func allTrips() async throws -> 1️⃣Array<Trip> { [] }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("allTrips", "Trip"))],
            otherFiles: [
                "/tmp/Trip.swift": """
                @SwiftData.Model
                final class Trip {
                    var name: String = ""
                }
                """
            ]
        )
    }

    @Test func identifiersNotFlagged() {
        assertLint(
            NoModelReturnFromModelActor.self,
            """
            @Model final class Trip {}

            @ModelActor
            actor TripStore {
                func allTrips() throws -> [PersistentIdentifier] { [] }
                func count() throws -> Int { 0 }
                private func fetch() throws -> [Trip] { [] }
            }
            """,
            findings: []
        )
    }

    @Test func plainActorNotFlagged() {
        assertLint(
            NoModelReturnFromModelActor.self,
            """
            @Model final class Trip {}

            actor TripCache {
                func allTrips() -> [Trip] { [] }
            }
            """,
            findings: []
        )
    }

    @Test func nonModelTypeNotFlagged() {
        assertLint(
            NoModelReturnFromModelActor.self,
            """
            @ModelActor
            actor TripStore {
                func summary() throws -> TripSummary { TripSummary() }
            }
            """,
            findings: [],
            otherFiles: [
                "/tmp/TripSummary.swift": """
                struct TripSummary: Sendable {}
                final class Trip {}
                """
            ]
        )
    }
}
