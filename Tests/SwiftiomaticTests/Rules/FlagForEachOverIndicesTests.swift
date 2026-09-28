import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagForEachOverIndicesTests: RuleTesting {
    private static let message =
        "'ForEach' over indices gives each row a positional identity. Iterate the elements, or use 'ForEach($items) { $item in ... }' for bindings"

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
