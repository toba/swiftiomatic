import Foundation
import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoViewFactoryMembersTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "'\(name)' builds a view outside 'body'. Extract it into a 'View' type with its own inputs"
    }

    private static func ownerMessage(_ name: String) -> String {
        "'\(name)' builds part of its view in helper members. Move each helper into a focused 'View' type"
    }

    @Test func guidanceIsMustNot() { #expect(NoViewFactoryMembers.guidance == .mustNot) }

    @Test func gutterMarkerViewMethodFlagged() {
        assertLint(
            NoViewFactoryMembers.self,
            """
            struct 0️⃣EditorGutterView: View {
              var body: some View {
                ForEach(markers, id: \\.id) { marker in markerView(marker) }
              }

              @ViewBuilder private 1️⃣func markerView(_ marker: GutterMarker) -> some View {
                Image(systemName: marker.symbolName)
              }
            }
            """,
            findings: [
                FindingSpec("0️⃣", message: Self.ownerMessage("EditorGutterView")),
                FindingSpec("1️⃣", message: Self.message("markerView")),
            ]
        )
    }

    @Test func tablePickerCellMethodFlagged() {
        assertLint(
            NoViewFactoryMembers.self,
            """
            private struct 0️⃣TableSizePicker: View {
              var body: some View {
                ForEach(1...8, id: \\.self) { row in cell(row: row, column: 1) }
              }

              private 1️⃣func cell(row: Int, column: Int) -> some View {
                RoundedRectangle(cornerRadius: 2)
              }
            }
            """,
            findings: [
                FindingSpec("0️⃣", message: Self.ownerMessage("TableSizePicker")),
                FindingSpec("1️⃣", message: Self.message("cell")),
            ]
        )
    }

    @Test func computedPropertyAndAnyViewFlagged() {
        assertLint(
            NoViewFactoryMembers.self,
            """
            struct 0️⃣Card: View {
              var body: some View { VStack { header; footer } }

              private 1️⃣var header: some View { Text("Header").bold() }
              private 2️⃣var footer: AnyView { AnyView(Text("Footer")) }
            }
            """,
            findings: [
                FindingSpec("0️⃣", message: Self.ownerMessage("Card")),
                FindingSpec("1️⃣", message: Self.message("header")),
                FindingSpec("2️⃣", message: Self.message("footer")),
            ]
        )
    }

    @Test func extensionOfViewTypeFlagged() {
        assertLint(
            NoViewFactoryMembers.self,
            """
            struct 0️⃣Card: View {
              var body: some View { header }
            }

            extension Card {
              1️⃣func header() -> some View { Text("Header") }
            }
            """,
            findings: [
                FindingSpec("0️⃣", message: Self.ownerMessage("Card")),
                FindingSpec("1️⃣", message: Self.message("header")),
            ]
        )
    }

    @Test func ownerReportedOnceForFactoriesInTypeAndExtension() {
        assertLint(
            NoViewFactoryMembers.self,
            """
            struct 0️⃣Card: View {
              var body: some View { VStack { header; footer } }

              private 1️⃣var header: some View { Text("Header") }
            }

            extension Card {
              2️⃣var footer: some View { Text("Footer") }
            }
            """,
            findings: [
                FindingSpec("0️⃣", message: Self.ownerMessage("Card")),
                FindingSpec("1️⃣", message: Self.message("header")),
                FindingSpec("2️⃣", message: Self.message("footer")),
            ]
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
        // From jig `DisplayStyle.swift` and `FieldPickers.swift`.
        assertLint(
            NoViewFactoryMembers.self,
            """
            extension View {
              nonisolated func tinted(_ style: some ShapeStyle, when tinted: Bool) -> some View {
                foregroundStyle(tinted ? AnyShapeStyle(style) : AnyShapeStyle(.secondary))
              }
            }

            private extension SwiftUI.View {
              func pickerChrome(summary: String) -> some View {
                menuStyle(.button).help(summary)
              }
            }
            """,
            findings: []
        )
    }

    /// From jig `SampleData.swift`: a member of `extension View` that transforms `self` is a
    /// modifier, with or without parameters. A member that builds a new view is a factory.
    @Test func parameterlessViewExtensionModifierNotFlagged() {
        assertLint(
            NoViewFactoryMembers.self,
            """
            extension View {
              @MainActor func sampleFixture() -> some View {
                environment(\\.people, SampleAuthor.people)
                  .environment(\\.database, SampleFixture.shared.database)
              }

              var carded: some View { padding().background(.thinMaterial) }
              var framed: some View { self.border(.red) }

              1️⃣var placeholder: some View { Text("None").foregroundStyle(.secondary) }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("placeholder"))]
        )
    }

    /// Concrete containers and controls are views too. Only display, shape, gradient and empty
    /// types are allowed.
    @Test func concreteContainerAndControlReturnsFlagged() {
        assertLint(
            NoViewFactoryMembers.self,
            """
            struct 3️⃣Card: View {
              var body: some View { header }

              private 1️⃣var header: HStack<Text> { HStack { Text("Title") } }
              private 2️⃣func action() -> Button<Text> { Button("Go") {} }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("header")),
                FindingSpec("2️⃣", message: Self.message("action")),
                FindingSpec("3️⃣", message: Self.ownerMessage("Card")),
            ]
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
              func subject(_ isActive: Bool) -> Text { bold(isActive) }
              func caption() -> Text { font(.caption) }
            }

            extension Shape {
              func outlined(_ color: Color) -> some View { stroke(color) }
            }
            """,
            findings: []
        )
    }

    @Test func concreteReceiverExtensionReturningOtherViewFlagged() {
        // From jig `WrappingSubject.swift`.
        assertLint(
            NoViewFactoryMembers.self,
            """
            extension Text {
              1️⃣func wrappingSubject() -> some View {
                lineLimit(nil)
                  .fixedSize(horizontal: false, vertical: true)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }

              2️⃣func padded(_ amount: CGFloat) -> some View { padding(amount) }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("wrappingSubject")),
                FindingSpec("2️⃣", message: Self.message("padded")),
            ]
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
            struct 0️⃣EditorThemeStylesPreview: View {
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
                FindingSpec("0️⃣", message: Self.ownerMessage("EditorThemeStylesPreview")),
                FindingSpec("1️⃣", message: Self.message("styleView")),
                FindingSpec("2️⃣", message: Self.message("header")),
                FindingSpec("3️⃣", message: Self.message("scroller")),
            ]
        )
    }

    @Test func viewOwnerOfFactoryMemberFlagged() {
        // From jig `ProjectList.swift`.
        assertLint(
            NoViewFactoryMembers.self,
            """
            private struct 0️⃣AddProjectBar: View {
              let failure: String?
              let canWrite: Bool
              @Binding var typedName: String

              private 1️⃣var buttons: AddProjectButtons {
                AddProjectButtons(canWrite: canWrite, typedName: $typedName)
              }

              var body: some View {
                ViewThatFits(in: .horizontal) {
                  buttons.labelStyle(.titleAndIcon)
                  buttons.labelStyle(.iconOnly)
                }
              }
            }

            private struct AddProjectButtons: View {
              let canWrite: Bool
              @Binding var typedName: String

              private var title: Text { Text("Add") }

              var body: some View { HStack { title } }
            }
            """,
            findings: [
                FindingSpec("0️⃣", message: Self.ownerMessage("AddProjectBar")),
                FindingSpec("1️⃣", message: Self.message("buttons")),
            ]
        )
    }

    @Test func nonViewOwnerOfFactoryMemberNotFlagged() {
        assertLint(
            NoViewFactoryMembers.self,
            """
            struct Factory {
              1️⃣func makeRow() -> some View { Text("x") }
              2️⃣func makeHeader() -> some View { Text("y") }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("makeRow")),
                FindingSpec("2️⃣", message: Self.message("makeHeader")),
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

    @Test func storedViewInputsNotFlagged() {
        assertLint(
            NoViewFactoryMembers.self,
            """
            struct 0️⃣Card: View {
              let content: AnyView
              var accessory: AnyView = AnyView(EmptyView())
              let row: RowView
              1️⃣var footer: AnyView { AnyView(Text("Footer")) }

              var body: some View { VStack { content; accessory; row; footer } }
            }
            """,
            findings: [
                FindingSpec("0️⃣", message: Self.ownerMessage("Card")),
                FindingSpec("1️⃣", message: Self.message("footer")),
            ]
        )
    }
}
