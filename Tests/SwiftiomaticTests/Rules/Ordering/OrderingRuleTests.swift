import Testing

@testable import SwiftiomaticKit

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

