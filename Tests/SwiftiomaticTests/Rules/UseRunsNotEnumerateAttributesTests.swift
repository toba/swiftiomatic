import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseRunsNotEnumerateAttributesTests: RuleTesting {
    private static let enumerateAttributes =
        "'enumerateAttributes(in:)' walks an 'NSAttributedString'. Iterate 'AttributedString.runs' instead"
    private static let enumerateAttribute =
        "'enumerateAttribute(_:in:)' walks an 'NSAttributedString'. Iterate 'AttributedString.runs' instead"

    @Test func enumerateAttributesFlagged() {
        assertLint(
            UseRunsNotEnumerateAttributes.self,
            """
            text.1️⃣enumerateAttributes(in: NSRange(location: 0, length: text.length)) { attributes, range, _ in
              apply(attributes, range)
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.enumerateAttributes)]
        )
    }

    @Test func enumerateAttributeFlagged() {
        assertLint(
            UseRunsNotEnumerateAttributes.self,
            """
            text.1️⃣enumerateAttribute(.font, in: range, options: []) { value, range, _ in
              use(value)
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.enumerateAttribute)]
        )
    }

    @Test func implicitSelfFlagged() {
        assertLint(
            UseRunsNotEnumerateAttributes.self,
            """
            extension NSAttributedString {
              func fonts() {
                1️⃣enumerateAttribute(.font, in: fullRange) { value, _, _ in use(value) }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.enumerateAttribute)]
        )
    }

    @Test func callWithoutInArgumentNotFlagged() {
        assertLint(
            UseRunsNotEnumerateAttributes.self,
            """
            model.enumerateAttributes { attribute in use(attribute) }
            model.enumerateAttribute(named: "font")
            """,
            findings: []
        )
    }

    @Test func otherMemberNotFlagged() {
        assertLint(
            UseRunsNotEnumerateAttributes.self,
            """
            text.enumerateSubstrings(in: range, options: .byWords) { word, _, _, _ in use(word) }
            """,
            findings: []
        )
    }

    @Test func runsNotFlagged() {
        assertLint(
            UseRunsNotEnumerateAttributes.self,
            """
            for run in text.runs {
              apply(run.attributes, run.range)
            }
            """,
            findings: []
        )
    }
}
