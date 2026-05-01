@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseExplicitFalseInGuardsTests: RuleTesting {

  // MARK: - Basic transformations

  @Test func basicNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!flag {
            print("false")
        }
        """,
      expected: """
        if flag == false {
            print("false")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func guardNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        guard 1️⃣!array.isEmpty else { return }
        """,
      expected: """
        guard array.isEmpty == false else { return }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func whileNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        while 1️⃣!finished {
            doWork()
        }
        """,
      expected: """
        while finished == false {
            doWork()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func propertyNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!view.isHidden {
            view.show()
        }
        """,
      expected: """
        if view.isHidden == false {
            view.show()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func functionCallNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!foo.bar() {
            handleFalse()
        }
        """,
      expected: """
        if foo.bar() == false {
            handleFalse()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func methodCallNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!array.contains(value) {
            addValue(value)
        }
        """,
      expected: """
        if array.contains(value) == false {
            addValue(value)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func parenthesizedExpressionNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!(a && b) {
            handleBothFalse()
        }
        """,
      expected: """
        if (a && b) == false {
            handleBothFalse()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func complexExpressionNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!(foo.bar() && baz.qux()) {
            handleComplexFalse()
        }
        """,
      expected: """
        if (foo.bar() && baz.qux()) == false {
            handleComplexFalse()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func nestedPropertyNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!self.view.subviews.isEmpty {
            addSubviews()
        }
        """,
      expected: """
        if self.view.subviews.isEmpty == false {
            addSubviews()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func chainedMethodCallNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!foo.bar().baz() {
            handleChainedFalse()
        }
        """,
      expected: """
        if foo.bar().baz() == false {
            handleChainedFalse()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func multipleNegationsInSameLine() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!a && 2️⃣!b {
            handleBothFalse()
        }
        """,
      expected: """
        if a == false && b == false {
            handleBothFalse()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
        FindingSpec("2️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func negationInTernary() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        let result = 1️⃣!condition ? "false" : "true"
        """,
      expected: """
        let result = condition == false ? "false" : "true"
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func negationInReturnStatement() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        func check() -> Bool {
            return 1️⃣!isValid
        }
        """,
      expected: """
        func check() -> Bool {
            return isValid == false
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func negationInAssignment() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        let isFalse = 1️⃣!someCondition
        """,
      expected: """
        let isFalse = someCondition == false
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func negationInFunctionParameter() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        processData(data: 1️⃣!isProcessed)
        """,
      expected: """
        processData(data: isProcessed == false)
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func negationWithComments() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!flag { // check if false
            doSomething()
        }
        """,
      expected: """
        if flag == false { // check if false
            doSomething()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func subscriptNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!array[0] {
            processFirstElement()
        }
        """,
      expected: """
        if array[0] == false {
            processFirstElement()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func forceUnwrapPropertyNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if 1️⃣!foo!.isValid {
            handleInvalidFoo()
        }
        """,
      expected: """
        if foo!.isValid == false {
            handleInvalidFoo()
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func negationInClosure() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        let closure = {
            if 1️⃣!condition {
                return false
            }
            return true
        }
        """,
      expected: """
        let closure = {
            if condition == false {
                return false
            }
            return true
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func negationInSwitchCase() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        switch value {
        case let x where 1️⃣!x.isValid:
            handleInvalid(x)
        default:
            break
        }
        """,
      expected: """
        switch value {
        case let x where x.isValid == false:
            handleInvalid(x)
        default:
            break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func negationInWhereClause() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        for item in items where 1️⃣!item.isProcessed {
            process(item)
        }
        """,
      expected: """
        for item in items where item.isProcessed == false {
            process(item)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func negationInComputedProperty() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        var isEmpty: Bool {
            return 1️⃣!items.isEmpty
        }
        """,
      expected: """
        var isEmpty: Bool {
            return items.isEmpty == false
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func negationInArrayLiteral() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        let array = [1️⃣!a, 2️⃣!b, 3️⃣!c]
        """,
      expected: """
        let array = [a == false, b == false, c == false]
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
        FindingSpec("2️⃣", message: "prefer '== false' over '!' prefix negation"),
        FindingSpec("3️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func negationInDictionaryLiteral() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        let dict = ["a": 1️⃣!value, "b": 2️⃣!other]
        """,
      expected: """
        let dict = ["a": value == false, "b": other == false]
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
        FindingSpec("2️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func closureArgumentNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        let result = 1️⃣!items.contains(where: { $0.isValid })
        """,
      expected: """
        let result = items.contains(where: { $0.isValid }) == false
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  @Test func trailingClosureNegation() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        let result = 1️⃣!myArray.contains {
            $0 == value
        }
        """,
      expected: """
        let result = myArray.contains {
            $0 == value
        } == false
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer '== false' over '!' prefix negation"),
      ]
    )
  }

  // MARK: - No-change cases

  @Test func noChangeForPostfixNot() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        let value = optional!
        """,
      expected: """
        let value = optional!
        """,
      findings: []
    )
  }

  @Test func noChangeForComparisonOperators() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if a != b {
            doSomething()
        }
        """,
      expected: """
        if a != b {
            doSomething()
        }
        """,
      findings: []
    )
  }

  @Test func noChangeForExistingEqualFalse() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if flag == false {
            doSomething()
        }
        """,
      expected: """
        if flag == false {
            doSomething()
        }
        """,
      findings: []
    )
  }

  @Test func noChangeForExistingEqualTrue() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if flag == true {
            doSomething()
        }
        """,
      expected: """
        if flag == true {
            doSomething()
        }
        """,
      findings: []
    )
  }

  @Test func noChangeForOptionalBool() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        if optionalBool! {
            doSomething()
        }
        """,
      expected: """
        if optionalBool! {
            doSomething()
        }
        """,
      findings: []
    )
  }

  @Test func noChangeForBinaryNot() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        let result = ~value
        """,
      expected: """
        let result = ~value
        """,
      findings: []
    )
  }

  @Test func noChangeForNegationBeforeEquals() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        print(!a == b)
        """,
      expected: """
        print(!a == b)
        """,
      findings: []
    )
  }

  @Test func noChangeForNegationBeforeNotEquals() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        print(!a != b)
        """,
      expected: """
        print(!a != b)
        """,
      findings: []
    )
  }

  @Test func noChangeForNegationAfterEquals() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        print(a == !b)
        """,
      expected: """
        print(a == !b)
        """,
      findings: []
    )
  }

  @Test func noChangeForNegationAfterNotEquals() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        print(a != !b)
        """,
      expected: """
        print(a != !b)
        """,
      findings: []
    )
  }

  @Test func noChangeForPreprocessorDirective() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        #if !DEBUG
        #error("Not supported")
        #endif
        """,
      expected: """
        #if !DEBUG
        #error("Not supported")
        #endif
        """,
      findings: []
    )
  }

  @Test func noChangeForPreprocessorCanImport() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        #if !canImport(UIKit)
        #error("UIKit required")
        #endif
        """,
      expected: """
        #if !canImport(UIKit)
        #error("UIKit required")
        #endif
        """,
      findings: []
    )
  }

  @Test func noChangeForNegationBeforeIs() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        print(!foo is Bar)
        """,
      expected: """
        print(!foo is Bar)
        """,
      findings: []
    )
  }

  @Test func noChangeForNegationBeforeAs() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        print(!foo as? Bar)
        """,
      expected: """
        print(!foo as? Bar)
        """,
      findings: []
    )
  }

  @Test func forceUnwrappedNegationBeforeEquals() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        print(!foo! == bar)
        """,
      expected: """
        print(!foo! == bar)
        """,
      findings: []
    )
  }

  @Test func doubleNegationAfterEquals() {
    assertFormatting(
      UseExplicitFalseInGuards.self,
      input: """
        print(a == !!b)
        """,
      expected: """
        print(a == !!b)
        """,
      findings: []
    )
  }
}
