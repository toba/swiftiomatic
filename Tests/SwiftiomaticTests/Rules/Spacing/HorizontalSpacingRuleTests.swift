import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

// MARK: - ConsecutiveSpacesRule

@Suite(.rulesRegistered)
struct ConsecutiveSpacesRuleTests {
  @Test func noViolationForSingleSpaces() async {
    await assertNoViolation(ConsecutiveSpacesRule.self, "let foo = 5")
  }

  @Test func noViolationInComments() async {
    await assertNoViolation(ConsecutiveSpacesRule.self, "// comment with   multiple spaces")
  }

  @Test func noViolationInBlockComments() async {
    await assertNoViolation(ConsecutiveSpacesRule.self, "/* block   comment */")
  }

  @Test func detectsConsecutiveSpaces() async {
    await assertViolates(ConsecutiveSpacesRule.self, "let  foo = 5")
  }

  @Test func detectsConsecutiveSpacesBeforeValue() async {
    await assertViolates(ConsecutiveSpacesRule.self, "let foo =  5")
  }

  @Test func correctsConsecutiveSpaces() async {
    await assertFormatting(
      ConsecutiveSpacesRule.self,
      input: "let  foo = 5",
      expected: "let foo = 5")
  }
}

// MARK: - SpaceInsideBracketsRule

@Suite(.rulesRegistered)
struct SpaceInsideBracketsRuleTests {
  @Test func noViolationForCleanBrackets() async {
    await assertNoViolation(SpaceInsideBracketsRule.self, "let a = [1, 2, 3]")
  }

  @Test func noViolationForSubscript() async {
    await assertNoViolation(SpaceInsideBracketsRule.self, "let b = foo[0]")
  }

  @Test func detectsSpaceInsideBrackets() async {
    await assertViolates(SpaceInsideBracketsRule.self, "let a = [ 1, 2, 3 ]")
  }
}

// MARK: - SpaceInsideParensRule

@Suite(.rulesRegistered)
struct SpaceInsideParensRuleTests {
  @Test func noViolationForCleanParens() async {
    await assertNoViolation(SpaceInsideParensRule.self, "let x = foo(bar)")
  }

  @Test func detectsSpaceInsideParens() async {
    await assertViolates(SpaceInsideParensRule.self, "let x = foo( bar )")
  }
}

// MARK: - SpaceInsideGenericsRule

@Suite(.rulesRegistered)
struct SpaceInsideGenericsRuleTests {
  @Test func noViolationForCleanGenerics() async {
    await assertNoViolation(SpaceInsideGenericsRule.self, "let a: Array<Int> = []")
  }

  @Test func detectsSpaceInsideGenerics() async {
    await assertViolates(SpaceInsideGenericsRule.self, "let a: Array< Int > = []")
  }
}

// MARK: - SpaceAroundBracketsRule

@Suite(.rulesRegistered)
struct SpaceAroundBracketsRuleTests {
  @Test func noViolationForDirectSubscript() async {
    await assertNoViolation(SpaceAroundBracketsRule.self, "let x = foo[0]")
  }

  @Test func detectsSpaceBeforeSubscript() async {
    await assertViolates(SpaceAroundBracketsRule.self, "let x = foo [0]")
  }
}

// MARK: - SpaceAroundParensRule

@Suite(.rulesRegistered)
struct SpaceAroundParensRuleTests {
  @Test func noViolationForDirectCall() async {
    await assertNoViolation(SpaceAroundParensRule.self, "let x = foo(bar)")
  }

  @Test func noViolationForControlFlow() async {
    await assertNoViolation(SpaceAroundParensRule.self, "if (condition) {}")
  }
}

// MARK: - SpaceAroundGenericsRule

@Suite(.rulesRegistered)
struct SpaceAroundGenericsRuleTests {
  @Test func noViolationForCleanGenerics() async {
    await assertNoViolation(SpaceAroundGenericsRule.self, "let a: Array<Int> = []")
  }

  @Test func detectsSpaceBeforeGenericBracket() async {
    await assertViolates(SpaceAroundGenericsRule.self, "let a: Array <Int> = []")
  }
}

// MARK: - SpaceAroundCommentsRule

@Suite(.rulesRegistered)
struct SpaceAroundCommentsRuleTests {
  @Test func noViolationWithSpaceBeforeComment() async {
    await assertNoViolation(SpaceAroundCommentsRule.self, "let a = 5 // comment")
  }
}

// MARK: - LeadingDelimitersRule

@Suite(.rulesRegistered)
struct LeadingDelimitersRuleTests {
  @Test func noViolationForTrailingComma() async {
    await assertNoViolation(
      LeadingDelimitersRule.self,
      """
      guard let foo = maybeFoo,
            let bar = maybeBar else { return }
      """)
  }

  @Test func detectsLeadingComma() async {
    await assertViolates(
      LeadingDelimitersRule.self,
      """
      guard let foo = maybeFoo
            , let bar = maybeBar else { return }
      """)
  }
}
