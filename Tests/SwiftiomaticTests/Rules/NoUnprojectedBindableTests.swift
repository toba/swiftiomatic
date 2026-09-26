@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoUnprojectedBindableTests: RuleTesting {
  private static func message(_ name: String) -> String {
    "'@Bindable' on '\(name)' makes no binding, because nothing reads '$\(name)'. Remove '@Bindable' and store the model as a plain property"
  }

  @Test func guidanceIsShould() {
    #expect(NoUnprojectedBindable.guidance == .should)
  }

  @Test func bindableMemberNeverProjectedFlagged() {
    assertLint(
      NoUnprojectedBindable.self,
      """
      struct GoogleDocsImportSheet: View {
        1️⃣@Bindable var model: GoogleDocs.ViewModel

        var body: some View {
          VStack(spacing: 0) {
            switch model.phase {
              case .finished: Button(.done) { model.phase = .idle }
              default: EmptyView()
            }
          }
        }

        private func progress(_ title: LocalizedStringKey) -> some View {
          Button(.cancel) { model.cancel() }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("model"))]
    )
  }

  @Test func bindableLocalNeverProjectedFlagged() {
    assertLint(
      NoUnprojectedBindable.self,
      """
      struct Results: View {
        var styles: Styles

        var body: some View {
          1️⃣@Bindable var styles = styles
          Text(styles.title)
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("styles"))]
    )
  }

  @Test func projectedBindablesNotFlagged() {
    assertLint(
      NoUnprojectedBindable.self,
      """
      struct Editor: View {
        @Bindable var model: Model

        var body: some View {
          TextField("Name", text: $model.name)
        }
      }

      struct Split: View {
        @Bindable var model: Model
        var body: some View { Text("x") }
      }

      extension Split {
        var toggle: some View { Toggle("On", isOn: $model.isOn) }
      }

      struct Results: View {
        var styles: Styles

        var body: some View {
          @Bindable var styles = styles
          List($styles.searchResults) { Row(result: $0) }
        }
      }

      struct Plain: View {
        var model: Model
        var body: some View { Text(model.title) }
      }
      """
    )
  }
}
