import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseOfferCodeSheetOptionsTests: RuleTesting {
    private static let message =
        "'presentOfferCodeRedeemSheet(in:)' is deprecated on OS 27. Call 'presentOfferCodeRedeemSheet(from:options:)' with the presenting view controller"

    @Test func sceneFormFlagged() {
        assertLint(
            UseOfferCodeSheetOptions.self,
            """
            try await AppStore.1️⃣presentOfferCodeRedeemSheet(in: scene)
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func unqualifiedSceneFormFlagged() {
        assertLint(
            UseOfferCodeSheetOptions.self,
            """
            extension AppStore {
              static func redeem(in scene: UIWindowScene) async throws {
                try await 1️⃣presentOfferCodeRedeemSheet(in: scene)
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func viewControllerFormNotFlagged() {
        assertLint(
            UseOfferCodeSheetOptions.self,
            """
            let result = try await AppStore.presentOfferCodeRedeemSheet(from: controller)
            """,
            findings: []
        )
    }

    @Test func optionsFormNotFlagged() {
        assertLint(
            UseOfferCodeSheetOptions.self,
            """
            let result = try await AppStore.presentOfferCodeRedeemSheet(from: controller, options: [])
            """,
            findings: []
        )
    }

    @Test func otherMemberNotFlagged() {
        assertLint(
            UseOfferCodeSheetOptions.self,
            """
            try await AppStore.showManageSubscriptions(in: scene)
            """,
            findings: []
        )
    }
}
