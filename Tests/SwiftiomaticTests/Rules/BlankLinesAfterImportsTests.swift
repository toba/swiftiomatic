@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct BlankLineAfterImportsTests: RuleTesting {

  @Test func blankLineAfterImport() {
    assertFormatting(
      BlankLinesAfterImports.self,
      input: """
        import ModuleA
        @testable import ModuleB
        import ModuleC
        @testable import ModuleD
        @_exported import ModuleE
        @_implementationOnly import ModuleF
        @_spi(SPI) import ModuleG
        @_spiOnly import ModuleH
        @preconcurrency import ModuleI
        1️⃣class foo {}
        """,
      expected: """
        import ModuleA
        @testable import ModuleB
        import ModuleC
        @testable import ModuleD
        @_exported import ModuleE
        @_implementationOnly import ModuleF
        @_spi(SPI) import ModuleG
        @_spiOnly import ModuleH
        @preconcurrency import ModuleI

        class foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after import statements"),
      ]
    )
  }

  @Test func blankLinesBetweenConditionalImports() {
    assertFormatting(
      BlankLinesAfterImports.self,
      input: """
        #if foo
            import ModuleA
        #else
            import ModuleB
        #endif
        import ModuleC
        1️⃣func foo() {}
        """,
      expected: """
        #if foo
            import ModuleA
        #else
            import ModuleB
        #endif
        import ModuleC

        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after import statements"),
      ]
    )
  }

  @Test func blankLineAfterScopedImports() {
    assertFormatting(
      BlankLinesAfterImports.self,
      input: """
        internal import UIKit
        internal import Foundation
        private import Time
        1️⃣public class Foo {}
        """,
      expected: """
        internal import UIKit
        internal import Foundation
        private import Time

        public class Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert blank line after import statements"),
      ]
    )
  }

  @Test func alreadyHasBlankLine() {
    assertFormatting(
      BlankLinesAfterImports.self,
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

  @Test func onlyImports() {
    assertFormatting(
      BlankLinesAfterImports.self,
      input: """
        import ModuleA
        import ModuleB
        """,
      expected: """
        import ModuleA
        import ModuleB
        """,
      findings: []
    )
  }

  @Test func noImports() {
    assertFormatting(
      BlankLinesAfterImports.self,
      input: """
        class Foo {}
        """,
      expected: """
        class Foo {}
        """,
      findings: []
    )
  }
}
