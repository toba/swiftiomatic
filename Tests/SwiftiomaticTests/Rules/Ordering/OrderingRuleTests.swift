import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

// MARK: - SortImportsRule

@Suite(.rulesRegistered)
struct SortImportsRuleTests {
  @Test func noViolationForSortedImports() async {
    await assertNoViolation(
      SortImportsRule.self,
      """
      import Bar
      import Foo
      """)
  }

  @Test func detectsUnsortedImports() async {
    await assertViolates(
      SortImportsRule.self,
      """
      import Foo
      import Bar
      """)
  }

  @Test func correctsUnsortedImports() async {
    await assertFormatting(
      SortImportsRule.self,
      input: "import Foo\nimport Bar\n",
      expected: "import Bar\nimport Foo\n")
  }

  // MARK: Length sorting

  @Test func noViolationForLengthSortedImports() async {
    await assertNoViolation(
      SortImportsRule.self,
      """
      import Foo
      import BarBar
      import BazBazBaz
      """,
      configuration: ["sort_order": "length"])
  }

  @Test func detectsUnsortedImportsByLength() async {
    await assertViolates(
      SortImportsRule.self,
      """
      import BazBazBaz
      import Foo
      import BarBar
      """,
      configuration: ["sort_order": "length"])
  }

  @Test func correctsUnsortedImportsByLength() async {
    await assertFormatting(
      SortImportsRule.self,
      input: "import BazBazBaz\nimport Foo\nimport BarBar\n",
      expected: "import Foo\nimport BarBar\nimport BazBazBaz\n",
      configuration: ["sort_order": "length"])
  }

  @Test func lengthSortBreaksTiesAlphabetically() async {
    await assertFormatting(
      SortImportsRule.self,
      input: "import Foo\nimport Bar\nimport Baz\n",
      expected: "import Bar\nimport Baz\nimport Foo\n",
      configuration: ["sort_order": "length"])
  }

  // MARK: Contiguous grouping (default)

  @Test func contiguousGroupingPreservesBlankLineSeparation() async {
    await assertNoViolation(
      SortImportsRule.self,
      """
      import Foundation
      import UIKit

      import Alamofire
      import SnapKit
      """)
  }

  @Test func contiguousGroupingSortsWithinEachGroup() async {
    await assertFormatting(
      SortImportsRule.self,
      input: "import UIKit\nimport Foundation\n\nimport SnapKit\nimport Alamofire\n",
      expected: "import Foundation\nimport UIKit\n\nimport Alamofire\nimport SnapKit\n")
  }

  @Test func contiguousGroupingBreaksOnComments() async {
    await assertNoViolation(
      SortImportsRule.self,
      """
      import Foundation
      import UIKit
      // Third party
      import Alamofire
      """)
  }

  // MARK: Attributed import grouping

  @Test func groupAttributedImportsNoViolationWhenGrouped() async {
    await assertNoViolation(
      SortImportsRule.self,
      """
      import Bar
      import Foo

      @testable import Baz
      """,
      configuration: ["group_attributed_imports": true])
  }

  @Test func groupAttributedImportsDetectsUngrouped() async {
    await assertViolates(
      SortImportsRule.self,
      """
      @testable import Baz
      import Bar
      import Foo
      """,
      configuration: ["group_attributed_imports": true])
  }

  @Test func groupAttributedImportsCorrects() async {
    await assertFormatting(
      SortImportsRule.self,
      input: "@testable import Baz\nimport Foo\nimport Bar\n",
      expected: "import Bar\nimport Foo\n\n@testable import Baz\n",
      configuration: ["group_attributed_imports": true])
  }

  @Test func groupAttributedImportsSortsWithinKind() async {
    await assertFormatting(
      SortImportsRule.self,
      input: "import Foo\nimport Bar\n@testable import Zed\n@testable import Abc\n",
      expected: "import Bar\nimport Foo\n\n@testable import Abc\n@testable import Zed\n",
      configuration: ["group_attributed_imports": true])
  }

  @Test func groupAttributedImportsHandlesImplementationOnly() async {
    await assertFormatting(
      SortImportsRule.self,
      input: "@testable import Z\n@_implementationOnly import Y\nimport X\n",
      expected: "import X\n\n@_implementationOnly import Y\n\n@testable import Z\n",
      configuration: ["group_attributed_imports": true])
  }

  @Test func groupAttributedImportsDisabledByDefault() async {
    // Without the option, @testable and regular imports are sorted together
    await assertNoViolation(
      SortImportsRule.self,
      """
      import Bar
      @testable import Foo
      """)
  }

  // MARK: All grouping

  @Test func allGroupingIgnoresBlankLines() async {
    await assertFormatting(
      SortImportsRule.self,
      input: "import UIKit\nimport Foundation\n\nimport Alamofire\n",
      expected: "import Alamofire\nimport Foundation\n\nimport UIKit\n",
      configuration: ["grouping": "all"])
  }

  @Test func allGroupingIgnoresComments() async {
    await assertViolates(
      SortImportsRule.self,
      """
      import UIKit
      // Third party
      import Alamofire
      """,
      configuration: ["grouping": "all"])
  }
}

// MARK: - SortDeclarationsRule

@Suite(.rulesRegistered)
struct SortDeclarationsRuleTests {
  @Test func noViolationForSortedEnum() async {
    await assertNoViolation(
      SortDeclarationsRule.self,
      """
      // sm:sort
      enum FeatureFlags {
          case barFeature
          case fooFeature
      }
      """)
  }

  @Test func detectsUnsortedDeclarations() async {
    await assertViolates(
      SortDeclarationsRule.self,
      """
      // sm:sort
      enum FeatureFlags {
          case fooFeature
          case barFeature
      }
      """)
  }
}

// MARK: - SortSwitchCasesRule

@Suite(.rulesRegistered)
struct SortSwitchCasesRuleTests {
  @Test func noViolationForSortedCases() async {
    await assertNoViolation(
      SortSwitchCasesRule.self,
      """
      switch value {
      case .a, .b, .c:
          break
      }
      """)
  }

  @Test func detectsUnsortedCases() async {
    await assertViolates(
      SortSwitchCasesRule.self,
      """
      switch value {
      case .c, .a, .b:
          break
      }
      """)
  }
}

// MARK: - SortTypealiasesRule

@Suite(.rulesRegistered)
struct SortTypealiasesRuleTests {
  @Test func noViolationForSortedTypealias() async {
    await assertNoViolation(
      SortTypealiasesRule.self,
      "typealias Dependencies = Bar & Foo & Quux")
  }

  @Test func detectsUnsortedTypealias() async {
    await assertViolates(
      SortTypealiasesRule.self,
      "typealias Dependencies = Foo & Bar & Quux")
  }
}

