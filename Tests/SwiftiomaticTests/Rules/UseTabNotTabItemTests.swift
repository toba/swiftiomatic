import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseTabNotTabItemTests: RuleTesting {
  private static let message =
    "consider 'Tab' in place of '.tabItem'. A 'Tab' carries its label, value and role in one declaration"

  @Test func tabItemInTabViewFlagged() {
    assertLint(
      UseTabNotTabItem.self,
      """
      struct SettingsScene: Scene {
        var body: some Scene {
          Settings {
            TabView {
              GeneralView()
                .1️⃣tabItem { Label("General", systemImage: "gear") }
              AccountsView()
                .2️⃣tabItem { Label("Accounts", systemImage: "person") }
            }
          }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message),
        FindingSpec("2️⃣", message: Self.message),
      ]
    )
  }

  @Test func closureArgumentFlagged() {
    assertLint(
      UseTabNotTabItem.self,
      """
      struct Root: View {
        var body: some View {
          Text("Home").1️⃣tabItem({ Text("Home") })
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func tabAPINotFlagged() {
    assertLint(
      UseTabNotTabItem.self,
      """
      struct Root: View {
        var body: some View {
          TabView {
            Tab("General", systemImage: "gear") { GeneralView() }
          }
        }
      }
      """,
      findings: []
    )
  }

  @Test func otherTabItemMembersNotFlagged() {
    assertLint(
      UseTabNotTabItem.self,
      """
      let item = model.tabItem
      let other = model.tabItem(for: index)
      func tabItem() {}
      """,
      findings: []
    )
  }
}
