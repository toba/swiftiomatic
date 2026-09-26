@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoWorkInViewInitializerTests: RuleTesting {
  private static let message =
    "This view initializer does work. A parent re-creates the view on each of its updates, so the work repeats. Store the inputs and do the work in 'body' or in a model"

  @Test func guidanceIsConsider() {
    #expect(NoWorkInViewInitializer.guidance == .consider)
  }

  @Test func enumPickerFilteringFlagged() {
    assertLint(
      NoWorkInViewInitializer.self,
      """
      public struct EnumPicker<Item: Pickable>: View {
        @Binding private var selection: Item?
        private let label: LocalizedStringKey
        private let presentable: [Item]

        public init(_ label: LocalizedStringKey, selection: Binding<Item?>, exclude: [Item] = []) {
          self.label = label
          1️⃣presentable = Item.allCases(excluding: exclude)
          _selection = selection
        }

        public var body: some View { Text(label) }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func localBindingAndCallFlagged() {
    assertLint(
      NoWorkInViewInitializer.self,
      """
      struct Chart: View {
        let points: [Point]

        init(values: [Double]) {
          1️⃣let sorted = values.sorted()
          2️⃣points = sorted.map(Point.init)
          3️⃣print(points.count)
        }

        var body: some View { Text("x") }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message),
        FindingSpec("2️⃣", message: Self.message),
        FindingSpec("3️⃣", message: Self.message),
      ]
    )
  }

  @Test func popoverPickerBuilderCallNotFlagged() {
    assertLint(
      NoWorkInViewInitializer.self,
      """
      public struct PopoverPicker<Popover: View>: View {
        private var label: LocalizedStringKey
        private var popover: Popover
        private var description: String
        private let popoverFrame: ViewFrameIntent?

        public init(
          _ label: LocalizedStringKey,
          description: String,
          popoverFrame: ViewFrameIntent? = nil,
          @ViewBuilder popover: () -> Popover
        ) {
          self.label = label
          self.popover = popover()
          self.description = description
          self.popoverFrame = popoverFrame
        }

        public var body: some View { popover }
      }
      """
    )
  }

  @Test func storedBuilderAndWrapperSetupNotFlagged() {
    assertLint(
      NoWorkInViewInitializer.self,
      """
      public struct ConditionalScrollView<Content: View>: View {
        public var scrollable: Bool
        @ViewBuilder public var content: (ScrollViewProxy?) -> Content
        @State private var count: Int
        @Binding var selection: String
        var mode: Mode
        var limit: Int?

        public init(
          scrollable: Bool,
          start: Int,
          selection: Binding<String>,
          @ContentBuilder content: @escaping (ScrollViewProxy?) -> Content
        ) {
          self.scrollable = scrollable
          self.content = content
          _count = State(initialValue: start)
          _selection = selection
          mode = .automatic
          limit = nil
        }

        public var body: some View { content(nil) }
      }
      """
    )
  }

  @Test func delegatingInitNotFlagged() {
    assertLint(
      NoWorkInViewInitializer.self,
      """
      struct Label: View {
        let title: String

        init(_ title: String) { self.title = title }
        init() { self.init("Untitled") }

        var body: some View { Text(title) }
      }
      """
    )
  }

  @Test func nonViewInitNotFlagged() {
    assertLint(
      NoWorkInViewInitializer.self,
      """
      struct Model {
        let items: [Int]
        init(values: [Int]) { items = values.sorted() }
      }
      """
    )
  }
}
