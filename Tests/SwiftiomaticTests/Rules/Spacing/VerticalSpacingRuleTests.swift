import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

// MARK: - BlankLineAfterImportsRule

@Suite(.rulesRegistered)
struct BlankLineAfterImportsRuleTests {
  @Test func noViolationWithBlankLine() async {
    await assertNoViolation(
      BlankLineAfterImportsRule.self,
      """
      import Foundation

      class Foo {}
      """)
  }

  @Test func noViolationForConsecutiveImports() async {
    await assertNoViolation(
      BlankLineAfterImportsRule.self,
      """
      import Foundation
      import UIKit

      class Foo {}
      """)
  }

  @Test func detectsMissingBlankLine() async {
    await assertViolates(
      BlankLineAfterImportsRule.self,
      """
      import Foundation
      class Foo {}
      """)
  }

  @Test func correctsMissingBlankLine() async {
    await assertFormatting(
      BlankLineAfterImportsRule.self,
      input: "import Foundation\nclass Foo {}\n",
      expected: "import Foundation\n\nclass Foo {}\n")
  }
}

// MARK: - BlankLineAfterGuardRule

@Suite(.rulesRegistered)
struct BlankLineAfterGuardRuleTests {
  @Test func noViolationWithBlankLine() async {
    await assertNoViolation(
      BlankLineAfterGuardRule.self,
      """
      func foo() {
          guard let foo = bar else { return }

          print(foo)
      }
      """)
  }

  @Test func noViolationForConsecutiveGuards() async {
    await assertNoViolation(
      BlankLineAfterGuardRule.self,
      """
      func foo() {
          guard let a = b else { return }
          guard let c = d else { return }

          print(a, c)
      }
      """)
  }

  @Test func detectsMissingBlankAfterGuard() async {
    await assertViolates(
      BlankLineAfterGuardRule.self,
      """
      func foo() {
          guard let foo = bar else { return }
          print(foo)
      }
      """)
  }
}

// MARK: - BlankLinesAroundMarkRule

@Suite(.rulesRegistered)
struct BlankLinesAroundMarkRuleTests {
  @Test func noViolationWithBlankLines() async {
    await assertNoViolation(
      BlankLinesAroundMarkRule.self,
      """
      func foo() {}

      // MARK: - Bar

      func bar() {}
      """)
  }

  @Test func detectsMissingBlankLinesAroundMark() async {
    await assertViolates(
      BlankLinesAroundMarkRule.self,
      """
      func foo() {}
      // MARK: - Bar
      func bar() {}
      """)
  }
}

// MARK: - NoBlankLineInChainRule

@Suite(.rulesRegistered)
struct NoBlankLineInChainRuleTests {
  @Test func noViolationForDirectChain() async {
    await assertNoViolation(
      NoBlankLineInChainRule.self,
      """
      let result = [0, 1, 2]
          .map { $0 * 2 }
          .filter { $0 > 0 }
      """)
  }

  @Test func detectsBlankLineBetweenChainedCalls() async {
    await assertViolates(
      NoBlankLineInChainRule.self,
      """
      let result = [0, 1, 2]
          .map { $0 * 2 }

          .filter { $0 > 0 }
      """)
  }
}

// MARK: - BlankLinesBetweenImportsRule

@Suite(.rulesRegistered)
struct BlankLinesBetweenImportsRuleTests {
  @Test func noViolationForConsecutiveImports() async {
    await assertNoViolation(
      BlankLinesBetweenImportsRule.self,
      """
      import A
      import B
      import C
      """)
  }

  @Test func detectsBlankLineBetweenImports() async {
    await assertViolates(BlankLinesBetweenImportsRule.self, "import A\n\nimport B\n")
  }

  @Test func correctsBlankLineBetweenImports() async {
    await assertFormatting(
      BlankLinesBetweenImportsRule.self,
      input: "import A\n\nimport B\n",
      expected: "import A\nimport B\n")
  }
}

// MARK: - BlankLinesBetweenScopesRule

@Suite(.rulesRegistered)
struct BlankLinesBetweenScopesRuleTests {
  @Test func noViolationWithBlankLine() async {
    await assertNoViolation(
      BlankLinesBetweenScopesRule.self,
      """
      class Foo {}

      class Bar {}
      """)
  }

  @Test func detectsMissingBlankBetweenScopes() async {
    await assertViolates(
      BlankLinesBetweenScopesRule.self,
      """
      class Foo {}
      class Bar {}
      """)
  }
}
