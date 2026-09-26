import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoUnreadEnvironmentPropertyTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "no member reads '\(name)'. The view still updates on every change to the value. Remove the property"
    }

    private static func owner(_ type: String) -> String { "'\(type)' subscribes to the value here" }

    @Test func guidanceIsShould() { #expect(NoUnreadEnvironmentProperty.guidance == .should) }

    @Test func unreadPrivateEnvironmentFlagged() {
        assertLint(
            NoUnreadEnvironmentProperty.self,
            """
            struct 0️⃣Row: View {
              1️⃣@Environment(\\.dismiss) private var dismiss
              2️⃣@FocusedValue(\\.selection) fileprivate var selection

              var body: some View { Text("x") }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message("dismiss"),
                    notes: [NoteSpec("0️⃣", message: Self.owner("Row"))]),
                FindingSpec(
                    "2️⃣", message: Self.message("selection"),
                    notes: [NoteSpec("0️⃣", message: Self.owner("Row"))]),
            ]
        )
    }

    @Test func readsInAnyFormAreNotFlagged() {
        assertLint(
            NoUnreadEnvironmentProperty.self,
            """
            struct Row: View {
              @Environment(\\.dismiss) private var dismiss
              @Environment(\\.colorScheme) private var colorScheme
              @Environment(Model.self) private var model
              @Environment(\\.openURL) private var openURL

              var body: some View {
                Button("x") { dismiss() }
                  .tint(self.colorScheme == .dark ? .white : .black)
                  .sheet(isPresented: $model.isShown) { EmptyView() }
              }
            }

            extension Row {
              private func open() { openURL(url) }
            }
            """,
            findings: []
        )
    }

    @Test func nonPrivatePropertyOfNonPrivateTypeNotFlagged() {
        assertLint(
            NoUnreadEnvironmentProperty.self,
            """
            struct Row: View {
              @Environment(\\.dismiss) var dismiss
              var body: some View { Text("x") }
            }
            """,
            findings: []
        )
    }

    @Test func propertyOfPrivateTypeFlagged() {
        assertLint(
            NoUnreadEnvironmentProperty.self,
            """
            private struct 0️⃣Badge: ViewModifier {
              1️⃣@Environment(\\.locale) var locale
              func body(content: Content) -> some View { content }
            }

            enum Outer {
              fileprivate struct 8️⃣Inner: View {
                9️⃣@Environment(\\.locale) var locale
                var body: some View { EmptyView() }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message("locale"),
                    notes: [NoteSpec("0️⃣", message: Self.owner("Badge"))]),
                FindingSpec(
                    "9️⃣", message: Self.message("locale"),
                    notes: [NoteSpec("8️⃣", message: Self.owner("Inner"))]),
            ]
        )
    }

    @Test func readInNestedTypeDoesNotCount() {
        assertLint(
            NoUnreadEnvironmentProperty.self,
            """
            struct 0️⃣Row: View {
              1️⃣@Environment(\\.locale) private var locale
              var body: some View { Text("x") }

              struct Child: View {
                let locale: Locale
                var body: some View { Text(locale.identifier) }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message("locale"),
                    notes: [NoteSpec("0️⃣", message: Self.owner("Row"))])
            ]
        )
    }

    @Test func shadowedNameDoesNotCount() {
        assertLint(
            NoUnreadEnvironmentProperty.self,
            """
            struct 0️⃣Row: View {
              1️⃣@Environment(\\.locale) private var locale
              var body: some View {
                let locale = Locale.current
                return Text(locale.identifier)
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣", message: Self.message("locale"),
                    notes: [NoteSpec("0️⃣", message: Self.owner("Row"))])
            ]
        )
    }

    @Test func nonViewTypeNotFlagged() {
        assertLint(
            NoUnreadEnvironmentProperty.self,
            """
            private struct Holder {
              @Environment(\\.locale) var locale
            }

            private struct Row: View {
              @State private var count = 0
              var body: some View { Text("x") }
            }
            """,
            findings: []
        )
    }
}
