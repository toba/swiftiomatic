@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct BlankLinesBetweenImportsTests: LayoutTesting {

  @Test func removesBlankLineBetweenImports() {
    assertLayout(
      input: """
        import ModuleA

        import ModuleB
        """,
      expected: """
        import ModuleA
        import ModuleB

        """,
      linelength: 100
    )
  }

  @Test func removesMultipleBlankLinesBetweenImports() {
    assertLayout(
      input: """
        import ModuleA
        import ModuleB

        import ModuleC
        import ModuleD
        import ModuleE

        import ModuleF

        import ModuleG
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
      linelength: 100
    )
  }

  @Test func removesBlankLinesBetweenTestableImports() {
    assertLayout(
      input: """
        import ModuleA

        @testable import ModuleB
        import ModuleC

        @testable import ModuleD
        @testable import ModuleE

        @testable import ModuleF
        """,
      expected: """
        import ModuleA
        @testable import ModuleB
        import ModuleC
        @testable import ModuleD
        @testable import ModuleE
        @testable import ModuleF

        """,
      linelength: 100
    )
  }

  @Test func noChangeWhenNoBlankLines() {
    assertLayout(
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
      linelength: 100
    )
  }

  @Test func preservesBlankLineAfterImportsBeforeCode() {
    assertLayout(
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
      linelength: 100
    )
  }
}
