import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseTopBarPlacementTests: RuleTesting {
    private static let leadingMessage = "replace '.navigationBarLeading' with '.topBarLeading'"
    private static let trailingMessage = "replace '.navigationBarTrailing' with '.topBarTrailing'"

    @Test func implicitMembers() {
        assertFormatting(
            UseTopBarPlacement.self,
            input: """
                ToolbarItem(placement: 1️⃣.navigationBarLeading) { back }
                ToolbarItem(placement: 2️⃣.navigationBarTrailing) { save }
                """,
            expected: """
                ToolbarItem(placement: .topBarLeading) { back }
                ToolbarItem(placement: .topBarTrailing) { save }
                """,
            findings: [
                FindingSpec("1️⃣", message: Self.leadingMessage),
                FindingSpec("2️⃣", message: Self.trailingMessage),
            ]
        )
    }

    @Test func explicitToolbarItemPlacementBase() {
        assertFormatting(
            UseTopBarPlacement.self,
            input: """
                let placement = 1️⃣ToolbarItemPlacement.navigationBarTrailing
                """,
            expected: """
                let placement = ToolbarItemPlacement.topBarTrailing
                """,
            findings: [FindingSpec("1️⃣", message: Self.trailingMessage)]
        )
    }

    @Test func keepsTrivia() {
        assertFormatting(
            UseTopBarPlacement.self,
            input: """
                ToolbarItemGroup(
                  placement: /* a */ 1️⃣.navigationBarLeading /* b */
                ) {}
                """,
            expected: """
                ToolbarItemGroup(
                  placement: /* a */ .topBarLeading /* b */
                ) {}
                """,
            findings: [FindingSpec("1️⃣", message: Self.leadingMessage)]
        )
    }

    @Test func otherBaseIgnored() {
        assertFormatting(
            UseTopBarPlacement.self,
            input: """
                let a = MyPlacement.navigationBarLeading
                let b = placement.navigationBarTrailing
                """,
            expected: """
                let a = MyPlacement.navigationBarLeading
                let b = placement.navigationBarTrailing
                """,
            findings: []
        )
    }

    @Test func alreadyTopBar() {
        assertFormatting(
            UseTopBarPlacement.self,
            input: """
                ToolbarItem(placement: .topBarLeading) { back }
                ToolbarItem(placement: .principal) { title }
                """,
            expected: """
                ToolbarItem(placement: .topBarLeading) { back }
                ToolbarItem(placement: .principal) { title }
                """,
            findings: []
        )
    }
}
