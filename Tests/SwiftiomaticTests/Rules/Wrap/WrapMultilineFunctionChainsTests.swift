@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapMultilineFunctionChainsTests: RuleTesting {

  // MARK: - Wrapping inconsistent chains

  @Test func wrapInconsistentChain() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        let evenSquaresSum = [20, 17, 35, 4]
            .filter { $0 % 2 == 0 }1️⃣.map { $0 * $0 }
            .reduce(0, +)
        """,
      expected: """
        let evenSquaresSum = [20, 17, 35, 4]
            .filter { $0 % 2 == 0 }
            .map { $0 * $0 }
            .reduce(0, +)
        """,
      findings: [FindingSpec("1️⃣", message: "wrap multiline function chain consistently")])
  }

  @Test func wrapNestedFunctionCallsWithTrailingClosures() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        let result = array
            .map { $0.filter { $1 > 10 } }1️⃣.flatMap { $0 }
        """,
      expected: """
        let result = array
            .map { $0.filter { $1 > 10 } }
            .flatMap { $0 }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap multiline function chain consistently")])
  }

  @Test func wrapChainWithMultilineClosureBody() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        let result = array
            .map { item in
                item.property
            }1️⃣.filter { $0 > 10 }
            .reduce(0, +)
        """,
      expected: """
        let result = array
            .map { item in
                item.property
            }
            .filter { $0 > 10 }
            .reduce(0, +)
        """,
      findings: [FindingSpec("1️⃣", message: "wrap multiline function chain consistently")])
  }

  @Test func wrapChainWithMultilineArguments() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        let result = array
            .function(
                arg1: item.property,
                arg2: item.property
            )1️⃣.reduce(0, +)
        """,
      expected: """
        let result = array
            .function(
                arg1: item.property,
                arg2: item.property
            )
            .reduce(0, +)
        """,
      findings: [FindingSpec("1️⃣", message: "wrap multiline function chain consistently")])
  }

  // MARK: - No-ops

  @Test func singleFunctionCallNotWrapped() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        let result = array.map { $0 * 2 }
        """,
      expected: """
        let result = array.map { $0 * 2 }
        """)
  }

  @Test func allOnOneLineNotWrapped() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        let result = array.map { $0 * 2 }.filter { $0 > 10 }.reduce(0, +)
        """,
      expected: """
        let result = array.map { $0 * 2 }.filter { $0 > 10 }.reduce(0, +)
        """)
  }

  @Test func alreadyWrappedNotChanged() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        let result = array
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """,
      expected: """
        let result = array
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """)
  }

  @Test func alreadyWrappedWithOptionalChainingNotChanged() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        let result = array?
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """,
      expected: """
        let result = array?
            .map { $0 * 2 }
            .filter { $0 > 10 }
            .reduce(0, +)
        """)
  }

  @Test func consecutiveDeclarationsNotContaminated() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        let sequence = [42].async
        let sequence = [43].async
        """,
      expected: """
        let sequence = [42].async
        let sequence = [43].async
        """)
  }

  @Test func consecutiveStatementsNotContaminated() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        let encoded = try JSONEncoder().encode(container)
        let decoded = try JSONDecoder().decode(Container.self, from: encoded)
        """,
      expected: """
        let encoded = try JSONEncoder().encode(container)
        let decoded = try JSONDecoder().decode(Container.self, from: encoded)
        """)
  }

  @Test func namespacedAccessNotWrapped() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        Namespace.NestedNamespace.property
            .map { $0 * 2 }
        """,
      expected: """
        Namespace.NestedNamespace.property
            .map { $0 * 2 }
        """)
  }

  @Test func chainWithCommentsNotWrapped() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        let result = array
            .map { $0 * 2 } // multiply by 2
            .filter { $0 > 10 } // filter greater than 10
            .reduce(0, +) // sum up
        """,
      expected: """
        let result = array
            .map { $0 * 2 } // multiply by 2
            .filter { $0 > 10 } // filter greater than 10
            .reduce(0, +) // sum up
        """)
  }

  @Test func adjacentChainsInViewBuilders() {
    assertFormatting(
      WrapMultilineFunctionChains.self,
      input: """
        Text("S")
            .padding(10)
        Color.blue.frame(maxWidth: 1, maxHeight: .infinity).fixedSize()
        """,
      expected: """
        Text("S")
            .padding(10)
        Color.blue.frame(maxWidth: 1, maxHeight: .infinity).fixedSize()
        """)
  }
}
