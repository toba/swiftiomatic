import Testing

@testable import Swiftiomatic

@Suite struct ExtensionAccessControlTests {
  @Test func updatesVisibilityOfExtensionMembers() {
    let input = """
      private extension Foo {
          var publicProperty: Int { 10 }
          public func publicFunction1() {}
          func publicFunction2() {}
          internal func internalFunction() {}
          private func privateFunction() {}
          fileprivate var privateProperty: Int { 10 }
      }
      """

    let output = """
      extension Foo {
          fileprivate var publicProperty: Int { 10 }
          public func publicFunction1() {}
          fileprivate func publicFunction2() {}
          internal func internalFunction() {}
          private func privateFunction() {}
          fileprivate var privateProperty: Int { 10 }
      }
      """

    testFormatting(
      for: input, output, rule: .extensionAccessControl,
      options: FormatOptions(extensionACLPlacement: .onDeclarations),
      exclude: [.redundantInternal, .wrapPropertyBodies],
    )
  }

  @Test func updatesVisibilityOfExtensionInConditionalCompilationBlock() {
    let input = """
      #if DEBUG
          public extension Foo {
              var publicProperty: Int { 10 }
          }
      #endif
      """

    let output = """
      #if DEBUG
          extension Foo {
              public var publicProperty: Int { 10 }
          }
      #endif
      """

    testFormatting(
      for: input, output, rule: .extensionAccessControl,
      options: FormatOptions(extensionACLPlacement: .onDeclarations),
      exclude: [.wrapPropertyBodies],
    )
  }

  @Test func updatesVisibilityOfExtensionMembersInConditionalCompilationBlock() {
    let input = """
      public extension Foo {
          #if DEBUG
              var publicProperty: Int { 10 }
          #endif
      }
      """

    let output = """
      extension Foo {
          #if DEBUG
              public var publicProperty: Int { 10 }
          #endif
      }
      """

    testFormatting(
      for: input, output, rule: .extensionAccessControl,
      options: FormatOptions(extensionACLPlacement: .onDeclarations),
      exclude: [.wrapPropertyBodies],
    )
  }

  @Test func doesNotUpdateDeclarationsInsideTypeInsideExtension() {
    let input = """
      public extension Foo {
          struct Bar {
              var baz: Int
              var quux: Int
          }
      }
      """

    let output = """
      extension Foo {
          public struct Bar {
              var baz: Int
              var quux: Int
          }
      }
      """

    testFormatting(
      for: input, output, rule: .extensionAccessControl,
      options: FormatOptions(extensionACLPlacement: .onDeclarations),
      exclude: [.wrapPropertyBodies],
    )
  }

  @Test func doesNothingForInternalExtension() {
    let input = """
      extension Foo {
          func bar() {}
          func baz() {}
          public func quux() {}
      }
      """

    testFormatting(
      for: input, rule: .extensionAccessControl,
      options: FormatOptions(extensionACLPlacement: .onDeclarations),
    )
  }

  @Test func placesVisibilityKeywordAfterAnnotations() {
    let input = """
      public extension Foo {
          @discardableResult
          func bar() -> Int { 10 }

          /// Doc comment
          @discardableResult
          @available(iOS 10.0, *)
          func baz() -> Int { 10 }

          @objc func quux() {}
          @available(iOS 10.0, *) func quixotic() {}
      }
      """

    let output = """
      extension Foo {
          @discardableResult
          public func bar() -> Int { 10 }

          /// Doc comment
          @discardableResult
          @available(iOS 10.0, *)
          public func baz() -> Int { 10 }

          @objc public func quux() {}
          @available(iOS 10.0, *) public func quixotic() {}
      }
      """

    testFormatting(
      for: input, output, rule: .extensionAccessControl,
      options: FormatOptions(extensionACLPlacement: .onDeclarations),
      exclude: [.wrapFunctionBodies],
    )
  }

  @Test func convertsExtensionPrivateToMemberFileprivate() {
    let input = """
      private extension Foo {
          var bar: Int
      }

      let bar = Foo().bar
      """

    let output = """
      extension Foo {
          fileprivate var bar: Int
      }

      let bar = Foo().bar
      """

    testFormatting(
      for: input, output, rule: .extensionAccessControl,
      options: FormatOptions(extensionACLPlacement: .onDeclarations, swiftVersion: "4"),
      exclude: [.propertyTypes],
    )
  }

  // MARK: extensionAccessControl .onExtension

  @Test func updatedVisibilityOfExtension() {
    let input = """
      extension Foo {
          public func bar() {}
          public var baz: Int { 10 }

          public struct Foo2 {
              var quux: Int
          }
      }
      """

    let output = """
      public extension Foo {
          func bar() {}
          var baz: Int { 10 }

          struct Foo2 {
              var quux: Int
          }
      }
      """

    testFormatting(
      for: input, output, rule: .extensionAccessControl, exclude: [.wrapPropertyBodies],
    )
  }

  @Test func updatedVisibilityOfExtensionWithDeclarationsInConditionalCompilation() {
    let input = """
      extension Foo {
          #if DEBUG
              public func bar() {}
              public var baz: Int { 10 }
          #endif
      }
      """

    let output = """
      public extension Foo {
          #if DEBUG
              func bar() {}
              var baz: Int { 10 }
          #endif
      }
      """

    testFormatting(
      for: input, output, rule: .extensionAccessControl, exclude: [.wrapPropertyBodies],
    )
  }

  @Test func doesNotUpdateExtensionVisibilityWithoutMajorityBodyVisibility() {
    let input = """
      extension Foo {
          public func foo() {}
          public func bar() {}
          var baz: Int { 10 }
          var quux: Int { 5 }
      }
      """

    testFormatting(for: input, rule: .extensionAccessControl, exclude: [.wrapPropertyBodies])
  }

  @Test func updateExtensionVisibilityWithMajorityBodyVisibility() {
    let input = """
      extension Foo {
          public func foo() {}
          public func bar() {}
          public var baz: Int { 10 }
          var quux: Int { 5 }
      }
      """

    let output = """
      public extension Foo {
          func foo() {}
          func bar() {}
          var baz: Int { 10 }
          internal var quux: Int { 5 }
      }
      """

    testFormatting(
      for: input, output, rule: .extensionAccessControl, exclude: [.wrapPropertyBodies],
    )
  }

  @Test func doesNotUpdateExtensionVisibilityWhenMajorityBodyVisibilityIsntMostVisible() {
    let input = """
      extension Foo {
          func foo() {}
          func bar() {}
          public var baz: Int { 10 }
      }
      """

    testFormatting(for: input, rule: .extensionAccessControl, exclude: [.wrapPropertyBodies])
  }

  @Test func doesNotUpdateExtensionVisibilityWithInternalDeclarations() {
    let input = """
      extension Foo {
          func bar() {}
          var baz: Int { 10 }
      }
      """

    testFormatting(for: input, rule: .extensionAccessControl, exclude: [.wrapPropertyBodies])
  }

  @Test func doesNotUpdateExtensionThatAlreadyHasCorrectVisibilityKeyword() {
    let input = """
      public extension Foo {
          func bar() {}
          func baz() {}
      }
      """

    testFormatting(for: input, rule: .extensionAccessControl)
  }

  @Test func updatesExtensionThatHasHigherACLThanBodyDeclarations() {
    let input = """
      public extension Foo {
          fileprivate func bar() {}
          fileprivate func baz() {}
      }
      """

    let output = """
      fileprivate extension Foo {
          func bar() {}
          func baz() {}
      }
      """

    testFormatting(
      for: input, output, rule: .extensionAccessControl,
      exclude: [.redundantFileprivate],
    )
  }

  @Test func doesNotHoistPrivateVisibilityFromExtensionBodyDeclarations() {
    let input = """
      extension Foo {
          private var bar() {}
          private func baz() {}
      }
      """

    testFormatting(for: input, rule: .extensionAccessControl)
  }

  @Test func doesNotUpdatesExtensionThatHasLowerACLThanBodyDeclarations() {
    let input = """
      private extension Foo {
          public var bar() {}
          public func baz() {}
      }
      """

    testFormatting(for: input, rule: .extensionAccessControl)
  }

  @Test func doesNotReduceVisibilityOfImplicitInternalDeclaration() {
    let input = """
      extension Foo {
          fileprivate var bar() {}
          func baz() {}
      }
      """

    testFormatting(for: input, rule: .extensionAccessControl)
  }

  @Test func updatesExtensionThatHasRedundantACLOnBodyDeclarations() {
    let input = """
      public extension Foo {
          func bar() {}
          public func baz() {}
      }
      """

    let output = """
      public extension Foo {
          func bar() {}
          func baz() {}
      }
      """

    testFormatting(for: input, output, rule: .extensionAccessControl)
  }

  @Test func noHoistAccessModifierForOpenMethod() {
    let input = """
      extension Foo {
          open func bar() {}
      }
      """
    testFormatting(for: input, rule: .extensionAccessControl)
  }

  @Test func dontChangePrivateExtensionToFileprivate() {
    let input = """
      private extension Foo {
          func bar() {}
      }
      """
    testFormatting(for: input, rule: .extensionAccessControl)
  }

  @Test func dontRemoveInternalKeywordFromExtension() {
    let input = """
      internal extension Foo {
          func bar() {}
      }
      """
    testFormatting(for: input, rule: .extensionAccessControl, exclude: [.redundantInternal])
  }

  @Test func noHoistAccessModifierForExtensionThatAddsProtocolConformance() {
    let input = """
      extension Foo: Bar {
          public func bar() {}
      }
      """
    testFormatting(for: input, rule: .extensionAccessControl)
  }

  @Test func noHoistAccessModifierForExtensionThatAddsPreconcurrencyProtocolConformance() {
    let input = """
      extension Foo: @preconcurrency Bar {
          public func bar() {}
      }
      """
    testFormatting(for: input, rule: .extensionAccessControl)
  }

  @Test func protocolConformanceCheckNotFooledByWhereClause() {
    let input = """
      extension Foo where Self: Bar {
          public func bar() {}
      }
      """
    let output = """
      public extension Foo where Self: Bar {
          func bar() {}
      }
      """
    testFormatting(for: input, output, rule: .extensionAccessControl)
  }

  @Test func accessNotHoistedIfTypeVisibilityIsLower() {
    let input = """
      class Foo {}

      extension Foo {
          public func bar() {}
      }
      """
    testFormatting(for: input, rule: .extensionAccessControl, exclude: [.redundantPublic])
  }

  @Test func extensionAccessControlRuleTerminatesInFileWithConditionalCompilation() {
    let input = """
      #if os(Linux)
          #error("Linux is currently not supported")
      #endif
      """

    testFormatting(for: input, rule: .extensionAccessControl)
  }

  @Test func extensionAccessControlRuleTerminatesInFileWithEmptyType() {
    let input = """
      struct Foo {
          // This type is empty
      }

      extension Foo {
          // This extension is empty
      }
      """

    testFormatting(for: input, rule: .extensionAccessControl, exclude: [.emptyExtensions])
  }
}
