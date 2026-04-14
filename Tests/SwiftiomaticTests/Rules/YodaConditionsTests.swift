@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct YodaConditionsTests: RuleTesting {
  @Test func integerOnLeft() {
    assertFormatting(
      YodaConditions.self,
      input: """
        if 1️⃣5 == foo {}
        """,
      expected: """
        if foo == 5 {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func nilOnLeft() {
    assertFormatting(
      YodaConditions.self,
      input: """
        if 1️⃣nil != bar {}
        """,
      expected: """
        if bar != nil {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func enumMemberOnLeft() {
    assertFormatting(
      YodaConditions.self,
      input: """
        if 1️⃣.default == style {}
        """,
      expected: """
        if style == .default {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func boolOnLeft() {
    assertFormatting(
      YodaConditions.self,
      input: """
        if 1️⃣true == flag {}
        """,
      expected: """
        if flag == true {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func stringOnLeft() {
    assertFormatting(
      YodaConditions.self,
      input: """
        if 1️⃣"hello" == greeting {}
        """,
      expected: """
        if greeting == "hello" {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func lessThanFlipped() {
    assertFormatting(
      YodaConditions.self,
      input: """
        if 1️⃣0 < count {}
        """,
      expected: """
        if count > 0 {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func greaterThanFlipped() {
    assertFormatting(
      YodaConditions.self,
      input: """
        if 1️⃣10 >= x {}
        """,
      expected: """
        if x <= 10 {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }

  @Test func constantOnRightNotModified() {
    assertFormatting(
      YodaConditions.self,
      input: """
        if foo == 5 {}
        if bar != nil {}
        if x > 0 {}
        """,
      expected: """
        if foo == 5 {}
        if bar != nil {}
        if x > 0 {}
        """,
      findings: []
    )
  }

  @Test func bothConstantsNotModified() {
    assertFormatting(
      YodaConditions.self,
      input: """
        if 1 == 1 {}
        if nil == nil {}
        """,
      expected: """
        if 1 == 1 {}
        if nil == nil {}
        """,
      findings: []
    )
  }

  @Test func bothVariablesNotModified() {
    assertFormatting(
      YodaConditions.self,
      input: """
        if foo == bar {}
        """,
      expected: """
        if foo == bar {}
        """,
      findings: []
    )
  }

  @Test func floatOnLeft() {
    assertFormatting(
      YodaConditions.self,
      input: """
        if 1️⃣3.14 == pi {}
        """,
      expected: """
        if pi == 3.14 {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place the constant on the right side of the comparison"),
      ]
    )
  }
}
