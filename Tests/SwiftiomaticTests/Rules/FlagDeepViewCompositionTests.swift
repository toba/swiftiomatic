@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagDeepViewCompositionTests: RuleTesting {
  private static func message(_ path: String, _ count: Int) -> String {
    "'body' nests \(count) structural levels (\(path)). Extract an inner level into a 'View' type so SwiftUI can skip it"
  }

  private static func note(_ name: String) -> String {
    "the deepest level, '\(name)', starts here"
  }

  private static func spec(
    _ path: String, _ count: Int, deepest: String, at marker: String = "2️⃣"
  ) -> FindingSpec {
    .init(
      "1️⃣", message: message(path, count), notes: [NoteSpec(marker, message: note(deepest))])
  }

  @Test func guidanceIsConsider() {
    #expect(FlagDeepViewComposition.guidance == .consider)
  }

  @Test func fontMenuBodyFlagged() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct FontMenu: View {
        var 1️⃣body: some View {
          VStack {
            TextField("Filter by name", text: $filter)
            ScrollView(.vertical) {
              LazyVStack(alignment: .leading, spacing: 1) {
                2️⃣ForEach(visibleRows) { FontPreview(row: $0) }
              }
              .padding(2)
            }
          }
          .task { await load() }
        }
      }
      """,
      findings: [Self.spec("VStack > ScrollView > LazyVStack > ForEach", 4, deepest: "ForEach")]
    )
  }

  @Test func threeLevelsFlaggedOnce() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct FontList: View {
        var 1️⃣body: some View {
          ScrollView {
            LazyVStack {
              ForEach(rows) { Text($0.name) }
            }
            HStack {
              2️⃣ForEach(tags) { Text($0) }
            }
          }
        }
      }
      """,
      findings: [Self.spec("ScrollView > HStack > ForEach", 3, deepest: "ForEach")]
    )
  }

  @Test func viewModifierBodyFlagged() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct Framed: ViewModifier {
        func 1️⃣body(content: Content) -> some View {
          HStack { VStack { 2️⃣Group { content } } }
        }
      }
      """,
      findings: [Self.spec("HStack > VStack > Group", 3, deepest: "Group")]
    )
  }

  // From jig `MilestonesSheet.swift`: a background layer that fills a shape (`in:`) composes a
  // shape view, so it adds a level. SwiftFairy reports this place.
  @Test func shapeBackgroundLayerCountsAsLevel() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct MilestoneRow: View {
        var 1️⃣body: some View {
          VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
              Text(milestone.shortName)
                .font(.caption.monospaced())
                .padding(.horizontal, 5)
                .2️⃣background(.quaternary, in: .capsule)
              Text(milestone.name).font(.headline)
            }
            Text(subtitle)
          }
        }
      }
      """,
      findings: [Self.spec("VStack > HStack > background", 3, deepest: "background")]
    )
  }

  @Test func shapeOverlayLayerCountsAsLevel() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct Ring: View {
        var 1️⃣body: some View {
          VStack {
            HStack { Text("a").2️⃣overlay(.red, in: Circle()) }
          }
        }
      }
      """,
      findings: [Self.spec("VStack > HStack > overlay", 3, deepest: "overlay")]
    )
  }

  /// A layer with a leaf view and no shape adds no level.
  @Test func leafViewBackgroundAddsNoLevel() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct Swatch: View {
        var body: some View {
          VStack { HStack { Text("a").background(Color.red).overlay { Image("x") } } }
        }
      }
      """
    )
  }

  @Test func colorBackgroundAddsNoLevel() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct Swatch: View {
        var body: some View {
          VStack { HStack { Text("a").background(.red) } }
        }
      }
      """
    )
  }

  @Test func layerThatHoldsContainerCountsAsLevel() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct Tile: View {
        var 1️⃣body: some View {
          VStack {
            Text("a").overlay { 2️⃣HStack { Text("b") } }
          }
        }
      }
      """,
      findings: [Self.spec("VStack > overlay > HStack", 3, deepest: "HStack")]
    )
  }

  // From jig `ProjectComposer.swift`: the finding sits on `body`, far above the deepest level.
  @Test func findingSitsOnBodyFarFromDeepestLevel() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct ProjectComposer: View {
        var 1️⃣body: some View {
          NavigationStack {
            Form {
              Section("Name") {
                TextField("Project name", text: $name)
              }
              Section {
                if let repo = detectedRepo {
                  LabeledContent("GitHub Repo") {
                    2️⃣HStack(spacing: 6) {
                      Text(repo.fullName)
                    }
                  }
                }
              }
            }
            .formStyle(.grouped)
          }
        }
      }
      """,
      findings: [Self.spec("NavigationStack > Form > Section > HStack", 4, deepest: "HStack")]
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

  @Test func backgroundOnOuterContainerNotFlagged() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct Badge: View {
        var body: some View {
          VStack {
            HStack { Text("a") }
          }
          .background(.quaternary, in: .capsule)
        }
      }
      """
    )
  }

  @Test func chainedLayersDoNotAddUp() {
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct Chip: View {
        var body: some View {
          VStack {
            Text("a")
              .padding()
              .background(.red)
              .overlay(Color.blue)
          }
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

  @Test func noteSitsOnTheLastDeepestContainer() {
    // From Thesis `ReferenceFilterForm.swift`
    assertLint(
      FlagDeepViewComposition.self,
      """
      struct TagMatchPicker: View {
        @Binding var matchAllTags: Bool

        var 1️⃣body: some View {
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
                  2️⃣HStack(spacing: 3) {
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
      findings: [Self.spec("VStack > HStack > HStack", 3, deepest: "HStack")]
    )
  }
}
