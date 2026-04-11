import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered, .disabled("requires sourcekitd")) struct FileTypesOrderRuleTests {
  // MARK: - Default order — no violations

  @Test func defaultOrderNoViolation() async {
    await assertNoViolation(
      FileTypesOrderRule.self,
      FileTypesOrderRule.defaultOrderParts.joined(separator: "\n\n"))
  }

  @Test func onlyExtensionsNoViolation() async {
    await assertNoViolation(
      FileTypesOrderRule.self,
      """
      extension Foo {}
      extension Bar {
      }
      """)
  }

  @Test func mainTypeThenPreviewThenLibraryNoViolation() async {
    await assertNoViolation(
      FileTypesOrderRule.self,
      """
      struct ContentView: View {
          var body: some View {
              Text("Hello, World!")
          }
      }

      struct ContentView_Previews: PreviewProvider {
          static var previews: some View { ContentView() }
      }

      struct ContentView_LibraryContent: LibraryContentProvider {
          var views: [LibraryItem] {
              LibraryItem(ContentView())
          }
      }
      """)
  }

  // MARK: - Default order — violations

  @Test func mainTypeBeforeSupportingTypeViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      1️⃣class TestViewController: UIViewController {}

      // Supporting Types
      protocol TestViewControllerDelegate {
          func didPressTrackedButton()
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func extensionBeforeMainTypeViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      // Extensions
      1️⃣extension TestViewController: UITableViewDataSource {
          func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
              return 1
          }
      }

      class TestViewController: UIViewController {}
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func duplicateSupportingTypeViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      // Supporting Types
      protocol TestViewControllerDelegate {
          func didPressTrackedButton()
      }

      1️⃣class TestViewController: UIViewController {}

      // Supporting Types
      protocol TestViewControllerDelegate {
          func didPressTrackedButton()
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func extensionBeforeMainTypeWithSupportingTypesViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      // Supporting Types
      protocol TestViewControllerDelegate {
          func didPressTrackedButton()
      }

      // Extensions
      1️⃣extension TestViewController: UITableViewDataSource {
          func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
              return 1
          }
      }

      class TestViewController: UIViewController {}

      // Extensions
      extension TestViewController: UITableViewDataSource {
          func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
              return 1
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func previewBeforeMainTypeViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      1️⃣struct ContentView_Previews: PreviewProvider {
          static var previews: some View { ContentView() }
      }

      struct ContentView: View {
          var body: some View {
              Text("Hello, World!")
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func libraryContentBeforeMainTypeViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      1️⃣struct ContentView_LibraryContent: LibraryContentProvider {
          var views: [LibraryItem] {
              LibraryItem(ContentView())
          }
      }

      struct ContentView: View {
          var body: some View {
              Text("Hello, World!")
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - Reversed order configuration

  @Test func reversedOrderNoViolation() async {
    await assertNoViolation(
      FileTypesOrderRule.self,
      FileTypesOrderRule.defaultOrderParts.reversed().joined(separator: "\n\n"),
      configuration: [
        "order": [
          "library_content_provider", "preview_provider", "extension", "main_type",
          "supporting_type",
        ] as [any Sendable]
      ])
  }

  @Test func reversedOrderSupportingBeforeMainViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      // Supporting Types
      1️⃣protocol TestViewControllerDelegate {
          func didPressTrackedButton()
      }

      class TestViewController: UIViewController {}
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: [
        "order": [
          "library_content_provider", "preview_provider", "extension", "main_type",
          "supporting_type",
        ] as [any Sendable]
      ])
  }

  @Test func reversedOrderMainBeforeExtensionViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      1️⃣class TestViewController: UIViewController {}

      extension TestViewController: UITableViewDataSource {
          func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
              return 1
          }

          func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
              return UITableViewCell()
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: [
        "order": [
          "library_content_provider", "preview_provider", "extension", "main_type",
          "supporting_type",
        ] as [any Sendable]
      ])
  }

  @Test func reversedOrderDuplicateSupportingViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      // Supporting Types
      1️⃣protocol TestViewControllerDelegate {
          func didPressTrackedButton()
      }

      class TestViewController: UIViewController {}

      // Supporting Types
      protocol TestViewControllerDelegate {
          func didPressTrackedButton()
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: [
        "order": [
          "library_content_provider", "preview_provider", "extension", "main_type",
          "supporting_type",
        ] as [any Sendable]
      ])
  }

  @Test func reversedOrderStructBeforePreviewViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      1️⃣struct ContentView: View {
         var body: some View {
             Text("Hello, World!")
         }
      }

      struct ContentView_Previews: PreviewProvider {
         static var previews: some View { ContentView() }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: [
        "order": [
          "library_content_provider", "preview_provider", "extension", "main_type",
          "supporting_type",
        ] as [any Sendable]
      ])
  }

  @Test func reversedOrderStructBeforeLibraryContentViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      1️⃣struct ContentView: View {
         var body: some View {
             Text("Hello, World!")
         }
      }

      struct ContentView_LibraryContent: LibraryContentProvider {
          var views: [LibraryItem] {
              LibraryItem(ContentView())
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: [
        "order": [
          "library_content_provider", "preview_provider", "extension", "main_type",
          "supporting_type",
        ] as [any Sendable]
      ])
  }

  // MARK: - Grouped order configuration

  @Test func groupedOrderNoViolation() async {
    await assertNoViolation(
      FileTypesOrderRule.self,
      """
      class TestViewController: UIViewController {}

      // Supporting Type
      protocol TestViewControllerDelegate {
          func didPressTrackedButton()
      }

      // Extension
      extension TestViewController: UITableViewDataSource {
          func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
              return 1
          }
      }

      // Supporting Type
      protocol TestViewControllerDelegate2 {
          func didPressTrackedButton()
      }

      // Extension
      extension TestViewController: UITableViewDelegate {
          func someMethod() {}
      }
      """,
      configuration: [
        "order": [
          "main_type",
          ["extension", "supporting_type"] as [any Sendable],
          "preview_provider",
        ] as [any Sendable]
      ])
  }

  @Test func groupedOrderSupportingBeforeMainViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      // Supporting Types
      1️⃣protocol TestViewControllerDelegate {
          func didPressTrackedButton()
      }

      class TestViewController: UIViewController {}
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: [
        "order": [
          "main_type",
          ["extension", "supporting_type"] as [any Sendable],
          "preview_provider",
        ] as [any Sendable]
      ])
  }

  @Test func groupedOrderExtensionBeforeMainViolation() async {
    await assertLint(
      FileTypesOrderRule.self,
      """
      // Extensions
      1️⃣extension TestViewController: UITableViewDataSource {
          func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
              return 1
          }

          func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
              return UITableViewCell()
          }
      }

      class TestViewController: UIViewController {}
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: [
        "order": [
          "main_type",
          ["extension", "supporting_type"] as [any Sendable],
          "preview_provider",
        ] as [any Sendable]
      ])
  }
}
