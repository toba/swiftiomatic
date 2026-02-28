import Testing

@testable import Swiftiomatic

@Suite struct RedundantSelfTests {
  // explicitSelf = .remove

  @Test func simpleRemoveRedundantSelf() {
    let input = """
      func foo() { self.bar() }
      """
    let output = """
      func foo() { bar() }
      """
    testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func removeSelfInsideStringInterpolation() {
    let input = """
      class Foo {
          var bar: String?
          func baz() {
              print(\"\\(self.bar)\")
          }
      }
      """
    let output = """
      class Foo {
          var bar: String?
          func baz() {
              print(\"\\(bar)\")
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func noRemoveSelfForArgument() {
    let input = """
      func foo(bar: Int) { self.bar = bar }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func noRemoveSelfForLocalVariable() {
    let input = """
      func foo() { var bar = self.bar }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func removeSelfForLocalVariableOn5_4() {
    let input = """
      func foo() { var bar = self.bar }
      """
    let output = """
      func foo() { var bar = bar }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(
      for: input, output, rule: .redundantSelf,
      options: options, exclude: [.wrapFunctionBodies])
  }

  @Test func noRemoveSelfForCommaDelimitedLocalVariables() {
    let input = """
      func foo() { let foo = self.foo, bar = self.bar }
      """
    testFormatting(
      for: input, rule: .redundantSelf, exclude: [.singlePropertyPerLine, .wrapFunctionBodies])
  }

  @Test func removeSelfForCommaDelimitedLocalVariablesOn5_4() {
    let input = """
      func foo() { let foo = self.foo, bar = self.bar }
      """
    let output = """
      func foo() { let foo = self.foo, bar = bar }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(
      for: input, output, rule: .redundantSelf,
      options: options, exclude: [.singlePropertyPerLine, .wrapFunctionBodies])
  }

  @Test func noRemoveSelfForCommaDelimitedLocalVariables2() {
    let input = """
      func foo() {
          let foo: Foo, bar: Bar
          foo = self.foo
          bar = self.bar
      }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.singlePropertyPerLine])
  }

  @Test func noRemoveSelfForTupleAssignedVariables() {
    let input = """
      func foo() { let (bar, baz) = (self.bar, self.baz) }
      """
    testFormatting(
      for: input, rule: .redundantSelf, exclude: [.singlePropertyPerLine, .wrapFunctionBodies])
  }

  // TODO: make this work
  //    func testRemoveSelfForTupleAssignedVariablesOn5_4() {
  //        let input = "func foo() { let (bar, baz) = (self.bar, self.baz) }"
  //        let output = "func foo() { let (bar, baz) = (bar, baz) }"
  //        let options = FormatOptions(swiftVersion: "5.4")
  //        testFormatting(for: input, output, rule: .redundantSelf,
  //                       options: options)
  //    }

  @Test func noRemoveSelfForTupleAssignedVariablesFollowedByRegularVariable() {
    let input = """
      func foo() {
          let (foo, bar) = (self.foo, self.bar), baz = self.baz
      }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.singlePropertyPerLine])
  }

  @Test func noRemoveSelfForTupleAssignedVariablesFollowedByRegularLet() {
    let input = """
      func foo() {
          let (foo, bar) = (self.foo, self.bar)
          let baz = self.baz
      }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.singlePropertyPerLine])
  }

  @Test func noRemoveNonRedundantNestedFunctionSelf() {
    let input = """
      func foo() { func bar() { self.bar() } }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func noRemoveNonRedundantNestedFunctionSelf2() {
    let input = """
      func foo() {
          func bar() {}
          self.bar()
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveNonRedundantNestedFunctionSelf3() {
    let input = """
      func foo() { let bar = 5; func bar() { self.bar = bar } }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func noRemoveClosureSelf() {
    let input = """
      func foo() { bar { self.bar = 5 } }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func noRemoveSelfAfterOptionalReturn() {
    let input = """
      func foo() -> String? {
          var index = startIndex
          if !matching(self[index]) {
              break
          }
          index = self.index(after: index)
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveRequiredSelfInExtensions() {
    let input = """
      extension Foo {
          func foo() {
              var index = 5
              if true {
                  break
              }
              index = self.index(after: index)
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfBeforeInit() {
    let input = """
      convenience init() { self.init(5) }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func removeSelfInsideSwitch() {
    let input = """
      func foo() {
          switch self.bar {
          case .foo:
              self.baz()
          }
      }
      """
    let output = """
      func foo() {
          switch bar {
          case .foo:
              baz()
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func removeSelfInsideSwitchWhere() {
    let input = """
      func foo() {
          switch self.bar {
          case .foo where a == b:
              self.baz()
          }
      }
      """
    let output = """
      func foo() {
          switch bar {
          case .foo where a == b:
              baz()
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func removeSelfInsideSwitchWhereAs() {
    let input = """
      func foo() {
          switch self.bar {
          case .foo where a == b as C:
              self.baz()
          }
      }
      """
    let output = """
      func foo() {
          switch bar {
          case .foo where a == b as C:
              baz()
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func removeSelfInsideClassInit() {
    let input = """
      class Foo {
          var bar = 5
          init() { self.bar = 6 }
      }
      """
    let output = """
      class Foo {
          var bar = 5
          init() { bar = 6 }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func noRemoveSelfInClosureInsideIf() {
    let input = """
      if foo { bar { self.baz() } }
      """
    testFormatting(
      for: input, rule: .redundantSelf,
      exclude: [.wrapConditionalBodies])
  }

  @Test func noRemoveSelfForErrorInCatch() {
    let input = """
      do {} catch { self.error = error }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfForErrorInDoThrowsCatch() {
    let input = """
      do throws(Foo) {} catch { self.error = error }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfForNewValueInSet() {
    let input = """
      var foo: Int { set { self.newValue = newValue } get { return 0 } }
      """
    testFormatting(
      for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func noRemoveSelfForCustomNewValueInSet() {
    let input = """
      var foo: Int { set(n00b) { self.n00b = n00b } get { return 0 } }
      """
    testFormatting(
      for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func noRemoveSelfForNewValueInWillSet() {
    let input = """
      var foo: Int { willSet { self.newValue = newValue } }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
  }

  @Test func noRemoveSelfForCustomNewValueInWillSet() {
    let input = """
      var foo: Int { willSet(n00b) { self.n00b = n00b } }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
  }

  @Test func noRemoveSelfForOldValueInDidSet() {
    let input = """
      var foo: Int { didSet { self.oldValue = oldValue } }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
  }

  @Test func noRemoveSelfForCustomOldValueInDidSet() {
    let input = """
      var foo: Int { didSet(oldz) { self.oldz = oldz } }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
  }

  @Test func noRemoveSelfForIndexVarInFor() {
    let input = """
      for foo in bar { self.foo = foo }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapLoopBodies])
  }

  @Test func noRemoveSelfForKeyValueTupleInFor() {
    let input = """
      for (foo, bar) in baz { self.foo = foo; self.bar = bar }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapLoopBodies])
  }

  @Test func removeSelfFromComputedVar() {
    let input = """
      var foo: Int { return self.bar }
      """
    let output = """
      var foo: Int { return bar }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func removeSelfFromOptionalComputedVar() {
    let input = """
      var foo: Int? { return self.bar }
      """
    let output = """
      var foo: Int? { return bar }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func removeSelfFromNamespacedComputedVar() {
    let input = """
      var foo: Swift.String { return self.bar }
      """
    let output = """
      var foo: Swift.String { return bar }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func removeSelfFromGenericComputedVar() {
    let input = """
      var foo: Foo<Int> { return self.bar }
      """
    let output = """
      var foo: Foo<Int> { return bar }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func removeSelfFromComputedArrayVar() {
    let input = """
      var foo: [Int] { return self.bar }
      """
    let output = """
      var foo: [Int] { return bar }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func removeSelfFromVarSetter() {
    let input = """
      var foo: Int { didSet { self.bar() } }
      """
    let output = """
      var foo: Int { didSet { bar() } }
      """
    testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
  }

  @Test func noRemoveSelfFromVarClosure() {
    let input = """
      var foo = { self.bar }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfFromLazyVar() {
    let input = """
      lazy var foo = self.bar
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func removeSelfFromLazyVar() {
    let input = """
      lazy var foo = self.bar
      """
    let output = """
      lazy var foo = bar
      """
    let options = FormatOptions(swiftVersion: "4")
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func noRemoveSelfFromLazyVarImmediatelyAfterOtherVar() {
    let input = """
      var baz = bar
      lazy var foo = self.bar
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func removeSelfFromLazyVarImmediatelyAfterOtherVar() {
    let input = """
      var baz = bar
      lazy var foo = self.bar
      """
    let output = """
      var baz = bar
      lazy var foo = bar
      """
    let options = FormatOptions(swiftVersion: "4")
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func noRemoveSelfFromLazyVarClosure() {
    let input = """
      lazy var foo = { self.bar }()
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.redundantClosure])
  }

  @Test func noRemoveSelfFromLazyVarClosure2() {
    let input = """
      lazy var foo = { let bar = self.baz }()
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfFromLazyVarClosure3() {
    let input = """
      lazy var foo = { [unowned self] in let bar = self.baz }()
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func removeSelfFromVarInFuncWithUnusedArgument() {
    let input = """
      func foo(bar _: Int) { self.baz = 5 }
      """
    let output = """
      func foo(bar _: Int) { baz = 5 }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func removeSelfFromVarMatchingUnusedArgument() {
    let input = """
      func foo(bar _: Int) { self.bar = 5 }
      """
    let output = """
      func foo(bar _: Int) { bar = 5 }
      """
    testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func noRemoveSelfFromVarMatchingRenamedArgument() {
    let input = """
      func foo(bar baz: Int) { self.baz = baz }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func noRemoveSelfFromVarRedeclaredInSubscope() {
    let input = """
      func foo() {
          if quux {
              let bar = 5
          }
          let baz = self.bar
      }
      """
    let output = """
      func foo() {
          if quux {
              let bar = 5
          }
          let baz = bar
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func noRemoveSelfFromVarDeclaredLaterInScope() {
    let input = """
      func foo() {
          let bar = self.baz
          let baz = quux
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfFromVarDeclaredLaterInOuterScope() {
    let input = """
      func foo() {
          if quux {
              let bar = self.baz
          }
          let baz = 6
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInWhilePreceededByVarDeclaration() {
    let input = """
      var index = start
      while index < end {
          index = self.index(after: index)
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInLocalVarPrecededByLocalVarFollowedByIfComma() {
    let input = """
      func foo() {
          let bar = Bar()
          let baz = Baz()
          self.baz = baz
          if let bar = bar, bar > 0 {}
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInLocalVarPrecededByIfLetContainingClosure() {
    let input = """
      func foo() {
          if let bar = 5 { baz { _ in } }
          let quux = self.quux
      }
      """
    testFormatting(
      for: input, rule: .redundantSelf,
      exclude: [.wrapConditionalBodies])
  }

  @Test func noRemoveSelfForVarCreatedInGuardScope() {
    let input = """
      func foo() {
          guard let bar = 5 else {}
          let baz = self.bar
      }
      """
    testFormatting(
      for: input, rule: .redundantSelf,
      exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
  }

  @Test func removeSelfForVarCreatedInIfScope() {
    let input = """
      func foo() {
          if let bar = bar {}
          let baz = self.bar
      }
      """
    let output = """
      func foo() {
          if let bar = bar {}
          let baz = bar
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func noRemoveSelfForVarDeclaredInWhileCondition() {
    let input = """
      while let foo = bar { self.foo = foo }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapLoopBodies])
  }

  @Test func removeSelfForVarNotDeclaredInWhileCondition() {
    let input = """
      while let foo == bar { self.baz = 5 }
      """
    let output = """
      while let foo == bar { baz = 5 }
      """
    testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapLoopBodies])
  }

  @Test func noRemoveSelfForVarDeclaredInSwitchCase() {
    let input = """
      switch foo {
      case bar: let baz = self.baz
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfAfterGenericInit() {
    let input = """
      init(bar: Int) {
          self = Foo<Bar>()
          self.bar(bar)
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func removeSelfInClassFunction() {
    let input = """
      class Foo {
          class func foo() {
              func bar() { self.foo() }
          }
      }
      """
    let output = """
      class Foo {
          class func foo() {
              func bar() { foo() }
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func removeSelfInStaticFunction() {
    let input = """
      struct Foo {
          static func foo() {
              func bar() { self.foo() }
          }
      }
      """
    let output = """
      struct Foo {
          static func foo() {
              func bar() { foo() }
          }
      }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf, exclude: [.enumNamespaces, .wrapFunctionBodies])
  }

  @Test func removeSelfInClassFunctionWithModifiers() {
    let input = """
      class Foo {
          class private func foo() {
              func bar() { self.foo() }
          }
      }
      """
    let output = """
      class Foo {
          class private func foo() {
              func bar() { foo() }
          }
      }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf,
      exclude: [.modifierOrder, .wrapFunctionBodies])
  }

  @Test func noRemoveSelfInClassFunction() {
    let input = """
      class Foo {
          class func foo() {
              var foo: Int
              func bar() { self.foo() }
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func noRemoveSelfForVarDeclaredAfterRepeatWhile() {
    let input = """
      class Foo {
          let foo = 5
          func bar() {
              repeat {} while foo
              let foo = 6
              self.foo()
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfForVarInClosureAfterRepeatWhile() {
    let input = """
      class Foo {
          let foo = 5
          func bar() {
              repeat {} while foo
              ({ self.foo() })()
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInClosureAfterVar() {
    let input = """
      var foo: String
      bar { self.baz() }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInClosureAfterNamespacedVar() {
    let input = """
      var foo: Swift.String
      bar { self.baz() }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInClosureAfterOptionalVar() {
    let input = """
      var foo: String?
      bar { self.baz() }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInClosureAfterGenericVar() {
    let input = """
      var foo: Foo<Int>
      bar { self.baz() }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInClosureAfterArray() {
    let input = """
      var foo: [Int]
      bar { self.baz() }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInExpectFunction() {
    let input = """
      class FooTests: XCTestCase {
          let foo = 1
          func testFoo() {
              expect(self.foo) == 1
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noRemoveNestedSelfInExpectFunction() {
    let input = """
      func testFoo() {
          expect(Foo.validate(bar: self.bar)).to(equal(1))
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noRemoveNestedSelfInArrayInExpectFunction() {
    let input = """
      func testFoo() {
          expect(Foo.validate(bar: [self.bar])).to(equal(1))
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noRemoveNestedSelfInSubscriptInExpectFunction() {
    let input = """
      func testFoo() {
          expect(Foo.validations[self.bar]).to(equal(1))
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noRemoveSelfInOSLogFunction() {
    let input = """
      func testFoo() {
          os_log("error: \\(self.bar) is nil")
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noRemoveSelfInExcludedFunction() {
    let input = """
      class Foo {
          let foo = 1
          func testFoo() {
              log(self.foo)
          }
      }
      """
    let options = FormatOptions(selfRequired: ["log"])
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noRemoveSelfForExcludedFunction() {
    let input = """
      class Foo {
          let foo = 1
          func testFoo() {
              self.log(foo)
          }
      }
      """
    let options = FormatOptions(selfRequired: ["log"])
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noRemoveSelfInInterpolatedStringInExcludedFunction() {
    let input = """
      class Foo {
          let foo = 1
          func testFoo() {
              log("\\(self.foo)")
          }
      }
      """
    let options = FormatOptions(selfRequired: ["log"])
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noRemoveSelfInExcludedInitializer() {
    let input = """
      let vc = UIHostingController(rootView: InspectionView(inspection: self.inspection))
      """
    let options = FormatOptions(selfRequired: ["InspectionView"])
    testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.propertyTypes])
  }

  @Test func selfRemovedFromSwitchCaseWhere() {
    let input = """
      class Foo {
          var bar: Bar
          var bazziestBar: Bar? {
              switch x {
              case let foo where self.bar.baz:
                  return self.bar
              default:
                  return nil
              }
          }
      }
      """
    let output = """
      class Foo {
          var bar: Bar
          var bazziestBar: Bar? {
              switch x {
              case let foo where bar.baz:
                  return bar
              default:
                  return nil
              }
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func switchCaseLetVarRecognized() {
    let input = """
      switch foo {
      case .bar:
          baz = nil
      case let baz:
          self.baz = baz
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func switchCaseHoistedLetVarRecognized() {
    let input = """
      switch foo {
      case .bar:
          baz = nil
      case let .foo(baz):
          self.baz = baz
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func switchCaseWhereMemberNotTreatedAsVar() {
    let input = """
      class Foo {
          var bar: Bar
          var bazziestBar: Bar? {
              switch x {
              case let bar where self.bar.baz:
                  return self.bar
              default:
                  return nil
              }
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func selfNotRemovedInClosureAfterSwitch() {
    let input = """
      switch x {
      default:
          break
      }
      let foo = { y in
          switch y {
          default:
              self.bar()
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func selfNotRemovedInClosureInCaseWithWhereClause() {
    let input = """
      switch foo {
      case bar where baz:
          quux = { self.foo }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func selfRemovedInDidSet() {
    let input = """
      class Foo {
          var bar = false {
              didSet {
                  self.bar = !self.bar
              }
          }
      }
      """
    let output = """
      class Foo {
          var bar = false {
              didSet {
                  bar = !bar
              }
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func selfNotRemovedInGetter() {
    let input = """
      class Foo {
          var bar: Int {
              return self.bar
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func selfNotRemovedInIfdef() {
    let input = """
      func foo() {
          #if os(macOS)
              let bar = self.bar
          #endif
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func redundantSelfRemovedWhenFollowedBySwitchContainingIfdef() {
    let input = """
      struct Foo {
          func bar() {
              self.method(self.value)
              switch x {
              #if BAZ
                  case .baz:
                      break
              #endif
              default:
                  break
              }
          }
      }
      """
    let output = """
      struct Foo {
          func bar() {
              method(value)
              switch x {
              #if BAZ
                  case .baz:
                      break
              #endif
              default:
                  break
              }
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func redundantSelfRemovedInsideConditionalCase() {
    let input = """
      struct Foo {
          func bar() {
              let method2 = () -> Void
              switch x {
              #if BAZ
                  case .baz:
                      self.method1(self.value)
              #else
                  case .quux:
                      self.method2(self.value)
              #endif
              default:
                  break
              }
          }
      }
      """
    let output = """
      struct Foo {
          func bar() {
              let method2 = () -> Void
              switch x {
              #if BAZ
                  case .baz:
                      method1(value)
              #else
                  case .quux:
                      self.method2(value)
              #endif
              default:
                  break
              }
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func redundantSelfRemovedAfterConditionalLet() {
    let input = """
      class Foo {
          var bar: Int?
          var baz: Bool

          func foo() {
              if let bar = bar, self.baz {
                  // ...
              }
          }
      }
      """
    let output = """
      class Foo {
          var bar: Int?
          var baz: Bool

          func foo() {
              if let bar = bar, baz {
                  // ...
              }
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func nestedClosureInNotMistakenForForLoop() {
    let input = """
      func f() {
          let str = "hello"
          try! str.withCString(encodedAs: UTF8.self) { _ throws in
              try! str.withCString(encodedAs: UTF8.self) { _ throws in }
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func typedThrowingNestedClosureInNotMistakenForForLoop() {
    let input = """
      func f() {
          let str = "hello"
          try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in
              try! str.withCString(encodedAs: UTF8.self) { _ throws(Foo) in }
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func redundantSelfPreservesSelfInClosureWithExplicitStrongCaptureBefore5_3() {
    let input = """
      class Foo {
          let bar: Int

          func baaz() {
              closure { [self] in
                  print(self.bar)
              }
          }
      }
      """

    let options = FormatOptions(swiftVersion: "5.2")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func redundantSelfRemovesSelfInClosureWithExplicitStrongCapture() {
    let input = """
      class Foo {
          let foo: Int

          func baaz() {
              closure { [self, bar] baaz, quux in
                  print(self.foo)
              }
          }
      }
      """

    let output = """
      class Foo {
          let foo: Int

          func baaz() {
              closure { [self, bar] baaz, quux in
                  print(foo)
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.3")
    testFormatting(
      for: input, output, rule: .redundantSelf, options: options, exclude: [.unusedArguments])
  }

  @Test func redundantSelfRemovesSelfInClosureWithNestedExplicitStrongCapture() {
    let input = """
      class Foo {
          let bar: Int

          func baaz() {
              closure {
                  print(self.bar)
                  closure { [self] in
                      print(self.bar)
                  }
                  print(self.bar)
              }
          }
      }
      """

    let output = """
      class Foo {
          let bar: Int

          func baaz() {
              closure {
                  print(self.bar)
                  closure { [self] in
                      print(bar)
                  }
                  print(self.bar)
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.3")
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func redundantSelfKeepsSelfInNestedClosureWithNoExplicitStrongCapture() {
    let input = """
      class Foo {
          let bar: Int
          let baaz: Int?

          func baaz() {
              closure { [self] in
                  print(self.bar)
                  closure {
                      print(self.bar)
                      if let baaz = self.baaz {
                          print(baaz)
                      }
                  }
                  print(self.bar)
                  if let baaz = self.baaz {
                      print(baaz)
                  }
              }
          }
      }
      """

    let output = """
      class Foo {
          let bar: Int
          let baaz: Int?

          func baaz() {
              closure { [self] in
                  print(bar)
                  closure {
                      print(self.bar)
                      if let baaz = self.baaz {
                          print(baaz)
                      }
                  }
                  print(bar)
                  if let baaz = baaz {
                      print(baaz)
                  }
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.3")
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func redundantSelfRemovesSelfInClosureCapturingStruct() {
    let input = """
      struct Foo {
          let bar: Int

          func baaz() {
              closure {
                  print(self.bar)
              }
          }
      }
      """

    let output = """
      struct Foo {
          let bar: Int

          func baaz() {
              closure {
                  print(bar)
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.3")
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func redundantSelfRemovesSelfInClosureCapturingSelfWeakly() {
    let input = """
      class Foo {
          let bar: Int

          func baaz() {
              closure { [weak self] in
                  print(self?.bar)
                  guard let self else {
                      return
                  }
                  print(self.bar)
                  closure {
                      print(self.bar)
                  }
                  closure { [self] in
                      print(self.bar)
                  }
                  print(self.bar)
              }

              closure { [weak self] in
                  guard let self = self else {
                      return
                  }

                  print(self.bar)
              }

              closure { [weak self] in
                  guard let self = self ?? somethingElse else {
                      return
                  }

                  print(self.bar)
              }
          }
      }
      """

    let output = """
      class Foo {
          let bar: Int

          func baaz() {
              closure { [weak self] in
                  print(self?.bar)
                  guard let self else {
                      return
                  }
                  print(bar)
                  closure {
                      print(self.bar)
                  }
                  closure { [self] in
                      print(bar)
                  }
                  print(bar)
              }

              closure { [weak self] in
                  guard let self = self else {
                      return
                  }

                  print(bar)
              }

              closure { [weak self] in
                  guard let self = self ?? somethingElse else {
                      return
                  }

                  print(self.bar)
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.8")
    testFormatting(
      for: input, output, rule: .redundantSelf,
      options: options, exclude: [.redundantOptionalBinding, .blankLinesAfterGuardStatements])
  }

  @Test func weakSelfNotRemovedIfNotUnwrapped() {
    let input = """
      class A {
          weak var delegate: ADelegate?

          func testFunction() {
              DispatchQueue.main.async { [weak self] in
                  self.flatMap { $0.delegate?.aDidSomething($0) }
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.8")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func closureParameterListShadowingPropertyOnSelf() {
    let input = """
      class Foo {
          var bar = "bar"

          func method() {
              closure { [self] bar in
                  self.bar = bar
              }
          }
      }
      """

    let options = FormatOptions(swiftVersion: "5.3")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func closureParameterListShadowingPropertyOnSelfInStruct() {
    let input = """
      struct Foo {
          var bar = "bar"

          func method() {
              closure { bar in
                  self.bar = bar
              }
          }
      }
      """

    let options = FormatOptions(swiftVersion: "5.3")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func closureCaptureListShadowingPropertyOnSelf() {
    let input = """
      class Foo {
          var bar = "bar"
          var baaz = "baaz"

          func method() {
              closure { [self, bar, baaz = bar] in
                  self.bar = bar
                  self.baaz = baaz
              }
          }
      }
      """

    let options = FormatOptions(swiftVersion: "5.3")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func redundantSelfKeepsSelfInClosureCapturingSelfWeaklyBefore5_8() {
    let input = """
      class Foo {
          let bar: Int

          func baaz() {
              closure { [weak self] in
                  print(self?.bar)
                  guard let self else {
                      return
                  }
                  print(self.bar)
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.7")
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.blankLinesAfterGuardStatements]
    )
  }

  @Test func nonRedundantSelfNotRemovedAfterConditionalLet() {
    let input = """
      class Foo {
          var bar: Int?
          var baz: Bool

          func foo() {
              let baz = 5
              if let bar = bar, self.baz {
                  // ...
              }
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func redundantSelfDoesntGetStuckIfNoParensFound() {
    let input = """
      init<T>_ foo: T {}
      """
    testFormatting(
      for: input, rule: .redundantSelf,
      exclude: [.spaceAroundOperators])
  }

  @Test func noRemoveSelfInIfLetSelf() {
    let input = """
      func foo() {
          if let self = self as? Foo {
              self.bar()
          }
          self.bar()
      }
      """
    let output = """
      func foo() {
          if let self = self as? Foo {
              self.bar()
          }
          bar()
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInIfLetEscapedSelf() {
    let input = """
      func foo() {
          if let `self` = self as? Foo {
              self.bar()
          }
          self.bar()
      }
      """
    let output = """
      func foo() {
          if let `self` = self as? Foo {
              self.bar()
          }
          bar()
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func noRemoveSelfAfterGuardLetSelf() {
    let input = """
      func foo() {
          guard let self = self as? Foo else {
              return
          }
          self.bar()
      }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.blankLinesAfterGuardStatements])
  }

  @Test func noRemoveSelfInClosureInIfCondition() {
    let input = """
      class Foo {
          func foo() {
              if bar({ self.baz() }) {}
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInTrailingClosureInVarAssignment() {
    let input = """
      func broken() {
          var bad = abc {
              self.foo()
              self.bar
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func selfNotRemovedWhenPropertyIsKeyword() {
    let input = """
      class Foo {
          let `default` = 5
          func foo() {
              print(self.default)
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func selfNotRemovedWhenPropertyIsContextualKeyword() {
    let input = """
      class Foo {
          let `self` = 5
          func foo() {
              print(self.self)
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func selfRemovedForContextualKeywordThatRequiresNoEscaping() {
    let input = """
      class Foo {
          let get = 5
          func foo() {
              print(self.get)
          }
      }
      """
    let output = """
      class Foo {
          let get = 5
          func foo() {
              print(get)
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func removeSelfForMemberNamedLazy() {
    let input = """
      func foo() { self.lazy() }
      """
    let output = """
      func foo() { lazy() }
      """
    testFormatting(for: input, output, rule: .redundantSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func removeRedundantSelfInArrayLiteral() {
    let input = """
      class Foo {
          func foo() {
              print([self.bar.x, self.bar.y])
          }
      }
      """
    let output = """
      class Foo {
          func foo() {
              print([bar.x, bar.y])
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func removeRedundantSelfInArrayLiteralVar() {
    let input = """
      class Foo {
          func foo() {
              var bars = [self.bar.x, self.bar.y]
              print(bars)
          }
      }
      """
    let output = """
      class Foo {
          func foo() {
              var bars = [bar.x, bar.y]
              print(bars)
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func removeRedundantSelfInGuardLet() {
    let input = """
      class Foo {
          func foo() {
              guard let bar = self.baz else {
                  return
              }
          }
      }
      """
    let output = """
      class Foo {
          func foo() {
              guard let bar = baz else {
                  return
              }
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func selfNotRemovedInClosureInIf() {
    let input = """
      if let foo = bar(baz: { [weak self] in
          guard let self = self else { return }
          _ = self.myVar
      }) {}
      """
    testFormatting(
      for: input, rule: .redundantSelf,
      exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
  }

  @Test func structSelfRemovedInTrailingClosureInIfCase() {
    let input = """
      struct A {
          func doSomething() {
              B.method { mode in
                  if case .edit = mode {
                      self.doA()
                  } else {
                      self.doB()
                  }
              }
          }

          func doA() {}
          func doB() {}
      }
      """
    let output = """
      struct A {
          func doSomething() {
              B.method { mode in
                  if case .edit = mode {
                      doA()
                  } else {
                      doB()
                  }
              }
          }

          func doA() {}
          func doB() {}
      }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf,
      options: FormatOptions(swiftVersion: "5.8"))
  }

  @Test func selfNotRemovedInDynamicMemberLookup() {
    let input = """
      @dynamicMemberLookup
      struct Foo {
          subscript(dynamicMember foo: String) -> String {
              foo + "bar"
          }

          func bar() {
              if self.foo == "foobar" {
                  return
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func selfNotRemovedInDeclarationWithDynamicMemberLookup() {
    let input = """
      @dynamicMemberLookup
      struct Foo {
          subscript(dynamicMember foo: String) -> String {
              foo + "bar"
          }

          func bar() {
              let foo = self.foo
              print(foo)
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func selfNotRemovedInExtensionOfTypeWithDynamicMemberLookup() {
    let input = """
      @dynamicMemberLookup
      struct Foo {}

      extension Foo {
          subscript(dynamicMember foo: String) -> String {
              foo + "bar"
          }

          func bar() {
              if self.foo == "foobar" {
                  return
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func selfRemovedInNestedExtensionOfTypeWithDynamicMemberLookup() {
    let input = """
      @dynamicMemberLookup
      struct Foo {
          var foo: Int
          struct Foo {}
          extension Foo {
              func bar() {
                  if self.foo == "foobar" {
                      return
                  }
              }
          }
      }
      """
    let output = """
      @dynamicMemberLookup
      struct Foo {
          var foo: Int
          struct Foo {}
          extension Foo {
              func bar() {
                  if foo == "foobar" {
                      return
                  }
              }
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(
      for: input, output, rule: .redundantSelf,
      options: options)
  }

  @Test func noRemoveSelfAfterGuardCaseLetWithExplicitNamespace() {
    let input = """
      class Foo {
          var name: String?

          func bug(element: Something) {
              guard case let Something.a(name) = element
              else { return }
              self.name = name
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantSelf,
      exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
  }

  @Test func noRemoveSelfInAssignmentInsideIfAsStatement() {
    let input = """
      if let foo = foo as? Foo, let bar = baz {
          self.bar = bar
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func noRemoveSelfInAssignmentInsideIfLetWithPostfixOperator() {
    let input = """
      if let foo = baz?.foo, let bar = baz?.bar {
          self.foo = foo
          self.bar = bar
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func redundantSelfParsingBug() {
    let input = """
      private class Foo {
          mutating func bar() -> Statement? {
              let start = self
              guard case Token.identifier(let name)? = self.popFirst() else {
                  self = start
                  return nil
              }
              return Statement.declaration(name: name)
          }
      }
      """
    let output = """
      private class Foo {
          mutating func bar() -> Statement? {
              let start = self
              guard case Token.identifier(let name)? = popFirst() else {
                  self = start
                  return nil
              }
              return Statement.declaration(name: name)
          }
      }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf,
      exclude: [.hoistPatternLet, .blankLinesAfterGuardStatements])
  }

  @Test func redundantSelfParsingBug2() {
    let input = """
      extension Foo {
          private enum NonHashableEnum: RawRepresentable {
              case foo
              case bar

              var rawValue: RuntimeTypeTests.TestStruct {
                  return TestStruct(foo: 0)
              }

              init?(rawValue: RuntimeTypeTests.TestStruct) {
                  switch rawValue.foo {
                  case 0:
                      self = .foo
                  case 1:
                      self = .bar
                  default:
                      return nil
                  }
              }
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func redundantSelfWithStaticMethodAfterForLoop() {
    let input = """
      struct Foo {
          init() {
              for foo in self.bar {}
          }

          static func foo() {}
      }

      """
    let output = """
      struct Foo {
          init() {
              for foo in bar {}
          }

          static func foo() {}
      }

      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func redundantSelfWithStaticMethodAfterForWhereLoop() {
    let input = """
      struct Foo {
          init() {
              for foo in self.bar where !bar.isEmpty {}
          }

          static func foo() {}
      }

      """
    let output = """
      struct Foo {
          init() {
              for foo in bar where !bar.isEmpty {}
          }

          static func foo() {}
      }

      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func redundantSelfRuleDoesntErrorInForInTryLoop() {
    let input = """
      for foo in try bar() {}
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func redundantSelfInInitWithActorLabel() {
    let input = """
      class Foo {
          init(actor: Actor, bar: Bar) {
              self.actor = actor
              self.bar = bar
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func redundantSelfRuleFailsInGuardWithParenthesizedClosureAfterComma() {
    let input = """
      guard let foo = bar, foo.bar(baz: { $0 }) else {
          return nil
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func minSelfNotRemoved() {
    let input = """
      extension Array where Element: Comparable {
          func foo() -> Int {
              self.min()
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func minSelfNotRemovedOnSwift5_4() {
    let input = """
      extension Array where Element == Foo {
          func smallest() -> Foo? {
              let bar = self.min(by: { rect1, rect2 -> Bool in
                  rect1.perimeter < rect2.perimeter
              })
              return bar
          }
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty])
  }

  @Test func disableRedundantSelfDirective() {
    let input = """
      func smallest() -> Foo? {
          // swiftformat:disable:next redundantSelf
          let bar = self.foo { rect1, rect2 -> Bool in
              rect1.perimeter < rect2.perimeter
          }
          return bar
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty])
  }

  @Test func disableRedundantSelfDirective2() {
    let input = """
      func smallest() -> Foo? {
          let bar =
              // swiftformat:disable:next redundantSelf
              self.foo { rect1, rect2 -> Bool in
                  rect1.perimeter < rect2.perimeter
              }
          return bar
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty])
  }

  @Test(.disabled("Inline swiftformat:options not supported"))
  func selfInsertDirective() {
    let input = """
      func smallest() -> Foo? {
          // swiftformat:options:next --self insert
          let bar = self.foo { rect1, rect2 -> Bool in
              rect1.perimeter < rect2.perimeter
          }
          return bar
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.redundantProperty])
  }

  @Test func noRemoveVariableShadowedLaterInScopeInOlderSwiftVersions() {
    let input = """
      func foo() -> Bar? {
          guard let baz = self.bar else {
              return nil
          }

          let bar = Foo()
          return Bar(baz)
      }
      """
    let options = FormatOptions(swiftVersion: "4.2")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func stillRemoveVariableShadowedInSameDecalarationInOlderSwiftVersions() {
    let input = """
      func foo() -> Bar? {
          guard let bar = self.bar else {
              return nil
          }
          return bar
      }
      """
    let output = """
      func foo() -> Bar? {
          guard let bar = bar else {
              return nil
          }
          return bar
      }
      """
    let options = FormatOptions(swiftVersion: "5.0")
    testFormatting(
      for: input, output, rule: .redundantSelf, options: options,
      exclude: [.blankLinesAfterGuardStatements])
  }

  @Test func shadowedSelfRemovedInGuardLet() {
    let input = """
      func foo() {
          guard let optional = self.optional else {
              return
          }
          print(optional)
      }
      """
    let output = """
      func foo() {
          guard let optional = optional else {
              return
          }
          print(optional)
      }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf, exclude: [.blankLinesAfterGuardStatements])
  }

  @Test func shadowedStringValueNotRemovedInInit() {
    let input = """
      init() {
          let value = "something"
          self.value = value
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func shadowedIntValueNotRemovedInInit() {
    let input = """
      init() {
          let value = 5
          self.value = value
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func shadowedPropertyValueNotRemovedInInit() {
    let input = """
      init() {
          let value = foo
          self.value = value
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func shadowedFuncCallValueNotRemovedInInit() {
    let input = """
      init() {
          let value = foo()
          self.value = value
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func shadowedFuncParamRemovedInInit() {
    let input = """
      init() {
          let value = foo(self.value)
      }
      """
    let output = """
      init() {
          let value = foo(value)
      }
      """
    let options = FormatOptions(swiftVersion: "5.4")
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func noRemoveSelfInMacro() {
    let input = """
      struct MyStruct {
          private var __myVar: String
          var myVar: String {
              @storageRestrictions(initializes: self.__myVar)
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  // explicitSelf = .insert

  @Test func insertSelf() {
    let input = """
      class Foo {
          let foo: Int
          init() { foo = 5 }
      }
      """
    let output = """
      class Foo {
          let foo: Int
          init() { self.foo = 5 }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, output, rule: .redundantSelf, options: options,
      exclude: [.wrapFunctionBodies])
  }

  @Test func insertSelfInActor() {
    let input = """
      actor Foo {
          let foo: Int
          init() { foo = 5 }
      }
      """
    let output = """
      actor Foo {
          let foo: Int
          init() { self.foo = 5 }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, output, rule: .redundantSelf, options: options,
      exclude: [.wrapFunctionBodies])
  }

  @Test func insertSelfAfterReturn() {
    let input = """
      class Foo {
          let foo: Int
          func bar() -> Int { return foo }
      }
      """
    let output = """
      class Foo {
          let foo: Int
          func bar() -> Int { return self.foo }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, output, rule: .redundantSelf, options: options, exclude: [.wrapFunctionBodies])
  }

  @Test func insertSelfInsideStringInterpolation() {
    let input = """
      class Foo {
          var bar: String?
          func baz() {
              print(\"\\(bar)\")
          }
      }
      """
    let output = """
      class Foo {
          var bar: String?
          func baz() {
              print(\"\\(self.bar)\")
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func noInterpretGenericTypesAsMembers() {
    let input = """
      class Foo {
          let foo: Bar<Int, Int>
          init() { self.foo = Int(5) }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options,
      exclude: [.wrapFunctionBodies])
  }

  @Test func insertSelfForStaticMemberInClassFunction() {
    let input = """
      class Foo {
          static var foo: Int
          class func bar() { foo = 5 }
      }
      """
    let output = """
      class Foo {
          static var foo: Int
          class func bar() { self.foo = 5 }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, output, rule: .redundantSelf, options: options, exclude: [.wrapFunctionBodies])
  }

  @Test func noInsertSelfForInstanceMemberInClassFunction() {
    let input = """
      class Foo {
          var foo: Int
          class func bar() { foo = 5 }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.wrapFunctionBodies])
  }

  @Test func noInsertSelfForStaticMemberInInstanceFunction() {
    let input = """
      class Foo {
          static var foo: Int
          func bar() { foo = 5 }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.wrapFunctionBodies])
  }

  @Test func noInsertSelfForShadowedClassMemberInClassFunction() {
    let input = """
      class Foo {
          class func foo() {
              var foo: Int
              func bar() { foo = 5 }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.wrapFunctionBodies])
  }

  @Test func noInsertSelfInForLoopTuple() {
    let input = """
      class Foo {
          var bar: Int
          func foo() { for (bar, baz) in quux {} }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.wrapFunctionBodies])
  }

  @Test func noInsertSelfForTupleTypeMembers() {
    let input = """
      class Foo {
          var foo: (Int, UIColor) {
              let bar = UIColor.red
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfForArrayElements() {
    let input = """
      class Foo {
          var foo = [1, 2, nil]
          func bar() { baz(nil) }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options,
      exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func noInsertSelfForNestedVarReference() {
    let input = """
      class Foo {
          func bar() {
              var bar = 5
              repeat { bar = 6 } while true
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.wrapLoopBodies])
  }

  @Test func noInsertSelfInSwitchCaseLet() {
    let input = """
      class Foo {
          var foo: Bar? {
              switch bar {
              case let .baz(foo, _):
                  return nil
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfInFuncAfterImportedClass() {
    let input = """
      import class Foo.Bar
      func foo() {
          var bar = 5
          if true {
              bar = 6
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options,
      exclude: [.blankLineAfterImports])
  }

  @Test func noInsertSelfForSubscriptGetSet() {
    let input = """
      class Foo {
          func get() {}
          func set() {}
          subscript(key: String) -> String {
              get { return get(key) }
              set { set(key, newValue) }
          }
      }
      """
    let output = """
      class Foo {
          func get() {}
          func set() {}
          subscript(key: String) -> String {
              get { return self.get(key) }
              set { self.set(key, newValue) }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfInIfCaseLet() {
    let input = """
      enum Foo {
          case bar(Int)
          var value: Int? {
              if case let .bar(value) = self { return value }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options,
      exclude: [.wrapConditionalBodies])
  }

  @Test func noInsertSelfForPatternLet() {
    let input = """
      class Foo {
          func foo() {}
          func bar() {
              switch x {
              case .bar(let foo, var bar): print(foo + bar)
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfForPatternLet2() {
    let input = """
      class Foo {
          func foo() {}
          func bar() {
              switch x {
              case let .foo(baz): print(baz)
              case .bar(let foo, var bar): print(foo + bar)
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfForTypeOf() {
    let input = """
      class Foo {
          var type: String?
          func bar() {
              print(\"\\(type(of: self))\")
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfForConditionalLocal() {
    let input = """
      class Foo {
          func foo() {
              #if os(watchOS)
                  var foo: Int
              #else
                  var foo: Float
              #endif
              print(foo)
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func insertSelfInExtension() {
    let input = """
      struct Foo {
          var bar = 5
      }

      extension Foo {
          func baz() {
              bar = 6
          }
      }
      """
    let output = """
      struct Foo {
          var bar = 5
      }

      extension Foo {
          func baz() {
              self.bar = 6
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func globalAfterTypeNotTreatedAsMember() {
    let input = """
      struct Foo {
          var foo = 1
      }

      var bar = 5

      extension Foo {
          func baz() {
              bar = 6
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func forWhereVarNotTreatedAsMember() {
    let input = """
      class Foo {
          var bar: Bar
          var bazziestBar: Bar? {
              for bar in self where bar.baz {
                  return bar
              }
              return nil
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func switchCaseWhereVarNotTreatedAsMember() {
    let input = """
      class Foo {
          var bar: Bar
          var bazziestBar: Bar? {
              switch x {
              case let bar where bar.baz:
                  return bar
              default:
                  return nil
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func switchCaseVarDoesntLeak() {
    let input = """
      class Foo {
          var bar: Bar
          var bazziestBar: Bar? {
              switch x {
              case let bar:
                  return bar
              default:
                  return bar
              }
          }
      }
      """
    let output = """
      class Foo {
          var bar: Bar
          var bazziestBar: Bar? {
              switch x {
              case let bar:
                  return bar
              default:
                  return self.bar
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func selfInsertedInSwitchCaseLet() {
    let input = """
      class Foo {
          var bar: Bar
          var bazziestBar: Bar? {
              switch x {
              case let foo:
                  return bar
              default:
                  return bar
              }
          }
      }
      """
    let output = """
      class Foo {
          var bar: Bar
          var bazziestBar: Bar? {
              switch x {
              case let foo:
                  return self.bar
              default:
                  return self.bar
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func selfInsertedInSwitchCaseWhere() {
    let input = """
      class Foo {
          var bar: Bar
          var bazziestBar: Bar? {
              switch x {
              case let foo where bar.baz:
                  return bar
              default:
                  return bar
              }
          }
      }
      """
    let output = """
      class Foo {
          var bar: Bar
          var bazziestBar: Bar? {
              switch x {
              case let foo where self.bar.baz:
                  return self.bar
              default:
                  return self.bar
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func selfInsertedInDidSet() {
    let input = """
      class Foo {
          var bar = false {
              didSet {
                  bar = !bar
              }
          }
      }
      """
    let output = """
      class Foo {
          var bar = false {
              didSet {
                  self.bar = !self.bar
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func selfInsertedAfterLet() {
    let input = """
      struct Foo {
          let foo = "foo"
          func bar() {
              let x = foo
              baz(x)
          }

          func baz(_: String) {}
      }
      """
    let output = """
      struct Foo {
          let foo = "foo"
          func bar() {
              let x = self.foo
              self.baz(x)
          }

          func baz(_: String) {}
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func selfNotInsertedInParameterNames() {
    let input = """
      class Foo {
          let a: String

          func bar() {
              foo(a: a)
          }
      }
      """
    let output = """
      class Foo {
          let a: String

          func bar() {
              foo(a: self.a)
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func selfNotInsertedInCaseLet() {
    let input = """
      class Foo {
          let a: String?
          let b: String

          func bar() {
              if case let .some(a) = self.a, case var .some(b) = self.b {}
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func selfNotInsertedInCaseLet2() {
    let input = """
      class Foo {
          let a: String?
          let b: String

          func baz() {
              if case let .foos(a, b) = foo, case let .bars(a, b) = bar {}
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func selfInsertedInTupleAssignment() {
    let input = """
      class Foo {
          let a: String?
          let b: String

          func bar() {
              (a, b) = ("foo", "bar")
          }
      }
      """
    let output = """
      class Foo {
          let a: String?
          let b: String

          func bar() {
              (self.a, self.b) = ("foo", "bar")
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func selfNotInsertedInTupleAssignment() {
    let input = """
      class Foo {
          let a: String?
          let b: String

          func bar() {
              let (a, b) = (self.a, self.b)
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.singlePropertyPerLine])
  }

  @Test func insertSelfForMemberNamedLazy() {
    let input = """
      class Foo {
          var lazy = "foo"
          func foo() {
              print(lazy)
          }
      }
      """
    let output = """
      class Foo {
          var lazy = "foo"
          func foo() {
              print(self.lazy)
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfForVarDefinedInIfCaseLet() {
    let input = """
      struct A {
          var localVar = ""

          var B: String {
              if case let .c(localVar) = self.d, localVar == .e {
                  print(localVar)
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfForVarDefinedInUnhoistedIfCaseLet() {
    let input = """
      struct A {
          var localVar = ""

          var B: String {
              if case .c(let localVar) = self.d, localVar == .e {
                  print(localVar)
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options,
      exclude: [.hoistPatternLet])
  }

  @Test func noInsertSelfForVarDefinedInFor() {
    let input = """
      struct A {
          var localVar = ""

          var B: String {
              for localVar in 0 ..< 6 where localVar < 5 {
                  print(localVar)
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfForVarDefinedInWhileLet() {
    let input = """
      struct A {
          var localVar = ""

          var B: String {
              while let localVar = self.localVar, localVar < 5 {
                  print(localVar)
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfInCaptureList() {
    let input = """
      class Thing {
          var a: String? { nil }

          func foo() {
              let b = ""
              { [weak a = b] _ in }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options,
      exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func noInsertSelfInCaptureList2() {
    let input = """
      class Thing {
          var a: String? { nil }

          func foo() {
              { [weak a] _ in }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options,
      exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func noInsertSelfInCaptureList3() {
    let input = """
      class A {
          var thing: B? { fatalError() }

          func foo() {
              let thing2 = B()
              let _: (Bool) -> Void = { [weak thing = thing2] _ in
                  thing?.bar()
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(
      for: input, rule: .redundantSelf, options: options,
      exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
  }

  @Test func bodilessFunctionDoesntBreakParser() {
    let input = """
      @_silgen_name("foo")
      func foo(_: CFString, _: CFTypeRef) -> Int?

      enum Bar {
          static func baz() {
              fatalError()
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func functionWithNoBodyFollowedByStaticFunction() {
    let input = """
      struct Foo {
          let foo: String

          @_silgen_name("__MARKER_doIt")
          func doIt(_ x: String) -> Int?

          static func bar() {
              print(self.foo)
          }
      }
      """

    let output = """
      struct Foo {
          let foo: String

          @_silgen_name("__MARKER_doIt")
          func doIt(_ x: String) -> Int?

          static func bar() {
              print(foo)
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func noInsertSelfBeforeSet() {
    let input = """
      class Foo {
          var foo: Bool

          var bar: Bool {
              get { self.foo }
              set { self.foo = newValue }
          }

          required init() {}

          func set() {}
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfInMacro() {
    let input = """
      struct MyStruct {
          private var __myVar: String
          var myVar: String {
              @storageRestrictions(initializes: __myVar)
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfBeforeBinding() {
    let input = """
      struct MyView: View {
          @Environment(ViewModel.self) var viewModel

          var body: some View {
              @Bindable var viewModel = self.viewModel
              ZStack {
                  MySubview(
                      navigationPath: $viewModel.navigationPath
                  )
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert, swiftVersion: "5.10")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfInKeyPath() {
    let input = """
      class UserScreenPresenter: ScreenPresenter {
          func onAppear() {
              self.sessionInteractor.stage.compactMap(\\.?.session).latestValues(on: .main)
          }

          private var session: Session?
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  // explicitSelf = .initOnly

  @Test func preserveSelfInsideClassInit() {
    let input = """
      class Foo {
          var bar = 5
          init() {
              self.bar = 6
          }
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func removeSelfIfNotInsideClassInit() {
    let input = """
      class Foo {
          var bar = 5
          func baz() {
              self.bar = 6
          }
      }
      """
    let output = """
      class Foo {
          var bar = 5
          func baz() {
              bar = 6
          }
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func insertSelfInsideClassInit() {
    let input = """
      class Foo {
          var bar = 5
          init() {
              bar = 6
          }
      }
      """
    let output = """
      class Foo {
          var bar = 5
          init() {
              self.bar = 6
          }
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func noInsertSelfInsideClassInitIfNotLvalue() {
    let input = """
      class Foo {
          var bar = 5
          let baz = 6
          init() {
              bar = baz
          }
      }
      """
    let output = """
      class Foo {
          var bar = 5
          let baz = 6
          init() {
              self.bar = baz
          }
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func removeSelfInsideClassInitIfNotLvalue() {
    let input = """
      class Foo {
          var bar = 5
          let baz = 6
          init() {
              self.bar = self.baz
          }
      }
      """
    let output = """
      class Foo {
          var bar = 5
          let baz = 6
          init() {
              self.bar = baz
          }
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func selfDotTypeInsideClassInitEdgeCase() {
    let input = """
      class Foo {
          let type: Int

          init() {
              self.type = 5
          }

          func baz() {
              switch type {}
          }
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func selfInsertedInTupleInInit() {
    let input = """
      class Foo {
          let a: String?
          let b: String

          init() {
              (a, b) = ("foo", "bar")
          }
      }
      """
    let output = """
      class Foo {
          let a: String?
          let b: String

          init() {
              (self.a, self.b) = ("foo", "bar")
          }
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func selfInsertedAfterLetInInit() {
    let input = """
      class Foo {
          var foo: String
          init(bar: Bar) {
              let baz = bar.quux
              foo = baz
          }
      }
      """
    let output = """
      class Foo {
          var foo: String
          init(bar: Bar) {
              let baz = bar.quux
              self.foo = baz
          }
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, output, rule: .redundantSelf, options: options)
  }

  @Test func redundantSelfRuleDoesntErrorForStaticFuncInProtocolWithWhere() {
    let input = """
      protocol Foo where Self: Bar {
          static func baz() -> Self
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func redundantSelfRuleDoesntErrorForStaticFuncInStructWithWhere() {
    let input = """
      struct Foo<T> where T: Bar {
          static func baz() -> Foo {}
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.simplifyGenericConstraints])
  }

  @Test func redundantSelfRuleDoesntErrorForClassFuncInClassWithWhere() {
    let input = """
      class Foo<T> where T: Bar {
          class func baz() -> Foo {}
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(
      for: input, rule: .redundantSelf, options: options, exclude: [.simplifyGenericConstraints])
  }

  @Test func redundantSelfRuleFailsInInitOnlyMode() {
    let input = """
      class Foo {
          func foo() -> Foo? {
              guard let bar = { nil }() else {
                  return nil
              }
          }

          static func baz() -> String? {}
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.redundantClosure])
  }

  @Test func redundantSelfRuleFailsInInitOnlyMode2() {
    let input = """
      struct Mesh {
          var storage: Storage
          init(vertices: [Vertex]) {
              let isConvex = pointsAreConvex(vertices)
              storage = Storage(vertices: vertices)
          }
      }
      """
    let output = """
      struct Mesh {
          var storage: Storage
          init(vertices: [Vertex]) {
              let isConvex = pointsAreConvex(vertices)
              self.storage = Storage(vertices: vertices)
          }
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(
      for: input, output, rule: .redundantSelf,
      options: options)
  }

  @Test func selfNotRemovedInInitForSwift5_4() {
    let input = """
      init() {
          let foo = 1234
          self.bar = foo
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly, swiftVersion: "5.4")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func propertyInitNotInterpretedAsTypeInit() {
    let input = """
      struct MyStruct {
          private var __myVar: String
          var myVar: String {
              @storageRestrictions(initializes: __myVar)
              init(initialValue) {
                  __myVar = initialValue
              }
              set {
                  __myVar = newValue
              }
              get {
                  __myVar
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func propertyInitNotInterpretedAsTypeInit2() {
    let input = """
      struct MyStruct {
          private var __myVar: String
          var myVar: String {
              @storageRestrictions(initializes: __myVar)
              init {
                  __myVar = newValue
              }
              set {
                  __myVar = newValue
              }
              get {
                  __myVar
              }
          }
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  // parsing bugs

  @Test func selfRemovalParsingBug() {
    let input = """
      extension Dictionary where Key == String {
          func requiredValue<T>(for keyPath: String) throws -> T {
              return keyPath as! T
          }

          func optionalValue<T>(for keyPath: String) throws -> T? {
              guard let anyValue = self[keyPath] else {
                  return nil
              }
              guard let value = anyValue as? T else {
                  return nil
              }
              return value
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.blankLinesAfterGuardStatements])
  }

  @Test func selfRemovalParsingBug2() {
    let input = """
      if let test = value()["hi"] {
          print("hi")
      }
      """
    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func selfRemovalParsingBug3() {
    let input = """
      func handleGenericError(_ error: Error) {
          if let requestableError = error as? RequestableError,
             case let .underlying(error as NSError) = requestableError,
             error.code == NSURLErrorNotConnectedToInternet
          {}
      }
      """
    let options = FormatOptions(explicitSelf: .initOnly)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func selfRemovalParsingBug4() {
    let input = """
      struct Foo {
          func bar() {
              for flag in [] where [].filter({ true }) {}
          }

          static func baz() {}
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func selfRemovalParsingBug5() {
    let input = """
      extension Foo {
          func method(foo: Bar) {
              self.foo = foo

              switch foo {
              case let .foo(bar):
                  closure {
                      Foo.draw()
                  }
              }
          }

          private static func draw() {}
      }
      """

    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func selfRemovalParsingBug6() {
    let input = """
      something.do(onSuccess: { result in
          if case .success((let d, _)) = result {
              self.relay.onNext(d)
          }
      })
      """
    testFormatting(
      for: input, rule: .redundantSelf,
      exclude: [.hoistPatternLet])
  }

  @Test func selfRemovalParsingBug7() {
    let input = """
      extension Dictionary where Key == String {
          func requiredValue<T>(for keyPath: String) throws(Foo) -> T {
              return keyPath as! T
          }

          func optionalValue<T>(for keyPath: String) throws(Foo) -> T? {
              guard let anyValue = self[keyPath] else {
                  return nil
              }
              guard let value = anyValue as? T else {
                  return nil
              }
              return value
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.blankLinesAfterGuardStatements])
  }

  @Test func selfNotRemovedInCaseIfElse() {
    let input = """
      class Foo {
          let bar = true
          let someOptionalBar: String? = "bar"

          func test() {
              guard let bar: String = someOptionalBar else {
                  return
              }

              let result = Result<Any, Error>.success(bar)
              switch result {
              case let .success(value):
                  if self.bar {
                      if self.bar {
                          print(self.bar)
                      }
                  } else {
                      if self.bar {
                          print(self.bar)
                      }
                  }

              case .failure:
                  if self.bar {
                      print(self.bar)
                  }
              }
          }
      }
      """

    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func selfCallAfterIfStatementInSwitchStatement() {
    let input = """
      closure { [weak self] in
          guard let self else {
              return
          }

          switch result {
          case let .success(value):
              if value != nil {
                  if value != nil {
                      self.method()
                  }
              }
              self.method()

          case .failure:
              break
          }
      }
      """

    let options = FormatOptions(swiftVersion: "5.3")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func selfNotRemovedFollowingNestedSwitchStatements() {
    let input = """
      class Foo {
          let bar = true
          let someOptionalBar: String? = "bar"

          func test() {
              guard let bar: String = someOptionalBar else {
                  return
              }

              let result = Result<Any, Error>.success(bar)
              switch result {
              case let .success(value):
                  switch result {
                  case .success:
                      print("success")
                  case .value:
                      print("value")
                  }

              case .failure:
                  guard self.bar else {
                      print(self.bar)
                      return
                  }

                  print(self.bar)
              }
          }
      }
      """

    testFormatting(for: input, rule: .redundantSelf)
  }

  @Test func redundantSelfWithStaticAsyncSendableClosureFunction() {
    let input = """
      class Foo: Bar {
          static func bar(
              _ closure: @escaping @Sendable () async -> Foo
          ) -> @Sendable () async -> Foo {
              self.foo = closure
              return closure
          }

          static func bar() {}
      }
      """
    let output = """
      class Foo: Bar {
          static func bar(
              _ closure: @escaping @Sendable () async -> Foo
          ) -> @Sendable () async -> Foo {
              foo = closure
              return closure
          }

          static func bar() {}
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  // enable/disable

  @Test func disableRemoveSelf() {
    let input = """
      class Foo {
          var bar: Int
          func baz() {
              // swiftformat:disable redundantSelf
              self.bar = 1
              // swiftformat:enable redundantSelf
              self.bar = 2
          }
      }
      """
    let output = """
      class Foo {
          var bar: Int
          func baz() {
              // swiftformat:disable redundantSelf
              self.bar = 1
              // swiftformat:enable redundantSelf
              bar = 2
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func disableRemoveSelfCaseInsensitive() {
    let input = """
      class Foo {
          var bar: Int
          func baz() {
              // swiftformat:disable redundantself
              self.bar = 1
              // swiftformat:enable RedundantSelf
              self.bar = 2
          }
      }
      """
    let output = """
      class Foo {
          var bar: Int
          func baz() {
              // swiftformat:disable redundantself
              self.bar = 1
              // swiftformat:enable RedundantSelf
              bar = 2
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func disableNextRemoveSelf() {
    let input = """
      class Foo {
          var bar: Int
          func baz() {
              // swiftformat:disable:next redundantSelf
              self.bar = 1
              self.bar = 2
          }
      }
      """
    let output = """
      class Foo {
          var bar: Int
          func baz() {
              // swiftformat:disable:next redundantSelf
              self.bar = 1
              bar = 2
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func multilineDisableRemoveSelf() {
    let input = """
      class Foo {
          var bar: Int
          func baz() {
              /* swiftformat:disable redundantSelf */ self.bar = 1 /* swiftformat:enable all */
              self.bar = 2
          }
      }
      """
    let output = """
      class Foo {
          var bar: Int
          func baz() {
              /* swiftformat:disable redundantSelf */ self.bar = 1 /* swiftformat:enable all */
              bar = 2
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func multilineDisableNextRemoveSelf() {
    let input = """
      class Foo {
          var bar: Int
          func baz() {
              /* swiftformat:disable:next redundantSelf */
              self.bar = 1
              self.bar = 2
          }
      }
      """
    let output = """
      class Foo {
          var bar: Int
          func baz() {
              /* swiftformat:disable:next redundantSelf */
              self.bar = 1
              bar = 2
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func removesSelfInNestedFunctionInStrongSelfClosure() {
    let input = """
      class Test {
          func doWork(_ escaping: @escaping () -> Void) {
              escaping()
          }

          func test() {
              doWork { [self] in
                  doWork {
                      // Not allowed. Warning in Swift 5 and error in Swift 6.
                      self.test()
                  }

                  func innerFunc() {
                      // Allowed: https://forums.swift.org/t/why-does-se-0269-have-different-rules-for-inner-closures-vs-inner-functions/64334/2
                      self.test()
                  }

                  innerFunc()
              }
          }
      }
      """

    let output = """
      class Test {
          func doWork(_ escaping: @escaping () -> Void) {
              escaping()
          }

          func test() {
              doWork { [self] in
                  doWork {
                      // Not allowed. Warning in Swift 5 and error in Swift 6.
                      self.test()
                  }

                  func innerFunc() {
                      // Allowed: https://forums.swift.org/t/why-does-se-0269-have-different-rules-for-inner-closures-vs-inner-functions/64334/2
                      test()
                  }

                  innerFunc()
              }
          }
      }
      """
    testFormatting(
      for: input, output, rule: .redundantSelf, options: FormatOptions(swiftVersion: "5.8"))
  }

  @Test func preservesSelfInNestedFunctionInWeakSelfClosure() {
    let input = """
      class Test {
          func doWork(_ escaping: @escaping () -> Void) {
              escaping()
          }

          func test() {
              doWork { [weak self] in
                  func innerFunc() {
                      self?.test()
                  }

                  guard let self else {
                      return
                  }

                  self.test()

                  func innerFunc() {
                      self.test()
                  }

                  self.test()
              }
          }
      }
      """

    let output = """
      class Test {
          func doWork(_ escaping: @escaping () -> Void) {
              escaping()
          }

          func test() {
              doWork { [weak self] in
                  func innerFunc() {
                      self?.test()
                  }

                  guard let self else {
                      return
                  }

                  test()

                  func innerFunc() {
                      self.test()
                  }

                  test()
              }
          }
      }
      """

    testFormatting(
      for: input, output, rule: .redundantSelf,
      options: FormatOptions(swiftVersion: "5.8"))
  }

  @Test func redundantSelfAfterScopedImport() {
    let input = """
      import struct Foundation.Date

      struct Foo {
          let foo: String
          init(bar: String) {
              self.foo = bar
          }
      }
      """
    let output = """
      import struct Foundation.Date

      struct Foo {
          let foo: String
          init(bar: String) {
              foo = bar
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }

  @Test func redundantSelfNotConfusedByParameterPack() {
    let input = """
      func pairUp<each T, each U>(firstPeople: repeat each T, secondPeople: repeat each U) -> (repeat (first: each T, second: each U)) {
          (repeat (each firstPeople, each secondPeople))
      }
      """
    let options = FormatOptions(swiftVersion: "5.9")
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func redundantSelfNotConfusedByStaticAfterSwitch() {
    let input = """
      public final class MyClass {
          private static func privateStaticFunction1() -> Bool {
              switch Result(catching: { try someThrowingFunction() }) {
              case .success:
                  return true
              case .failure:
                  return false
              }
          }

          private static func privateStaticFunction2() -> Bool {
              return false
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options, exclude: [.enumNamespaces])
  }

  @Test func redundantSelfNotConfusedByMainActor() {
    let input = """
      class Test {
          private var p: Int

          func f() {
              self.f2(
                  closure: { @MainActor [weak self] p in
                      print(p)
                  }
              )
          }
      }
      """
    let options = FormatOptions(explicitSelf: .insert)
    testFormatting(for: input, rule: .redundantSelf, options: options)
  }

  @Test func noMistakeProtocolClassModifierForClassFunction() throws {
    let input = """
      protocol Foo: class {}
      func bar() {}
      """
    _ = try format(input, rules: [.redundantSelf])
    _ = try format(input, rules: FormatRules.all)
  }

  @Test func redundantSelfParsingBug3() throws {
    let input = """
      final class ViewController {
        private func bottomBarModels() -> [BarModeling] {
          if let url = URL(string: "..."){
            // ...
          }

          models.append(
            Footer.barModel(
              content: FooterContent(
                primaryTitleText: "..."),
              style: style)
              .setBehaviors { context in
                context.view.primaryButtonState = self.isLoading ? .waiting : .normal
                context.view.primaryActionHandler = { [weak self] _ in
                  self?.acceptButtonWasTapped()
                }
              })
        }

      }
      """
    _ = try format(input, rules: [.redundantSelf])
  }

  @Test func redundantSelfParsingBug4() throws {
    let input = """
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          guard let row: Row = promotionSections[indexPath.section][indexPath.row] else { return UITableViewCell() }
          let cell = tableView.dequeueReusable(RowTableViewCell.self, forIndexPath: indexPath)
          cell.update(row: row)
          return cell
      }
      """
    _ = try format(input, rules: [.redundantSelf])
  }

  @Test func redundantSelfParsingBug5() throws {
    let input = """
      Button.primary(
          title: "Title",
          tapHandler: { [weak self] in
              self?.dismissBlock? {
                  // something
              }
          }
      )
      """
    _ = try format(input, rules: [.redundantSelf])
  }

  @Test func redundantSelfParsingBug6() throws {
    let input = """
      if let foo = bar, foo.tracking[jsonDict: "something"] != nil {}
      """
    _ = try format(input, rules: [.redundantSelf])
  }

  @Test func understandsParameterPacks_issue_1992() {
    let input = """
      @resultBuilder
      public enum DirectoryContentBuilder {
          public static func buildPartialBlock<each Accumulated>(
              accumulated: repeat each Accumulated,
              next: some DirectoryContent
          ) -> some DirectoryContent where repeat each Accumulated: DirectoryContent {
              Accumulate(
                  accumulated: repeat each accumulated,
                  next: next
              )
          }

          public static func buildEither<First, Second>(
              first component: First
          ) -> _Either<First, Second> where First: DirectoryContent, Second: DirectoryContent {
              .first(component)
          }

          struct List<Element>: DirectoryContent where Element: DirectoryContent {
              init(_ list: [Element]) {
                  self._list = list
              }

              private let _list: [Element]
          }
      }
      """

    let output = """
      @resultBuilder
      public enum DirectoryContentBuilder {
          public static func buildPartialBlock<each Accumulated>(
              accumulated: repeat each Accumulated,
              next: some DirectoryContent
          ) -> some DirectoryContent where repeat each Accumulated: DirectoryContent {
              Accumulate(
                  accumulated: repeat each accumulated,
                  next: next
              )
          }

          public static func buildEither<First, Second>(
              first component: First
          ) -> _Either<First, Second> where First: DirectoryContent, Second: DirectoryContent {
              .first(component)
          }

          struct List<Element>: DirectoryContent where Element: DirectoryContent {
              init(_ list: [Element]) {
                  _list = list
              }

              private let _list: [Element]
          }
      }
      """

    testFormatting(for: input, output, rule: .redundantSelf, exclude: [.simplifyGenericConstraints])
  }

  @Test func redundantSelfIssue2177() {
    let input = """
      final class A {
          let v1: Int
          var v2: Int { didSet {}}

          init(v1: Int, v2: Int) {
              self.v1 = v1
              self.v2 = v2
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.wrapPropertyBodies])
  }

  @Test func redundantSelfIssue2177_2() {
    let input = """
      final class A {
          let v1: Int
          var v2: Int { didSet { }}

          init(v1: Int, v2: Int) {
              self.v1 = v1
              self.v2 = v2
          }
      }
      """
    testFormatting(for: input, rule: .redundantSelf, exclude: [.emptyBraces, .wrapPropertyBodies])
  }

  @Test func redundantSelfIssue2177_3() {
    let input = """
      final class A {
          let v1: Int
          var v2: Int { didSet {} }

          init(v1: Int, v2: Int) {
              self.v1 = v1
              self.v2 = v2
          }
      }
      """
    testFormatting(
      for: input, rule: .redundantSelf, exclude: [.spaceInsideBraces, .wrapPropertyBodies])
  }

  @Test func forAwaitParsingError() {
    let input = """
      for await case (let index, let result)? in group {
          responses[index] = result
      }
      """
    testFormatting(
      for: input, rule: .redundantSelf,
      options: FormatOptions(
        hoistPatternLet: false,
        explicitSelf: .initOnly
      ))
  }

  @Test func conditionallyCompiledSelfRemoved() {
    let input = """
      extension View {
          @ViewBuilder
          func compatibleSearchable(
              text: Binding<String>,
              isPresented: Binding<Bool>,
              prompt: Text?
          ) -> some View {
              if #available(iOS 17, *) {
                  self.searchable(
                      text: text,
                      isPresented: isPresented,
                      prompt: prompt
                  )
              } else {
                  self.searchable(
                      text: text,
                      prompt: prompt
                  )
              }
          }
      }
      """
    let output = """
      extension View {
          @ViewBuilder
          func compatibleSearchable(
              text: Binding<String>,
              isPresented: Binding<Bool>,
              prompt: Text?
          ) -> some View {
              if #available(iOS 17, *) {
                  searchable(
                      text: text,
                      isPresented: isPresented,
                      prompt: prompt
                  )
              } else {
                  searchable(
                      text: text,
                      prompt: prompt
                  )
              }
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantSelf)
  }
}
