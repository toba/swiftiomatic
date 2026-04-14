@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct ConditionalAssignmentTests: RuleTesting {

  // MARK: - If expression

  @Test func convertsIfStatementAssignment() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        1️⃣if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """,
      expected: """
        let foo: Foo = if condition {
            Foo("foo")
        } else {
            Foo("bar")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use if/switch expression for conditional assignment")])
  }

  @Test func convertsVarIfStatementAssignment() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        var foo: Foo
        1️⃣if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """,
      expected: """
        var foo: Foo = if condition {
            Foo("foo")
        } else {
            Foo("bar")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use if/switch expression for conditional assignment")])
  }

  @Test func convertsIfElseIfElseAssignment() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        1️⃣if conditionA {
            foo = Foo("a")
        } else if conditionB {
            foo = Foo("b")
        } else {
            foo = Foo("c")
        }
        """,
      expected: """
        let foo: Foo = if conditionA {
            Foo("a")
        } else if conditionB {
            Foo("b")
        } else {
            Foo("c")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use if/switch expression for conditional assignment")])
  }

  // MARK: - Switch expression

  @Test func convertsSimpleSwitchStatementAssignment() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        1️⃣switch condition {
        case true:
            foo = Foo("foo")
        case false:
            foo = Foo("bar")
        }
        """,
      expected: """
        let foo: Foo = switch condition {
        case true:
            Foo("foo")
        case false:
            Foo("bar")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use if/switch expression for conditional assignment")])
  }

  @Test func convertsSwitchWithDefaultCase() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        1️⃣switch condition {
        case .foo:
            foo = Foo("foo")
        case .bar:
            foo = Foo("bar")
        default:
            foo = Foo("default")
        }
        """,
      expected: """
        let foo: Foo = switch condition {
        case .foo:
            Foo("foo")
        case .bar:
            Foo("bar")
        default:
            Foo("default")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use if/switch expression for conditional assignment")])
  }

  @Test func convertsSwitchWithUnknownDefaultCase() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        1️⃣switch condition {
        case .foo:
            foo = Foo("foo")
        case .bar:
            foo = Foo("bar")
        @unknown default:
            foo = Foo("default")
        }
        """,
      expected: """
        let foo: Foo = switch condition {
        case .foo:
            Foo("foo")
        case .bar:
            Foo("bar")
        @unknown default:
            Foo("default")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use if/switch expression for conditional assignment")])
  }

  // MARK: - Nested conditionals

  @Test func convertsNestedIfSwitchStatementAssignments() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        1️⃣switch condition {
        case true:
            if condition {
                foo = Foo("foo")
            } else {
                foo = Foo("bar")
            }

        case false:
            switch condition {
            case true:
                foo = Foo("baaz")

            case false:
                if condition {
                    foo = Foo("quux")
                } else {
                    foo = Foo("quack")
                }
            }
        }
        """,
      expected: """
        let foo: Foo = switch condition {
        case true:
            if condition {
                Foo("foo")
            } else {
                Foo("bar")
            }

        case false:
            switch condition {
            case true:
                Foo("baaz")

            case false:
                if condition {
                    Foo("quux")
                } else {
                    Foo("quack")
                }
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use if/switch expression for conditional assignment")])
  }

  // MARK: - No-ops

  @Test func doesNotConvertWithoutTypeAnnotation() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo = defaultValue
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """,
      expected: """
        let foo = defaultValue
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """)
  }

  @Test func doesNotConvertMultiStatementBranch() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        if condition {
            foo = Foo("foo")
            print("Multi-statement")
        } else {
            foo = Foo("bar")
        }
        """,
      expected: """
        let foo: Foo
        if condition {
            foo = Foo("foo")
            print("Multi-statement")
        } else {
            foo = Foo("bar")
        }
        """)
  }

  @Test func doesNotConvertMultiStatementSwitchBranch() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        switch condition {
        case true:
            foo = Foo("foo")
            print("Multi-statement")

        case false:
            foo = Foo("bar")
        }
        """,
      expected: """
        let foo: Foo
        switch condition {
        case true:
            foo = Foo("foo")
            print("Multi-statement")

        case false:
            foo = Foo("bar")
        }
        """)
  }

  @Test func doesNotConvertDifferentPropertyAssignments() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        var foo: Foo?
        var bar: Bar?
        if condition {
            foo = Foo("foo")
        } else {
            bar = Bar("bar")
        }
        """,
      expected: """
        var foo: Foo?
        var bar: Bar?
        if condition {
            foo = Foo("foo")
        } else {
            bar = Bar("bar")
        }
        """)
  }

  @Test func doesNotConvertNonExhaustiveIfStatement() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        var foo: Foo?
        if condition {
            foo = Foo("foo")
        } else if someOtherCondition {
            foo = Foo("bar")
        }
        """,
      expected: """
        var foo: Foo?
        if condition {
            foo = Foo("foo")
        } else if someOtherCondition {
            foo = Foo("bar")
        }
        """)
  }

  @Test func doesNotConvertNonExhaustiveNestedIf() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        var foo: Foo?
        if condition {
            if condition {
                foo = Foo("foo")
            }
        } else {
            foo = Foo("bar")
        }
        """,
      expected: """
        var foo: Foo?
        if condition {
            if condition {
                foo = Foo("foo")
            }
        } else {
            foo = Foo("bar")
        }
        """)
  }

  @Test func doesNotConvertMultiplePropertyDeclarations() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        let bar: Bar
        if condition {
            foo = Foo("foo")
            bar = Bar("foo")
        } else {
            foo = Foo("bar")
            bar = Bar("bar")
        }
        """,
      expected: """
        let foo: Foo
        let bar: Bar
        if condition {
            foo = Foo("foo")
            bar = Bar("foo")
        } else {
            foo = Foo("bar")
            bar = Bar("bar")
        }
        """)
  }

  @Test func preservesSwitchWithReturnInDefaultCase() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        switch condition {
        case .foo:
            foo = Foo("foo")
        case .bar:
            foo = Foo("bar")
        default:
            return
        }
        """,
      expected: """
        let foo: Foo
        switch condition {
        case .foo:
            foo = Foo("foo")
        case .bar:
            foo = Foo("bar")
        default:
            return
        }
        """)
  }

  @Test func doesNotConvertIfStatementWithForLoopInBranch() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        var foo: Foo?
        if condition {
            foo = Foo("foo")
            for foo in foos {
                print(foo)
            }
        } else {
            foo = Foo("bar")
        }
        """,
      expected: """
        var foo: Foo?
        if condition {
            foo = Foo("foo")
            for foo in foos {
                print(foo)
            }
        } else {
            foo = Foo("bar")
        }
        """)
  }

  @Test func doesNotConvertCommentBetweenDeclAndConditional() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        // This is a comment between the property and condition
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """,
      expected: """
        let foo: Foo
        // This is a comment between the property and condition
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """)
  }

  @Test func doesNotConvertMultiBindingDeclaration() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo, bar: Bar
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """,
      expected: """
        let foo: Foo, bar: Bar
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """)
  }

  @Test func doesNotConvertPropertyWithInitializer() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo = .default
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """,
      expected: """
        let foo: Foo = .default
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """)
  }

  @Test func doesNotConvertIfWithoutElse() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        var foo: Foo?
        if condition {
            foo = Foo("foo")
        }
        """,
      expected: """
        var foo: Foo?
        if condition {
            foo = Foo("foo")
        }
        """)
  }

  @Test func convertsSingleCaseSwitchAssignment() {
    assertFormatting(
      ConditionalAssignment.self,
      input: """
        let foo: Foo
        1️⃣switch condition {
        case .only:
            foo = value
        }
        """,
      expected: """
        let foo: Foo = switch condition {
        case .only:
            value
        }
        """,
      findings: [FindingSpec("1️⃣", message: "use if/switch expression for conditional assignment")])
  }

}
