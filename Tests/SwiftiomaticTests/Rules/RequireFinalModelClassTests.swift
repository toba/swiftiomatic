import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct RequireFinalModelClassTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "'@Model' class '\(name)' is not 'final'; mark it 'final' unless a model subclasses it"
    }

    @Test func nonFinalModelFlagged() {
        assertLint(
            RequireFinalModelClass.self,
            """
            @Model
            class 1️⃣Trip {
              var name: String = ""
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("Trip"))]
        )
    }

    @Test func qualifiedAttributeFlagged() {
        assertLint(
            RequireFinalModelClass.self,
            """
            @SwiftData.Model public class 1️⃣Trip {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("Trip"))]
        )
    }

    @Test func finalModelNotFlagged() {
        assertLint(
            RequireFinalModelClass.self,
            """
            @Model final class Trip {}
            @Model public final class Leg {}
            """,
            findings: []
        )
    }

    @Test func subclassedModelNotFlagged() {
        assertLint(
            RequireFinalModelClass.self,
            """
            @Model class Trip { var name: String = "" }
            @Model final class BusinessTrip: Trip { var code: String = "" }
            """,
            findings: []
        )
    }

    @Test func openModelNotFlagged() {
        assertLint(
            RequireFinalModelClass.self,
            """
            @Model open class Trip {}
            """,
            findings: []
        )
    }

    @Test func classWithoutModelNotFlagged() {
        assertLint(
            RequireFinalModelClass.self,
            """
            @Observable class Trip {}
            class Leg {}
            """,
            findings: []
        )
    }
}
