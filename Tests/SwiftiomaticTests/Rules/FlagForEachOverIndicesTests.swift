import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagForEachOverIndicesTests: RuleTesting {
    private static let message =
        "'ForEach' over indices gives each row a positional identity. Iterate the elements, or use 'ForEach($items) { $item in ... }' for bindings"
    private static let enumeratedMessage =
        "'$items[index]' from an 'enumerated()' offset is a positional binding, so a removal or a move makes the row edit another element. Use 'ForEach($items, id: ...) { $item in ... }'"

    @Test func guidanceIsShouldNot() { #expect(FlagForEachOverIndices.guidance == .shouldNot) }

    @Test func indicesWithIDSelfFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(1️⃣items.indices, id: \\.self) { i in
              Text("\\(i)")
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func indicesWithoutIDFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(1️⃣items.indices) { i in
              Text("\\(i)")
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func halfOpenRangeWithIDSelfFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(1️⃣0..<items.count, id: \\.self) { i in
              Text("\\(i)")
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func halfOpenRangeWithoutIDFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(1️⃣0..<n) { i in
              Text("\\(i)")
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func closedRangeFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(1️⃣0...9) { i in
              Text("\\(i)")
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func rangeInitFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(1️⃣Range(0..<n)) { i in
              Text("\\(i)")
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func elementCollectionWithIDSelfNotFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(items, id: \\.self) { item in
              Text(String(describing: item))
            }
            """,
            findings: []
        )
    }

    @Test func plainElementCollectionNotFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(items) { item in
              Text(item.name)
            }
            """,
            findings: []
        )
    }

    @Test func enumeratedNotFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(Array(tags.enumerated()), id: \\.element.id) { index, tag in
              Text(tag.name)
            }
            """,
            findings: []
        )
    }

    @Test func enumeratedOffsetWithBindingProjectionFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(1️⃣Array(contributors.enumerated()), id: \\.offset) { index, _ in
              ContributorRow(
                contributor: $contributors[guarded: index],
                isEditable: isEditable,
                onRemove: isEditable ? { remove(at: index) } : nil,
              )
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.enumeratedMessage)]
        )
    }

    @Test func bareEnumeratedOffsetWithBindingProjectionFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(1️⃣items.enumerated(), id: \\.offset) { index, item in
              TextField("Name", text: $items[index].name)
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.enumeratedMessage)]
        )
    }

    @Test func enumeratedOffsetWithoutBindingProjectionNotFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(Array(steps.enumerated()), id: \\.offset) { index, step in
              Text("\\(index + 1). \\(step.title)")
            }
            """,
            findings: []
        )
    }

    @Test func enumeratedOffsetProjectingOtherIndexNotFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            ForEach(Array(items.enumerated()), id: \\.offset) { index, item in
              Toggle(item.name, isOn: $flags[0])
            }
            """,
            findings: []
        )
    }

    @Test func nonForEachNotFlagged() {
        assertLint(
            FlagForEachOverIndices.self,
            """
            List(items.indices, id: \\.self) { i in
              Text("\\(i)")
            }
            """,
            findings: []
        )
    }

    @Test func statefulRowsFlaggedWhenStatefulRuleDisabled() {
        // The default test configuration disables `flagStatefulForEachOverIndices`
        assertLint(
            FlagForEachOverIndices.self,
            """
            struct CitationGroupForm: View {
              @FocusState private var focusedIndex: Int?

              var body: some View {
                ForEach(1️⃣citations.indices, id: \\.self) { index in
                  CitationForm(index: index).focused($focusedIndex, equals: index)
                }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }
}
