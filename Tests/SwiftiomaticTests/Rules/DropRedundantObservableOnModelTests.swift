import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct DropRedundantObservableOnModelTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "remove '@Observable' from '\(name)'; '@Model' already makes the class observable"
    }
    private static let modelNote = "the '@Model' attribute that adds 'Observable'"

    @Test func observableModelFlagged() {
        assertLint(
            DropRedundantObservableOnModel.self,
            """
            2️⃣@Model
            1️⃣@Observable
            final class Trip {}
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("Trip"),
                    notes: [NoteSpec("2️⃣", message: Self.modelNote)]
                )
            ]
        )
    }

    @Test func qualifiedAttributesFlagged() {
        assertLint(
            DropRedundantObservableOnModel.self,
            """
            1️⃣@Observation.Observable 2️⃣@SwiftData.Model final class Trip {}
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("Trip"),
                    notes: [NoteSpec("2️⃣", message: Self.modelNote)]
                )
            ]
        )
    }

    @Test func modelOnlyNotFlagged() {
        assertLint(
            DropRedundantObservableOnModel.self,
            """
            @Model final class Trip {}
            @Observable final class Store {}
            """,
            findings: []
        )
    }
}
