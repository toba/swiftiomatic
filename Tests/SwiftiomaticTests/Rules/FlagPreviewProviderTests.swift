@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagPreviewProviderTests: RuleTesting {
  private static let provider =
    "'PreviewProvider' is deprecated in the 27.0 SDK — use the '#Preview' macro"
  private static let displayName =
    "'previewDisplayName' is deprecated in the 27.0 SDK — pass the name to '#Preview(\"Name\")'"
  private static let layout =
    "'previewLayout' is deprecated in the 27.0 SDK — use '#Preview(traits: .sizeThatFitsLayout)' or '.fixedLayout(width:height:)'"
  private static let orientation =
    "'previewInterfaceOrientation' is deprecated in the 27.0 SDK — use an orientation trait such as '#Preview(traits: .landscapeLeft)'"
  private static let device =
    "'previewDevice' is deprecated in the 27.0 SDK — pick the device in Xcode's canvas"

  @Test func previewProviderStructFlagged() {
    assertLint(
      FlagPreviewProvider.self,
      """
      struct V_Previews: 1️⃣PreviewProvider {
        static var previews: some View { V() }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.provider)]
    )
  }

  @Test func previewProviderExtensionFlagged() {
    assertLint(
      FlagPreviewProvider.self,
      """
      extension V: 1️⃣PreviewProvider {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.provider)]
    )
  }

  @Test func previewProviderAmongOthersFlagged() {
    assertLint(
      FlagPreviewProvider.self,
      """
      struct V_Previews: Sendable, 1️⃣PreviewProvider {
        static var previews: some View { V() }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.provider)]
    )
  }

  @Test func previewDisplayNameFlagged() {
    assertLint(
      FlagPreviewProvider.self,
      """
      let preview = V().1️⃣previewDisplayName("Dark")
      """,
      findings: [FindingSpec("1️⃣", message: Self.displayName)]
    )
  }

  @Test func previewLayoutFlagged() {
    assertLint(
      FlagPreviewProvider.self,
      """
      let preview = V().1️⃣previewLayout(.sizeThatFits)
      """,
      findings: [FindingSpec("1️⃣", message: Self.layout)]
    )
  }

  @Test func previewInterfaceOrientationFlagged() {
    assertLint(
      FlagPreviewProvider.self,
      """
      let preview = V().1️⃣previewInterfaceOrientation(.landscapeLeft)
      """,
      findings: [FindingSpec("1️⃣", message: Self.orientation)]
    )
  }

  @Test func previewDeviceFlagged() {
    assertLint(
      FlagPreviewProvider.self,
      """
      let preview = V().1️⃣previewDevice("iPhone 17")
      """,
      findings: [FindingSpec("1️⃣", message: Self.device)]
    )
  }

  @Test func previewMacroNotFlagged() {
    assertLint(
      FlagPreviewProvider.self,
      """
      #Preview("Dark") {
        V()
      }
      """,
      findings: []
    )
  }

  @Test func otherConformanceNotFlagged() {
    assertLint(
      FlagPreviewProvider.self,
      """
      struct V: View {
        var body: some View { Text("") }
      }
      """,
      findings: []
    )
  }

  @Test func unrelatedModifierNotFlagged() {
    assertLint(
      FlagPreviewProvider.self,
      """
      let view = V().padding(8)
      """,
      findings: []
    )
  }
}
