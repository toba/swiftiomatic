@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoWholeCollectionChangeKeyTests: RuleTesting {
  private static func keyMessage(modifier: String, name: String) -> String {
    "'.\(modifier): \(name))' compares the whole collection '\(name)' on each update. Observe a small key that changes whenever the work must run, such as a revision or a count and IDs"
  }

  private static func sourceMessage(_ name: String) -> String {
    "'\(name)' is a collection that a change key compares whole. Give it a small key, or update the dependent state where '\(name)' changes"
  }

  @Test func guidanceIsShould() {
    #expect(NoWholeCollectionChangeKey.guidance == .should)
  }

  @Test func fetchAllArrayObservedByOnChangeFlagged() {
    assertLint(
      NoWholeCollectionChangeKey.self,
      """
      struct ProjectSettingsView: View {
        @FetchAll(Project.all) private var 1️⃣projects: [Project]
        @State private var takenNames: Set<String> = []

        var body: some View {
          TextField("Name", text: $draftName)
            .onChange(of: 2️⃣projects) { refreshTakenNames() }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.sourceMessage("projects")),
        FindingSpec("2️⃣", message: Self.keyMessage(modifier: "onChange(of", name: "projects")),
      ]
    )
  }

  @Test func taskIDOverDictionaryFlagged() {
    assertLint(
      NoWholeCollectionChangeKey.self,
      """
      struct Totals: View {
        let 1️⃣scores: [String: Int]

        var body: some View {
          Text("Totals")
            .task(id: 2️⃣self.scores) { await reload() }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.sourceMessage("scores")),
        FindingSpec("2️⃣", message: Self.keyMessage(modifier: "task(id", name: "self.scores")),
      ]
    )
  }

  @Test func sourceReportedOnceForTwoObservers() {
    assertLint(
      NoWholeCollectionChangeKey.self,
      """
      struct RouteList: View {
        @State private var 1️⃣routes = [Route]()

        var body: some View {
          List(routes) { RouteRow(route: $0) }
            .onChange(of: 2️⃣routes, initial: true) { _, new in stats = new.count }
            .task(id: 3️⃣routes) { await sync() }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.sourceMessage("routes")),
        FindingSpec("2️⃣", message: Self.keyMessage(modifier: "onChange(of", name: "routes")),
        FindingSpec("3️⃣", message: Self.keyMessage(modifier: "task(id", name: "routes")),
      ]
    )
  }

  @Test func queryArrayFlagged() {
    assertLint(
      NoWholeCollectionChangeKey.self,
      """
      struct Trips: View {
        @Query(sort: \\Trip.date) private var 1️⃣trips: [Trip]

        var body: some View {
          List { }
            .onChange(of: 2️⃣trips) { refresh() }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.sourceMessage("trips")),
        FindingSpec("2️⃣", message: Self.keyMessage(modifier: "onChange(of", name: "trips")),
      ]
    )
  }

  @Test func lightweightKeysNotFlagged() {
    assertLint(
      NoWholeCollectionChangeKey.self,
      """
      struct RouteList: View {
        let routes: [Route]
        let regionID: String
        @State private var revision = 0

        var body: some View {
          List(routes) { RouteRow(route: $0) }
            .onChange(of: routes.count) { refresh() }
            .onChange(of: revision) { refresh() }
            .task(id: regionID) { await load() }
        }
      }
      """,
      findings: []
    )
  }

  @Test func scalarAndUnknownTypesNotFlagged() {
    assertLint(
      NoWholeCollectionChangeKey.self,
      """
      struct Editor: View {
        @State private var name = ""
        @Binding var selection: Item.ID?
        var model: Model

        var body: some View {
          TextField("Name", text: $name)
            .onChange(of: name) { save() }
            .onChange(of: selection) { sync() }
            .onChange(of: model) { sync() }
        }
      }
      """,
      findings: []
    )
  }

  @Test func propertyOutsideViewNotFlagged() {
    assertLint(
      NoWholeCollectionChangeKey.self,
      """
      final class Store {
        var items: [Item] = []

        func observe() -> some View {
          Color.clear.onChange(of: items) { }
        }
      }
      """,
      findings: []
    )
  }

  @Test func localShadowNotFlagged() {
    assertLint(
      NoWholeCollectionChangeKey.self,
      """
      struct RouteList: View {
        let routes: [Route]

        var body: some View {
          let routes = routes.map(\\.id)
          List { }
            .onChange(of: routes) { refresh() }
        }
      }
      """,
      findings: []
    )
  }
}
