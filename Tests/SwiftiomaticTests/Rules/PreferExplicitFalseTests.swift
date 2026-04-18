@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferExplicitFalseTests: RuleTesting {

  // MARK: - Basic transformations

  @Test func basicNegation() {
    assertFormatting(
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
      PreferExplicitFalse.self,
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
