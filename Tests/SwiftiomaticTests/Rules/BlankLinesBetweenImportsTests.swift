@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct BlankLinesBetweenImportsTests: RuleTesting {

  @Test func removesBlankLineBetweenImports() {
    assertFormatting(
      BlankLinesBetweenImports.self,
      input: """
        import ModuleA

        1️⃣import ModuleB
        """,
      expected: """
        import ModuleA
        import ModuleB
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove blank line between import statements"),
      ]
    )
  }

  @Test func removesMultipleBlankLinesBetweenImports() {
    assertFormatting(
      BlankLinesBetweenImports.self,
      input: """
        import ModuleA
        import ModuleB

        1️⃣import ModuleC
        import ModuleD
        import ModuleE

        2️⃣import ModuleF

        3️⃣import ModuleG
        import ModuleH
        """,
      expected: """
        import ModuleA
        import ModuleB
        import ModuleC
        import ModuleD
        import ModuleE
        import ModuleF
        import ModuleG
        import ModuleH
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove blank line between import statements"),
        FindingSpec("2️⃣", message: "remove blank line between import statements"),
        FindingSpec("3️⃣", message: "remove blank line between import statements"),
      ]
    )
  }

  @Test func removesBlankLinesBetweenTestableImports() {
    assertFormatting(
      BlankLinesBetweenImports.self,
      input: """
        import ModuleA

        1️⃣@testable import ModuleB
        import ModuleC

        2️⃣@testable import ModuleD
        @testable import ModuleE

        3️⃣@testable import ModuleF
        """,
      expected: """
        import ModuleA
        @testable import ModuleB
        import ModuleC
        @testable import ModuleD
        @testable import ModuleE
        @testable import ModuleF
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove blank line between import statements"),
        FindingSpec("2️⃣", message: "remove blank line between import statements"),
        FindingSpec("3️⃣", message: "remove blank line between import statements"),
      ]
    )
  }

  @Test func noChangeWhenNoBlankLines() {
    assertFormatting(
      BlankLinesBetweenImports.self,
      input: """
        import ModuleA
        import ModuleB
        import ModuleC
        """,
      expected: """
        import ModuleA
        import ModuleB
        import ModuleC
        """,
      findings: []
    )
  }

  @Test func preservesBlankLineAfterImportsBeforeCode() {
    assertFormatting(
      BlankLinesBetweenImports.self,
      input: """
        import ModuleA
        import ModuleB

        class Foo {}
        """,
      expected: """
        import ModuleA
        import ModuleB

        class Foo {}
        """,
      findings: []
    )
  }
}
