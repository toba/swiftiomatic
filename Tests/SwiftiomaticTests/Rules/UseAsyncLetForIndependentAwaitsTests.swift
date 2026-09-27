@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseAsyncLetForIndependentAwaitsTests: RuleTesting {
  private static let message =
    "these awaits do not use each other's results but run one after another. Start them together with 'async let'"

  @Test func guidanceIsConsider() {
    #expect(UseAsyncLetForIndependentAwaits.guidance == .consider)
  }

  @Test func independentBindingsFlagged() {
    assertLint(
      UseAsyncLetForIndependentAwaits.self,
      """
      enum Report {
        static func current(in database: Database) async throws -> [Row] {
          1️⃣let statuses = try await SyncCoordinator.shared.zoneStatuses()
          let rows = try await database.read { db in try ProjectName.rows.fetchAll(from: db) }
          let names = rows.keyed(by: \\.id, value: \\.name)
          return statuses.map { Row($0, names) }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func threeIndependentBindingsFlaggedOnce() {
    assertLint(
      UseAsyncLetForIndependentAwaits.self,
      """
      func load() async {
        1️⃣let flowers = await fetchFlowers()
        let pollinators = await fetchPollinators()
        let soils = await fetchSoils()
        show(flowers, pollinators, soils)
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func dependentBindingNotFlagged() {
    assertLint(
      UseAsyncLetForIndependentAwaits.self,
      """
      func load() async throws {
        let user = try await fetchUser()
        let posts = try await fetchPosts(for: user.id)
        show(posts)
      }
      """
    )
  }

  @Test func orderedSideEffectsNotFlagged() {
    assertLint(
      UseAsyncLetForIndependentAwaits.self,
      """
      func sync() async throws {
        try await store.save()
        let items = try await store.load()
        show(items)
      }
      """
    )
  }

  @Test func asyncLetNotFlagged() {
    assertLint(
      UseAsyncLetForIndependentAwaits.self,
      """
      func load() async {
        async let flowers = fetchFlowers()
        async let pollinators = fetchPollinators()
        let (a, b) = await (flowers, pollinators)
        show(a, b)
      }
      """
    )
  }

  @Test func separatedAwaitsNotFlagged() {
    assertLint(
      UseAsyncLetForIndependentAwaits.self,
      """
      func load() async {
        let flowers = await fetchFlowers()
        show(flowers)
        let pollinators = await fetchPollinators()
        show(pollinators)
      }
      """
    )
  }

  @Test func sleepNotFlagged() {
    assertLint(
      UseAsyncLetForIndependentAwaits.self,
      """
      func load() async throws {
        let pause: Void = try await Task.sleep(for: .seconds(1))
        let flowers = await fetchFlowers()
        show(flowers, pause)
      }
      """
    )
  }
}
