@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagDeepViewCompositionTests: RuleTesting {
  private static func message(_ path: String, _ count: Int) -> String {
    "'body' nests \(count) structural containers (\(path)). Extract an inner level into a 'View' type so SwiftUI can skip it"
  }

  @Test func guidanceIsConsider() {
    #expect(FlagDeepViewComposition.guidance == .consider)
  }

  @Test func fontMenuBodyFlagged() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct FontMenu: View {
        var body: some View {
          VStack {
            TextField("Filter by name", text: $filter)
            ScrollView(.vertical) {
              LazyVStack(alignment: .leading, spacing: 1) {
                1️⃣ForEach(visibleRows) { FontPreview(row: $0) }
              }
              .padding(2)
            }
          }
          .task { await load() }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("VStack > ScrollView > LazyVStack > ForEach", 4))
      ]
    )
  }

  @Test func threeLevelsFlaggedOnce() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct FontList: View {
        var body: some View {
          ScrollView {
            LazyVStack {
              ForEach(rows) { Text($0.name) }
            }
            HStack {
              1️⃣ForEach(tags) { Text($0) }
            }
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("ScrollView > HStack > ForEach", 3))]
    )
  }

  @Test func viewModifierBodyFlagged() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct Framed: ViewModifier {
        func body(content: Content) -> some View {
          HStack { VStack { 1️⃣Group { content } } }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("HStack > VStack > Group", 3))]
    )
  }

  @Test func twoLevelsNotFlagged() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct PopoverPicker: View {
        var body: some View {
          LabeledContent(label) {
            Button { toggle() } label: {
              HStack {
                Text(description)
                Image(systemName: "chevron.up.chevron.down")
              }
            }
          }
        }
      }
      """
    )
  }

  @Test func siblingContainersDoNotAddUp() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct Card: View {
        var body: some View {
          VStack { Text("a") }
            .overlay { HStack { Text("b") } }
            .background { ZStack { Color.red } }
        }
      }
      """
    )
  }

  @Test func nonViewBodyNotFlagged() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct Response {
        var body: some Sequence { VStack { HStack { ZStack { } } } }
      }
      """
    )
  }

  @Test func findingSitsOnTheLastDeepestContainer() {
    // From Thesis `ReferenceFilterForm.swift`
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct TagMatchPicker: View {
        @Binding var matchAllTags: Bool

        var body: some View {
          LabeledContent {
            VStack(alignment: .leading, spacing: 0) {
              HStack(spacing: 4) {
                Button { matchAllTags = false } label: {
                  HStack(spacing: 3) {
                    Image(systemName: "line.3.horizontal")
                    Text("Any of")
                  }
                }
                .buttonStyle(PickerButton(isSelected: !matchAllTags))

                Button { matchAllTags = true } label: {
                  1️⃣HStack(spacing: 3) {
                    Image(systemName: "line.3.horizontal.decrease")
                    Text("All of")
                  }
                }
              }
            }
          } label: {
            Text("Tags")
          }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("VStack > HStack > HStack", 3))]
    )
  }
}
