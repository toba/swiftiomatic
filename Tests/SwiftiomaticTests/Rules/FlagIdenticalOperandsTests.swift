@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagIdenticalOperandsTests: RuleTesting {
  @Test func identicalIntLiterals() {
    assertLint(
      FlagIdenticalOperands.self,
      """
      _ = 1️⃣1 == 1
      _ = 2️⃣foo == foo
      _ = 3️⃣foo.aProperty == foo.aProperty
      _ = 4️⃣self.aProperty == self.aProperty
      _ = 5️⃣$0 == $0
      _ = 6️⃣a?.b == a?.b
      """,
      findings: [
        FindingSpec("1️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("2️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("3️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("4️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("5️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("6️⃣", message: "comparing two identical operands is likely a mistake"),
      ]
    )
  }

  @Test func differentOperandsDoNotTrigger() {
    assertLint(
      FlagIdenticalOperands.self,
      """
      _ = 1 == 2
      _ = foo == bar
      _ = foo.aProperty == foo.anotherProperty
      _ = self.aProperty == aProperty
      _ = lhs.identifier == rhs.identifier
      _ = $0 == 0
      _ = string == string.lowercased()
      _ = type(of: model).cachePrefix == cachePrefix
      """,
      findings: []
    )
  }

  @Test func allComparisonOperators() {
    assertLint(
      FlagIdenticalOperands.self,
      """
      _ = 1️⃣foo == foo
      _ = 2️⃣foo != foo
      _ = 3️⃣foo === foo
      _ = 4️⃣foo !== foo
      _ = 5️⃣foo > foo
      _ = 6️⃣foo >= foo
      _ = 7️⃣foo < foo
      _ = 8️⃣foo <= foo
      """,
      findings: [
        FindingSpec("1️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("2️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("3️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("4️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("5️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("6️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("7️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("8️⃣", message: "comparing two identical operands is likely a mistake"),
      ]
    )
  }

  @Test func nonComparisonOperatorsIgnored() {
    assertLint(
      FlagIdenticalOperands.self,
      """
      _ = foo + foo
      _ = foo - foo
      _ = foo * foo
      _ = foo && foo
      _ = foo || foo
      """,
      findings: []
    )
  }

  @Test func whitespaceInsensitive() {
    assertLint(
      FlagIdenticalOperands.self,
      """
      _ = 1️⃣1 + 1 == 1 + 1
      _ = 2️⃣f(i: 2) == f(i: 2)
      """,
      findings: [
        FindingSpec("1️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("2️⃣", message: "comparing two identical operands is likely a mistake"),
      ]
    )
  }

  @Test func insideControlFlow() {
    assertLint(
      FlagIdenticalOperands.self,
      """
      if 1️⃣elem == elem {}
      guard 2️⃣x == x else { return }
      while 3️⃣i == i { break }
      """,
      findings: [
        FindingSpec("1️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("2️⃣", message: "comparing two identical operands is likely a mistake"),
        FindingSpec("3️⃣", message: "comparing two identical operands is likely a mistake"),
      ]
    )
  }

  @Test func stringInterpolationNoFalsePositive() {
    // String interpolations with identical content should NOT trigger because
    // they're typically used in sort comparators where $0 and $1 differ.
    assertLint(
      FlagIdenticalOperands.self,
      #"""
      _ = array.sorted { "\($0)" < "\($1)" }
      """#,
      findings: []
    )
  }
}
