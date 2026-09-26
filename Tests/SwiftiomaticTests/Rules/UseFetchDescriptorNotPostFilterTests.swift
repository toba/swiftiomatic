import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseFetchDescriptorNotPostFilterTests: RuleTesting {
    private static func message(_ operation: String, _ fix: String) -> String {
        "'\(operation)' runs in memory on every fetched model; use \(fix) in the fetch"
    }
    private static let predicateFix = "a '#Predicate' on the 'FetchDescriptor'"
    private static let limitFix = "'fetchLimit' on the 'FetchDescriptor'"
    private static let countFix = "'fetchCount(_:)'"
    private static let fetchNote = "the fetch that loads every matching model"

    @Test func chainedFilterFlagged() {
        assertLint(
            UseFetchDescriptorNotPostFilter.self,
            """
            func load(context: ModelContext) throws -> [Trip] {
              try 2️⃣context.fetch(FetchDescriptor<Trip>()).1️⃣filter { $0.isActive }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("filter", Self.predicateFix),
                    notes: [NoteSpec("2️⃣", message: Self.fetchNote)]
                )
            ]
        )
    }

    @Test func chainedCountAndPrefixFlagged() {
        assertLint(
            UseFetchDescriptorNotPostFilter.self,
            """
            func load() throws {
              let n = try 2️⃣modelContext.fetch(descriptor).1️⃣count
              let top = try 4️⃣modelContext.fetch(descriptor).3️⃣prefix(10)
              let first = try 6️⃣modelContext.fetch(descriptor).5️⃣first(where: { $0.isActive })
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("count", Self.countFix),
                    notes: [NoteSpec("2️⃣", message: Self.fetchNote)]
                ),
                FindingSpec(
                    "3️⃣",
                    message: Self.message("prefix", Self.limitFix),
                    notes: [NoteSpec("4️⃣", message: Self.fetchNote)]
                ),
                FindingSpec(
                    "5️⃣",
                    message: Self.message("first(where:)", Self.predicateFix),
                    notes: [NoteSpec("6️⃣", message: Self.fetchNote)]
                ),
            ]
        )
    }

    @Test func localBindingFlagged() {
        assertLint(
            UseFetchDescriptorNotPostFilter.self,
            """
            func load(context: ModelContext) throws -> Int {
              let trips = try 2️⃣context.fetch(FetchDescriptor<Trip>())
              let active = trips.1️⃣filter { $0.isActive }
              return trips.3️⃣count + active.count
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("filter", Self.predicateFix),
                    notes: [NoteSpec("2️⃣", message: Self.fetchNote)]
                ),
                FindingSpec(
                    "3️⃣",
                    message: Self.message("count", Self.countFix),
                    notes: [NoteSpec("2️⃣", message: Self.fetchNote)]
                ),
            ]
        )
    }

    @Test func otherScopeNotFlagged() {
        assertLint(
            UseFetchDescriptorNotPostFilter.self,
            """
            func load(context: ModelContext) throws {
              let trips = try context.fetch(FetchDescriptor<Trip>())
              func inner(trips: [Trip]) -> Int { trips.count }
              _ = inner(trips: trips)
            }
            func other(trips: [Trip]) -> Int { trips.count }
            """,
            findings: []
        )
    }

    @Test func localWithOtherUsesNotFlagged() {
        assertLint(
            UseFetchDescriptorNotPostFilter.self,
            """
            func load(context: ModelContext) throws {
              let trips = try context.fetch(FetchDescriptor<Trip>())
              show(trips)
              print(trips.count)
            }
            """,
            findings: []
        )
    }

    @Test func networkFetchNotFlagged() {
        assertLint(
            UseFetchDescriptorNotPostFilter.self,
            """
            func load(api: API) async throws {
              let items = try await api.fetch(request).filter { $0.isActive }
            }
            """,
            findings: []
        )
    }

    @Test func reassignedLocalNotFlagged() {
        assertLint(
            UseFetchDescriptorNotPostFilter.self,
            """
            func load(context: ModelContext) throws {
              var trips = try context.fetch(FetchDescriptor<Trip>())
              trips = []
              _ = trips.count
            }
            """,
            findings: []
        )
    }

    @Test func fetchCountAndOtherMembersNotFlagged() {
        assertLint(
            UseFetchDescriptorNotPostFilter.self,
            """
            func load(context: ModelContext) throws {
              let n = try context.fetchCount(descriptor)
              let trips = try context.fetch(descriptor)
              for trip in trips { print(trip) }
              _ = trips.map(\\.name)
              _ = try context.fetch(descriptor, batchSize: 10).isEmpty
              _ = fetch(descriptor).count
            }
            """,
            findings: []
        )
    }
}
