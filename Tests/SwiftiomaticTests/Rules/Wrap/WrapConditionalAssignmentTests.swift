@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapMultilineConditionalAssignmentTests: RuleTesting {

  // MARK: - If expression assignments

  @Test func wrapIfExpressionAssignment() {
    assertFormatting(
      WrapConditionalAssignment.self,
      input: """
        let foo 1️⃣= if let bar {
            bar
        } else {
            baaz
        }
        """,
      expected: """
        let foo =
        if let bar {
            bar
        } else {
            baaz
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap multiline conditional assignment after '='")])
  }

  @Test func unwrapsAssignmentOperatorInIfExpressionAssignment() {
    assertFormatting(
      WrapConditionalAssignment.self,
      input: """
        let foo
            1️⃣= if let bar {
                bar
            } else {
                baaz
            }
        """,
      expected: """
        let foo =
            if let bar {
                bar
            } else {
                baaz
            }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap multiline conditional assignment after '='")])
  }

  @Test func unwrapsAssignmentOperatorInIfExpressionFollowingComment() {
    assertFormatting(
      WrapConditionalAssignment.self,
      input: """
        let foo
            // In order to unwrap the `=` here it has to move it to
            // before the comment, rather than simply unwrapping it.
            1️⃣= if let bar {
                bar
            } else {
                baaz
            }
        """,
      expected: """
        let foo =
            // In order to unwrap the `=` here it has to move it to
            // before the comment, rather than simply unwrapping it.
            if let bar {
                bar
            } else {
                baaz
            }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap multiline conditional assignment after '='")])
  }

  // MARK: - Reassignments (without let/var)

  @Test func wrapIfAssignmentWithoutIntroducer() {
    assertFormatting(
      WrapConditionalAssignment.self,
      input: """
        property 1️⃣= if condition {
            Foo("foo")
        } else {
            Foo("bar")
        }
        """,
      expected: """
        property =
        if condition {
            Foo("foo")
        } else {
            Foo("bar")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap multiline conditional assignment after '='")])
  }

  // MARK: - Switch expression assignments

  @Test func wrapSwitchAssignmentWithoutIntroducer() {
    assertFormatting(
      WrapConditionalAssignment.self,
      input: """
        property 1️⃣= switch condition {
        case true:
            Foo("foo")
        case false:
            Foo("bar")
        }
        """,
      expected: """
        property =
        switch condition {
        case true:
            Foo("foo")
        case false:
            Foo("bar")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap multiline conditional assignment after '='")])
  }

  @Test func wrapSwitchAssignmentWithComplexLValue() {
    assertFormatting(
      WrapConditionalAssignment.self,
      input: """
        property?.foo!.bar["baaz"] 1️⃣= switch condition {
        case true:
            Foo("foo")
        case false:
            Foo("bar")
        }
        """,
      expected: """
        property?.foo!.bar["baaz"] =
        switch condition {
        case true:
            Foo("foo")
        case false:
            Foo("bar")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap multiline conditional assignment after '='")])
  }

  // MARK: - No-ops

  @Test func singleLineIfExpressionUnchanged() {
    assertFormatting(
      WrapConditionalAssignment.self,
      input: """
        let foo = if bar { a } else { b }
        """,
      expected: """
        let foo = if bar { a } else { b }
        """)
  }

  @Test func alreadyWrappedIfExpressionUnchanged() {
    assertFormatting(
      WrapConditionalAssignment.self,
      input: """
        let foo =
            if let bar {
                bar
            } else {
                baaz
            }
        """,
      expected: """
        let foo =
            if let bar {
                bar
            } else {
                baaz
            }
        """)
  }

  @Test func singleLineSwitchExpressionUnchanged() {
    assertFormatting(
      WrapConditionalAssignment.self,
      input: """
        let x = switch val { case .a: 1 case .b: 2 }
        """,
      expected: """
        let x = switch val { case .a: 1 case .b: 2 }
        """)
  }

  @Test func nonConditionalAssignmentUnchanged() {
    assertFormatting(
      WrapConditionalAssignment.self,
      input: """
        let foo = bar
        """,
      expected: """
        let foo = bar
        """)
  }

  @Test func letSwitchAlreadyWrapped() {
    assertFormatting(
      WrapConditionalAssignment.self,
      input: """
        let x =
            switch value {
            case .a:
                1
            case .b:
                2
            }
        """,
      expected: """
        let x =
            switch value {
            case .a:
                1
            case .b:
                2
            }
        """)
  }
}
