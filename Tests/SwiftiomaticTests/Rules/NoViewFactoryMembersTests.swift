@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoViewFactoryMembersTests: RuleTesting {
  private static func message(_ name: String) -> String {
    "'\(name)' builds a view outside 'body'. Extract it into a 'View' type with its own inputs"
  }

  @Test func gutterMarkerViewMethodFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      struct EditorGutterView: View {
        var body: some View {
          ForEach(markers, id: \\.id) { marker in markerView(marker) }
        }

        @ViewBuilder private 1️⃣func markerView(_ marker: GutterMarker) -> some View {
          Image(systemName: marker.symbolName)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("markerView"))]
    )
  }

  @Test func tablePickerCellMethodFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      private struct TableSizePicker: View {
        var body: some View {
          ForEach(1...8, id: \\.self) { row in cell(row: row, column: 1) }
        }

        private 1️⃣func cell(row: Int, column: Int) -> some View {
          RoundedRectangle(cornerRadius: 2)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("cell"))]
    )
  }

  @Test func computedPropertyAndAnyViewFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      struct Card: View {
        var body: some View { VStack { header; footer } }

        private 1️⃣var header: some View { Text("Header").bold() }
        private 2️⃣var footer: AnyView { AnyView(Text("Footer")) }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("header")),
        FindingSpec("2️⃣", message: Self.message("footer")),
      ]
    )
  }

  @Test func extensionOfViewTypeFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      struct Card: View {
        var body: some View { header }
      }

      extension Card {
        1️⃣func header() -> some View { Text("Header") }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("header"))]
    )
  }

  @Test func allowlistedConcreteTypesNotFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      struct Card: View {
        var body: some View { VStack { title; icon; tint; shape; fill; EmptyView() } }

        private var title: Text { Text("Title") }
        private var icon: Image { Image(systemName: "star") }
        private var tint: Color { .accentColor }
        private func shape() -> RoundedRectangle { RoundedRectangle(cornerRadius: 4) }
        private var fill: LinearGradient { LinearGradient(colors: [], startPoint: .top, endPoint: .bottom) }
        private var nothing: EmptyView { EmptyView() }
        private var circle: Circle { Circle() }
      }
      """,
      findings: []
    )
  }

  @Test func protocolEntryPointsNotFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      struct Card: View {
        var body: some View { Text("x") }
      }

      struct Bordered: ViewModifier {
        func body(content: Content) -> some View { content.border(.red) }
      }

      struct Pressed: ButtonStyle, View {
        var body: some View { Text("x") }
        func makeBody(configuration: Configuration) -> some View { configuration.label }
      }
      """,
      findings: []
    )
  }

  @Test func fluentViewExtensionNotFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      extension View {
        func card() -> some View { padding().background(.thinMaterial) }
      }
      """,
      findings: []
    )
  }

  @Test func nonViewTypeNotFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      struct Factory {
        func makeRow() -> some View { Text("x") }
      }
      """,
      findings: []
    )
  }
}
