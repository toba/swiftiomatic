import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseItemPresentationTests: RuleTesting {
    private static func message(
        _ modifier: String,
        _ flag: String,
        _ value: String,
        fix: String = "item:"
    ) -> String {
        "'.\(modifier)(isPresented: $\(flag))' pairs a Bool with the optional '\(value)', and the two can disagree. Present with the '\(fix)' form and one 'Binding<T?>'"
    }

    private static func flagNote(_ name: String) -> String { "'\(name)' is the Bool that presents" }
    private static func valueNote(_ name: String) -> String {
        "'\(name)' is the optional value the content reads"
    }

    @Test func guidanceIsConsider() { #expect(UseItemPresentation.guidance == .consider) }

    @Test func sheetWithFlagAndOptionalFlagged() {
        assertLint(
            UseItemPresentation.self,
            """
            struct Library: View {
              2️⃣@State private var showEditor = false
              3️⃣@State private var editedBook: Book?

              var body: some View {
                List(books) { book in
                  Button(book.title) {
                    editedBook = book
                    showEditor = true
                  }
                }
                .sheet(1️⃣isPresented: $showEditor) {
                  if let editedBook { Editor(book: editedBook) }
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("sheet", "showEditor", "editedBook"),
                    notes: [
                        NoteSpec("2️⃣", message: Self.flagNote("showEditor")),
                        NoteSpec("3️⃣", message: Self.valueNote("editedBook")),
                    ]
                )
            ]
        )
    }

    @Test func alertUsesPresentingFix() {
        assertLint(
            UseItemPresentation.self,
            """
            struct Library: View {
              2️⃣@State var isShowingError: Bool = false
              3️⃣@State var error: Optional<LibraryError> = nil

              var body: some View {
                Text("x")
                  .alert("Error", 1️⃣isPresented: $isShowingError) {
                    Button("OK") {}
                  } message: {
                    Text(error?.localizedDescription ?? "")
                  }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("alert", "isShowingError", "error", fix: "presenting:"),
                    notes: [
                        NoteSpec("2️⃣", message: Self.flagNote("isShowingError")),
                        NoteSpec("3️⃣", message: Self.valueNote("error")),
                    ]
                )
            ]
        )
    }

    @Test func contentWithoutOptionalReadNotFlagged() {
        assertLint(
            UseItemPresentation.self,
            """
            struct Settings: View {
              @State private var showAbout = false
              @State private var draft: Draft?

              var body: some View {
                Button("About") { showAbout = true }
                  .sheet(isPresented: $showAbout) { AboutView() }
                  .onAppear { print(draft as Any) }
              }
            }
            """,
            findings: []
        )
    }

    @Test func alreadyItemFormNotFlagged() {
        assertLint(
            UseItemPresentation.self,
            """
            struct Library: View {
              @State private var editedBook: Book?

              var body: some View {
                Text("x").sheet(item: $editedBook) { Editor(book: $0) }
              }
            }
            """,
            findings: []
        )
    }

    @Test func nonStateOrNonViewNotFlagged() {
        assertLint(
            UseItemPresentation.self,
            """
            struct Library: View {
              @Binding var showEditor: Bool
              @State private var editedBook: Book?

              var body: some View {
                Text("x").sheet(isPresented: $showEditor) { Editor(book: editedBook) }
              }
            }

            struct Helper {
              @State private var show = false
              @State private var book: Book?
              func make() -> some View {
                Text("x").sheet(isPresented: $show) { Editor(book: book) }
              }
            }
            """,
            findings: []
        )
    }

    @Test func alertWithPresentingNotFlagged() {
        assertLint(
            UseItemPresentation.self,
            """
            struct Library: View {
              @State private var showError = false
              @State private var error: LibraryError?

              var body: some View {
                Text("x").alert("Error", isPresented: $showError, presenting: error) { _ in
                  Button("OK") {}
                } message: { _ in
                  Text(error?.localizedDescription ?? "")
                }
              }
            }
            """,
            findings: []
        )
    }
}
