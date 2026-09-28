import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagForEachIDSelfInViewTests: RuleTesting {
    @Test func guidanceIsConsider() { #expect(FlagForEachIDSelfInView.guidance == .consider) }

    @Test func idSelfFlagged() {
        assertLint(
            FlagForEachIDSelfInView.self,
            """
            ForEach(items, id: 1️⃣\\.self) { item in
              Text(String(describing: item))
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message:
                        "'id: \\.self' replaces the row on each edit, so make the element 'Identifiable' with 'let id = UUID()'"
                )
            ]
        )
    }

    @Test func idKeyPathToPropertyNotFlagged() {
        assertLint(
            FlagForEachIDSelfInView.self,
            """
            ForEach(items, id: \\.id) { item in
              Text(item.name)
            }
            """,
            findings: []
        )
    }

    @Test func noIDArgumentNotFlagged() {
        assertLint(
            FlagForEachIDSelfInView.self,
            """
            ForEach(items) { item in
              Text(item.name)
            }
            """,
            findings: []
        )
    }

    @Test func nonForEachNotFlagged() {
        assertLint(
            FlagForEachIDSelfInView.self,
            """
            List(items, id: \\.self) { item in
              Text(String(describing: item))
            }
            """,
            findings: []
        )
    }

    @Test func compoundKeyPathNotFlagged() {
        assertLint(
            FlagForEachIDSelfInView.self,
            """
            ForEach(Array(tags.enumerated()), id: \\.element.id) { index, tag in
              Text(tag.name)
            }
            """,
            findings: []
        )
    }

    @Test func indicesWithIDSelfNotFlagged() {
        assertLint(
            FlagForEachIDSelfInView.self,
            """
            ForEach(citations.indices, id: \\.self) { index in
              Text("\\(index)")
            }
            """,
            findings: []
        )
    }

    @Test func halfOpenRangeWithIDSelfNotFlagged() {
        assertLint(
            FlagForEachIDSelfInView.self,
            """
            ForEach(0..<count, id: \\.self) { index in
              Text("\\(index)")
            }
            """,
            findings: []
        )
    }

    @Test func closedRangeWithIDSelfNotFlagged() {
        assertLint(
            FlagForEachIDSelfInView.self,
            """
            ForEach(1...n, id: \\.self) { index in
              Text("\\(index)")
            }
            """,
            findings: []
        )
    }
}
