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

  @Test func nonViewTypeFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      struct Factory {
        1️⃣func makeRow() -> some View { Text("x") }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("makeRow"))]
    )
  }

  @Test func protocolExtensionFactoryFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      protocol SymbolView: RawRepresentable<String> {
        var tint: Color { get }
        var symbol: Symbol { get }
      }

      extension SymbolView {
        var label: String { rawValue.capitalized }
        1️⃣func view(tinted: Bool = true) -> some View { Image(symbol).tinted(tint, when: tinted) }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("view"))]
    )
  }

  @Test func modelTypeExtensionFactoryFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      extension IssueTask {
        1️⃣var badge: some View { IdentityBadge(id: id) }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("badge"))]
    )
  }

  @Test func fluentConcreteViewExtensionNotFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      extension Text {
        func wrappingSubject() -> some View {
          lineLimit(nil).fixedSize(horizontal: false, vertical: true)
        }
      }

      extension Shape {
        func outlined() -> some View { stroke(.red) }
      }
      """,
      findings: []
    )
  }

  @Test func styleEntryPointsAndPreviewsNotFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      struct Pill: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View { configuration.label }
      }

      struct Card_Previews: PreviewProvider {
        static var previews: some View { Card() }
      }

      protocol Erasing {
        var erased: AnyView { get }
      }
      """,
      findings: []
    )
  }
  @Test func concreteCustomViewReturnFlagged() {
    // From Thesis `EditorThemeStylesPreview.styleView(_:_:markdown:)`.
    assertLint(
      NoViewFactoryMembers.self,
      """
      struct EditorThemeStylesPreview: View {
        @Binding var theme: EditorTheme

        var body: some View {
          VStack { styleView(.chapterTitle, "Chapter Title"); header; scroller }
        }

        private 1️⃣func styleView(
          _ type: StyleType,
          _ textResource: LocalizedStringResource,
          markdown: Bool = false,
        ) -> EditorThemeStyleView {
          .init($theme[type], type: type)
        }

        private 2️⃣var header: HeaderRowView { HeaderRowView(theme: theme) }
        private 3️⃣var scroller: ScrollView<Text> { ScrollView { Text("x") } }
      }

      struct EditorThemeStyleView: View {
        var body: some View { Text("x") }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("styleView")),
        FindingSpec("2️⃣", message: Self.message("header")),
        FindingSpec("3️⃣", message: Self.message("scroller")),
      ]
    )
  }

  @Test func concreteNonViewReturnNotFlagged() {
    assertLint(
      NoViewFactoryMembers.self,
      """
      private struct WindowFramePersister: NSViewRepresentable {
        let child: ChildView
        func makeNSView(context: Context) -> WindowFrameView { WindowFrameView() }
        func updateNSView(_ view: WindowFrameView, context: Context) {}
        func makeTable() -> NSTableView { NSTableView() }
        func makeCanvas() -> MTKView { MTKView() }
        var model: RowModel { RowModel() }
      }

      private final class WindowFrameView: NSView {}

      struct RowModel {
        func summary() -> Summary { Summary() }
      }
      """,
      findings: []
    )
  }
}
