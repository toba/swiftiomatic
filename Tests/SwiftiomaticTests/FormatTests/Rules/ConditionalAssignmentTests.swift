import Testing

@testable import Swiftiomatic

@Suite struct ConditionalAssignmentTests {
  @Test func doesntConvertIfStatementAssignmentSwift5_8() {
    let input = """
      let foo: Foo
      if condition {
          foo = Foo("foo")
      } else {
          foo = Foo("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.8")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func convertsIfStatementAssignment() {
    let input = """
      let foo: Foo
      if condition {
          foo = Foo("foo")
      } else {
          foo = Foo("bar")
      }
      """
    let output = """
      let foo: Foo = if condition {
          Foo("foo")
      } else {
          Foo("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .conditionalAssignment, options: options,
      exclude: [.redundantType, .wrapMultilineConditionalAssignment])
  }

  @Test func convertsSimpleSwitchStatementAssignment() {
    let input = """
      let foo: Foo
      switch condition {
      case true:
          foo = Foo("foo")
      case false:
          foo = Foo("bar")
      }
      """
    let output = """
      let foo: Foo = switch condition {
      case true:
          Foo("foo")
      case false:
          Foo("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .conditionalAssignment, options: options,
      exclude: [.redundantType, .wrapMultilineConditionalAssignment])
  }

  @Test func convertsTrivialSwitchStatementAssignment() {
    let input = """
      let foo: Foo
      switch enumWithOnceCase(let value) {
      case singleCase:
          foo = value
      }
      """
    let output = """
      let foo: Foo = switch enumWithOnceCase(let value) {
      case singleCase:
          value
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .conditionalAssignment, options: options,
      exclude: [.wrapMultilineConditionalAssignment])
  }

  @Test func convertsNestedIfAndStatementAssignments() {
    let input = """
      let foo: Foo
      switch condition {
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
      """
    let output = """
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
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .conditionalAssignment, options: options,
      exclude: [.redundantType, .wrapMultilineConditionalAssignment])
  }

  @Test func convertsIfStatementAssignmentPreservingComment() {
    let input = """
      let foo: Foo
      // This is a comment between the property and condition
      if condition {
          foo = Foo("foo")
      } else {
          foo = Foo("bar")
      }
      """
    let output = """
      let foo: Foo
      // This is a comment between the property and condition
      = if condition {
          Foo("foo")
      } else {
          Foo("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .conditionalAssignment, options: options,
      exclude: [.indent, .redundantType, .wrapMultilineConditionalAssignment])
  }

  @Test func doesntConvertsIfStatementAssigningMultipleProperties() {
    let input = """
      let foo: Foo
      let bar: Bar
      if condition {
          foo = Foo("foo")
          bar = Bar("foo")
      } else {
          foo = Foo("bar")
          bar = Bar("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertsIfStatementAssigningDifferentProperties() {
    let input = """
      var foo: Foo?
      var bar: Bar?
      if condition {
          foo = Foo("foo")
      } else {
          bar = Bar("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertNonExhaustiveIfStatementAssignment1() {
    let input = """
      var foo: Foo?
      if condition {
          foo = Foo("foo")
      } else if someOtherCondition {
          foo = Foo("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertNonExhaustiveIfStatementAssignment2() {
    let input = """
      var foo: Foo?
      if condition {
          if condition {
              foo = Foo("foo")
          }
      } else {
          foo = Foo("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertMultiStatementIfStatementAssignment1() {
    let input = """
      let foo: Foo
      if condition {
          foo = Foo("foo")
          print("Multi-statement")
      } else {
          foo = Foo("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertMultiStatementIfStatementAssignment2() {
    let input = """
      let foo: Foo
      switch condition {
      case true:
          foo = Foo("foo")
          print("Multi-statement")

      case false:
          foo = Foo("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertMultiStatementIfStatementAssignment3() {
    let input = """
      let foo: Foo
      if condition {
          if condition {
              foo = Foo("bar")
          } else {
              foo = Foo("baaz")
          }
          print("Multi-statement")
      } else {
          foo = Foo("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertMultiStatementIfStatementAssignment4() {
    let input = """
      let foo: Foo
      switch condition {
      case true:
          if condition {
              foo = Foo("bar")
          } else {
              foo = Foo("baaz")
          }
          print("Multi-statement")

      case false:
          foo = Foo("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertMultiStatementIfStatementWithStringLiteral() {
    let input = """
      let text: String
      if conditionOne {
          text = "Hello World!"
          doSomeStuffHere()
      } else {
          text = "Goodbye!"
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertMultiStatementIfStatementWithCollectionLiteral() {
    let input = """
      let text: [String]
      if conditionOne {
          text = []
          doSomeStuffHere()
      } else {
          text = ["Goodbye!"]
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertMultiStatementIfStatementWithIntLiteral() {
    let input = """
      let number: Int?
      if conditionOne {
          number = 5
          doSomeStuffHere()
      } else {
          number = 10
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertMultiStatementIfStatementWithNilLiteral() {
    let input = """
      let number: Int?
      if conditionOne {
          number = nil
          doSomeStuffHere()
      } else {
          number = 10
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertMultiStatementIfStatementWithOtherProperty() {
    let input = """
      let number: Int?
      if conditionOne {
          number = someOtherProperty
          doSomeStuffHere()
      } else {
          number = 10
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertConditionalCastInSwift5_9() {
    // The following code doesn't compile in Swift 5.9 due to this issue:
    // https://github.com/apple/swift/issues/68764
    //
    //  let result = if condition {
    //    foo as? String
    //  } else {
    //    "bar"
    //  }
    //
    let input = """
      let result1: String?
      if condition {
          result1 = foo as? String
      } else {
          result1 = "bar"
      }

      let result2: String?
      switch condition {
      case true:
          result2 = foo as? String
      case false:
          result2 = "bar"
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func allowsAsWithinInnerScope() {
    let input = """
      let result: String?
      switch condition {
      case true:
          result = method(string: foo as? String)
      case false:
          result = "bar"
      }
      """

    let output = """
      let result: String? = switch condition {
      case true:
          method(string: foo as? String)
      case false:
          "bar"
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .conditionalAssignment, options: options,
      exclude: [.wrapMultilineConditionalAssignment])
  }

  // TODO: update branches parser to handle this case properly
  @Test func ignoreSwitchWithConditionalCompilation() {
    let input = """
      func foo() -> String? {
          let result: String?
          switch condition {
          #if os(macOS)
          case .foo:
              result = method(string: foo as? String)
          #endif
          case .bar:
              return nil
          }
          return result
      }
      """

    let options = FormatOptions(ifdefIndent: .noIndent, swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  // TODO: update branches parser to handle this scenario properly
  @Test func ignoreSwitchWithConditionalCompilation2() {
    let input = """
      func foo() -> String? {
          let result: String?
          switch condition {
          case .foo:
              result = method(string: foo as? String)
          #if os(macOS)
          case .bar:
              return nil
          #endif
          }
          return result
      }
      """

    let options = FormatOptions(ifdefIndent: .noIndent, swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func convertsConditionalCastInSwift5_10() {
    let input = """
      let result1: String?
      if condition {
          result1 = foo as? String
      } else {
          result1 = "bar"
      }

      let result2: String?
      switch condition {
      case true:
          result2 = foo as? String
      case false:
          result2 = "bar"
      }
      """

    let output = """
      let result1: String? = if condition {
          foo as? String
      } else {
          "bar"
      }

      let result2: String? = switch condition {
      case true:
          foo as? String
      case false:
          "bar"
      }
      """

    let options = FormatOptions(swiftVersion: "5.10")
    testFormatting(
      for: input, output, rule: .conditionalAssignment, options: options,
      exclude: [.wrapMultilineConditionalAssignment])
  }

  @Test func convertsSwitchWithDefaultCase() {
    let input = """
      let foo: Foo
      switch condition {
      case .foo:
          foo = Foo("foo")
      case .bar:
          foo = Foo("bar")
      default:
          foo = Foo("default")
      }
      """

    let output = """
      let foo: Foo = switch condition {
      case .foo:
          Foo("foo")
      case .bar:
          Foo("bar")
      default:
          Foo("default")
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .conditionalAssignment, options: options,
      exclude: [.wrapMultilineConditionalAssignment, .redundantType])
  }

  @Test func convertsSwitchWithUnknownDefaultCase() {
    let input = """
      let foo: Foo
      switch condition {
      case .foo:
          foo = Foo("foo")
      case .bar:
          foo = Foo("bar")
      @unknown default:
          foo = Foo("default")
      }
      """

    let output = """
      let foo: Foo = switch condition {
      case .foo:
          Foo("foo")
      case .bar:
          Foo("bar")
      @unknown default:
          Foo("default")
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .conditionalAssignment, options: options,
      exclude: [.wrapMultilineConditionalAssignment, .redundantType])
  }

  @Test func preservesSwitchWithReturnInDefaultCase() {
    let input = """
      let foo: Foo
      switch condition {
      case .foo:
          foo = Foo("foo")
      case .bar:
          foo = Foo("bar")
      default:
          return
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func preservesSwitchWithReturnInUnknownDefaultCase() {
    let input = """
      let foo: Foo
      switch condition {
      case .foo:
          foo = Foo("foo")
      case .bar:
          foo = Foo("bar")
      @unknown default:
          return
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func doesntConvertIfStatementWithForLoopInBranch() {
    let input = """
      var foo: Foo?
      if condition {
          foo = Foo("foo")
          for foo in foos {
              print(foo)
          }
      } else {
          foo = Foo("bar")
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .conditionalAssignment, options: options)
  }

  @Test func convertsIfStatementNotFollowingPropertyDefinition() {
    let input = """
      if condition {
          property = Foo("foo")
      } else {
          property = Foo("bar")
      }
      """

    let output = """
      property =
          if condition {
              Foo("foo")
          } else {
              Foo("bar")
          }
      """

    let options = FormatOptions(
      conditionalAssignmentOnlyAfterNewProperties: false, swiftVersion: "5.9")
    testFormatting(
      for: input, [output],
      rules: [.conditionalAssignment, .wrapMultilineConditionalAssignment, .indent],
      options: options)
  }

  @Test func preservesIfStatementNotFollowingPropertyDefinitionWithInvalidBranch() {
    let input = """
      if condition {
          property = Foo("foo")
      } else {
          property = Foo("bar")
          print("A second expression on this branch")
      }

      if condition {
          property = Foo("foo")
      } else {
          if otherCondition {
              property = Foo("foo")
          }
      }
      """

    let options = FormatOptions(
      conditionalAssignmentOnlyAfterNewProperties: false, swiftVersion: "5.9")
    testFormatting(
      for: input, rules: [.conditionalAssignment, .wrapMultilineConditionalAssignment, .indent],
      options: options)
  }

  @Test func preservesNonExhaustiveIfStatementNotFollowingPropertyDefinition() {
    let input = """
      if condition {
          property = Foo("foo")
      }

      if condition {
          property = Foo("foo")
      } else if otherCondition {
          property = Foo("foo")
      }
      """

    let options = FormatOptions(
      conditionalAssignmentOnlyAfterNewProperties: false, swiftVersion: "5.9")
    testFormatting(
      for: input, rules: [.conditionalAssignment, .wrapMultilineConditionalAssignment, .indent],
      options: options)
  }

  @Test func convertsSwitchStatementNotFollowingPropertyDefinition() {
    let input = """
      switch condition {
      case true:
          property = Foo("foo")
      case false:
          property = Foo("bar")
      }
      """

    let output = """
      property =
          switch condition {
          case true:
              Foo("foo")
          case false:
              Foo("bar")
          }
      """

    let options = FormatOptions(
      conditionalAssignmentOnlyAfterNewProperties: false, swiftVersion: "5.9")
    testFormatting(
      for: input, [output],
      rules: [.conditionalAssignment, .wrapMultilineConditionalAssignment, .indent],
      options: options)
  }

  @Test func convertsSwitchStatementWithComplexLValueNotFollowingPropertyDefinition() {
    let input = """
      switch condition {
      case true:
          property?.foo!.bar["baaz"] = Foo("foo")
      case false:
          property?.foo!.bar["baaz"] = Foo("bar")
      }
      """

    let output = """
      property?.foo!.bar["baaz"] =
          switch condition {
          case true:
              Foo("foo")
          case false:
              Foo("bar")
          }
      """

    let options = FormatOptions(
      conditionalAssignmentOnlyAfterNewProperties: false, swiftVersion: "5.9")
    testFormatting(
      for: input, [output],
      rules: [.conditionalAssignment, .wrapMultilineConditionalAssignment, .indent],
      options: options)
  }

  @Test func doesntMergePropertyWithUnrelatedCondition() {
    let input = """
      let differentProperty: Foo
      switch condition {
      case true:
          property = Foo("foo")
      case false:
          property = Foo("bar")
      }
      """

    let output = """
      let differentProperty: Foo
      property =
          switch condition {
          case true:
              Foo("foo")
          case false:
              Foo("bar")
          }
      """

    let options = FormatOptions(
      conditionalAssignmentOnlyAfterNewProperties: false, swiftVersion: "5.9")
    testFormatting(
      for: input, [output],
      rules: [.conditionalAssignment, .wrapMultilineConditionalAssignment, .indent],
      options: options)
  }

  @Test func convertsNestedIfSwitchStatementNotFollowingPropertyDefinition() {
    let input = """
      switch firstCondition {
      case true:
          if secondCondition {
              property = Foo("foo")
          } else {
              property = Foo("bar")
          }

      case false:
          if thirdCondition {
              property = Foo("baaz")
          } else {
              property = Foo("quux")
          }
      }
      """

    let output = """
      property =
          switch firstCondition {
          case true:
              if secondCondition {
                  Foo("foo")
              } else {
                  Foo("bar")
              }

          case false:
              if thirdCondition {
                  Foo("baaz")
              } else {
                  Foo("quux")
              }
          }
      """

    let options = FormatOptions(
      conditionalAssignmentOnlyAfterNewProperties: false, swiftVersion: "5.9")
    testFormatting(
      for: input, [output],
      rules: [.conditionalAssignment, .wrapMultilineConditionalAssignment, .indent],
      options: options)
  }

  @Test func preservesSwitchConditionWithIneligibleBranch() {
    let input = """
      switch firstCondition {
      case true:
          // Even though this condition is eligible to be converted,
          // we leave it as-is because it's nested in an ineligible condition.
          if secondCondition {
              property = Foo("foo")
          } else {
              property = Foo("bar")
          }

      case false:
          if thirdCondition {
              property = Foo("baaz")
          } else {
              property = Foo("quux")
              print("A second expression on this branch")
          }
      }
      """

    let options = FormatOptions(
      conditionalAssignmentOnlyAfterNewProperties: false, swiftVersion: "5.9")
    testFormatting(
      for: input, rules: [.conditionalAssignment, .wrapMultilineConditionalAssignment, .indent],
      options: options)
  }

  @Test func preservesIfConditionWithIneligibleBranch() {
    let input = """
      if firstCondition {
          // Even though this condition is eligible to be converted,
          // we leave it as-is because it's nested in an ineligible condition.
          if secondCondition {
              property = Foo("foo")
          } else {
              property = Foo("bar")
          }
      } else {
          if thirdCondition {
              property = Foo("baaz")
          } else {
              property = Foo("quux")
              print("A second expression on this branch")
          }
      }
      """

    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(
      for: input, rules: [.conditionalAssignment, .wrapMultilineConditionalAssignment, .indent],
      options: options)
  }
}
