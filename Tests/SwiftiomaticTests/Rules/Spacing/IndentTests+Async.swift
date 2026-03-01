import Testing

@testable import Swiftiomatic

extension IndentTests {
  // indent expression after return

  @Test func indentIdentifierAfterReturn() {
    let input = """
      if foo {
          return
              bar
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentEnumValueAfterReturn() {
    let input = """
      if foo {
          return
              .bar
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentMultilineExpressionAfterReturn() {
    let input = """
      if foo {
          return
              bar +
              baz
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func dontIndentClosingBraceAfterReturn() {
    let input = """
      if foo {
          return
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func dontIndentCaseAfterReturn() {
    let input = """
      switch foo {
      case bar:
          return
      case baz:
          return
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func dontIndentCaseAfterWhere() {
    let input = """
      switch foo {
      case bar
      where baz:
      return
      default:
      return
      }
      """
    let output = """
      switch foo {
      case bar
          where baz:
          return
      default:
          return
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func dontIndentIfAfterReturn() {
    let input = """
      if foo {
          return
          if bar {}
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func dontIndentFuncAfterReturn() {
    let input = """
      if foo {
          return
          func bar() {}
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  // indent fragments

  @Test func indentFragment() {
    let input = """
         func foo() {
      bar()
      }
      """
    let output = """
         func foo() {
             bar()
         }
      """
    let options = FormatOptions(fragment: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func indentFragmentAfterBlankLines() {
    let input = """

         func foo() {
      bar()
      }
      """
    let output = """

         func foo() {
             bar()
         }
      """
    let options = FormatOptions(fragment: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func unterminatedFragment() {
    let input = """
      class Foo {

        func foo() {
      bar()
      }
      """
    let output = """
      class Foo {

          func foo() {
              bar()
          }
      """
    let options = FormatOptions(fragment: true)
    testFormatting(
      for: input, output, rule: .indent, options: options,
      exclude: [.blankLinesAtStartOfScope],
    )
  }

  @Test func overTerminatedFragment() {
    let input = """
         func foo() {
      bar()
      }

      }
      """
    let output = """
         func foo() {
             bar()
         }

      }
      """
    let options = FormatOptions(fragment: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func dontCorruptPartialFragment() {
    let input = """
          } foo {
              bar
          }
      }
      """
    let options = FormatOptions(fragment: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func dontCorruptPartialFragment2() {
    let input = """
              return completionHandler(nil)
          }
      }
      """
    let options = FormatOptions(fragment: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func dontCorruptPartialFragment3() {
    let input = """
          foo: bar,
          foo1: bar2,
          foo2: bar3
      """
    let options = FormatOptions(fragment: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  // indent with tabs

  @Test func tabIndentWrappedTupleWithSmartTabs() {
    let input = """
      let foo = (bar: Int,
                 baz: Int)
      """
    let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func tabIndentWrappedTupleWithoutSmartTabs() {
    let input = """
      let foo = (bar: Int,
                 baz: Int)
      """
    let output = """
      let foo = (bar: Int,
      \t\t\t\t\t baz: Int)
      """
    let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: false)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func tabIndentCaseWithSmartTabs() {
    let input = """
      switch x {
      case .foo,
           .bar:
        break
      }
      """
    let output = """
      switch x {
      case .foo,
           .bar:
      \tbreak
      }
      """
    let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: true)
    testFormatting(
      for: input,
      output,
      rule: .indent,
      options: options,
      exclude: [.sortSwitchCases],
    )
  }

  @Test func tabIndentCaseWithoutSmartTabs() {
    let input = """
      switch x {
      case .foo,
           .bar:
        break
      }
      """
    let output = """
      switch x {
      case .foo,
      \t\t .bar:
      \tbreak
      }
      """
    let options = FormatOptions(indent: "\t", tabWidth: 2, smartTabs: false)
    testFormatting(
      for: input,
      output,
      rule: .indent,
      options: options,
      exclude: [.sortSwitchCases],
    )
  }

  @Test func tabIndentCaseWithoutSmartTabs2() {
    let input = """
      switch x {
          case .foo,
               .bar:
            break
      }
      """
    let output = """
      switch x {
      \tcase .foo,
      \t\t\t .bar:
      \t\tbreak
      }
      """
    let options = FormatOptions(
      indent: "\t", indentCase: true,
      tabWidth: 2, smartTabs: false,
    )
    testFormatting(
      for: input,
      output,
      rule: .indent,
      options: options,
      exclude: [.sortSwitchCases],
    )
  }

  // indent blank lines

  @Test func truncateBlankLineBeforeIndenting() throws {
    let input = """
      func foo() {
      \tguard bar = baz else { return }
      \t
      \tquux()
      }
      """
    let options = FormatOptions(indent: "\t", truncateBlankLines: true, tabWidth: 2)
    #expect(
      try lint(input, rules: [.indent, .trailingSpace], options: options) == [
        Formatter.Change(line: 3, rule: .trailingSpace, filePath: nil, isMove: false)
      ],
    )
  }

  @Test func noIndentBlankLinesIfTrimWhitespaceDisabled() {
    let input = """
      func foo() {
      \tguard bar = baz else { return }
      \t

      \tquux()
      }
      """
    let options = FormatOptions(indent: "\t", truncateBlankLines: false, tabWidth: 2)
    testFormatting(
      for: input, rule: .indent, options: options,
      exclude: [
        .consecutiveBlankLines,
        .wrapConditionalBodies,
        .blankLinesAfterGuardStatements,
      ],
    )
  }

  // async

  @Test func asyncThrowsNotUnindented() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          async throws -> String {}
      """
    let options = FormatOptions(closingParenPosition: .sameLine)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func asyncTypedThrowsNotUnindented() {
    let input = """
      func multilineFunction(
          foo _: String,
          bar _: String)
          async throws(Foo) -> String {}
      """
    let options = FormatOptions(closingParenPosition: .sameLine)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func indentAsyncLet() {
    let input = """
      func foo() async {
              async let bar = baz()
      async let baz = quux()
      }
      """
    let output = """
      func foo() async {
          async let bar = baz()
          async let baz = quux()
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentAsyncLetAfterLet() {
    let input = """
      func myFunc() {
          let x = 1
          async let foo = bar()
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentAsyncLetAfterBrace() {
    let input = """
      func myFunc() {
          let x = 1
          enum Baz {
              case foo
          }
          async let foo = bar()
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func asyncFunctionArgumentLabelNotIndented() {
    let input = """
      func multilineFunction(
          foo _: String,
          async _: String)
          -> String {}
      """
    let options = FormatOptions(closingParenPosition: .sameLine)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func indentIfExpressionAssignmentOnNextLine() {
    let input = """
      let foo =
      if let bar = someBar {
          bar
      } else if let baaz = someBaaz {
          baaz
      } else if let quux = someQuux {
          if let foo = someFoo {
              foo
          } else {
              quux
          }
      } else {
          foo2
      }

      print(foo)
      """

    let output = """
      let foo =
          if let bar = someBar {
              bar
          } else if let baaz = someBaaz {
              baaz
          } else if let quux = someQuux {
              if let foo = someFoo {
                  foo
              } else {
                  quux
              }
          } else {
              foo2
          }

      print(foo)
      """

    testFormatting(for: input, output, rule: .indent, exclude: [.wrapMultilineStatementBraces])
  }

  @Test func indentIfExpressionAssignmentOnSameLine() {
    let input = """
      let foo = if let bar {
          bar
      } else if let baaz {
          baaz
      } else if let quux {
          if let foo {
              foo
          } else {
              quux
          }
      }
      """

    testFormatting(for: input, rule: .indent, exclude: [.wrapMultilineConditionalAssignment])
  }

  @Test func indentSwitchExpressionAssignment() {
    let input = """
      let foo =
      switch bar {
      case true:
          bar
      case baaz:
          baaz
      }
      """

    let output = """
      let foo =
          switch bar {
          case true:
              bar
          case baaz:
              baaz
          }
      """

    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentSwitchExpressionAssignmentInNestedScope() {
    let input = """
      class Foo {
          func foo() -> Foo {
              let foo =
              switch bar {
              case true:
                  bar
              case baaz:
                  baaz
              }

              return foo
          }
      }
      """

    let output = """
      class Foo {
          func foo() -> Foo {
              let foo =
                  switch bar {
                  case true:
                      bar
                  case baaz:
                      baaz
                  }

              return foo
          }
      }
      """

    testFormatting(for: input, output, rule: .indent, exclude: [.redundantProperty])
  }

  @Test func indentNestedSwitchExpressionAssignment() {
    let input = """
      let foo =
      switch bar {
      case true:
          bar
      case baaz:
          switch bar {
          case true:
              bar
          case baaz:
              baaz
          }
      }
      """

    let output = """
      let foo =
          switch bar {
          case true:
              bar
          case baaz:
              switch bar {
              case true:
                  bar
              case baaz:
                  baaz
              }
          }
      """

    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentSwitchExpressionAssignmentWithComments() {
    let input = """
      let foo =
      // There is a comment before the switch statement
      switch bar {
      // Plus a comment before each case
      case true:
          bar
      // Plus a comment before each case
      case baaz:
          baaz
      }

      print(foo)
      """

    let output = """
      let foo =
          // There is a comment before the switch statement
          switch bar {
          // Plus a comment before each case
          case true:
              bar
          // Plus a comment before each case
          case baaz:
              baaz
          }

      print(foo)
      """

    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentIfExpressionWithSingleComment() {
    let input = """
      let foo =
          // There is a comment before the first branch
          if let foo {
              foo
          } else {
              bar
          }

      print(foo)
      """

    testFormatting(for: input, rule: .indent)
  }

  @Test func indentIfExpressionWithComments() {
    let input = """
      let foo =
          // There is a comment before the first branch
          if let foo {
              foo
          }
          // There is a comment before the second branch
          else {
              bar
          }

      print(foo)
      """

    testFormatting(for: input, rule: .indent, exclude: [.wrapMultilineStatementBraces])
  }

  @Test func indentMultilineIfExpression() {
    let input = """
      let foo =
          if
              let foo,
              foo != disallowedFoo
          {
              foo
          }
          // There is a comment before the second branch
          else {
              bar
          }

      print(foo)
      print(foo)
      """

    testFormatting(for: input, rule: .indent, exclude: [.braces])
  }

  @Test func indentNestedIfExpressionWithComments() {
    let input = """
      let foo =
          // There is a comment before the first branch
          if let foo {
              foo
          }
          // There is a comment before the second branch
          else {
              // And a comment before each of these nested branches
              if let bar {
                  bar
              }
              // And a comment before each of these nested branches
              else {
                  baaz
              }
          }

      print(foo)
      """

    testFormatting(for: input, rule: .indent, exclude: [.wrapMultilineStatementBraces])
  }

  @Test func indentIfExpressionWithMultilineComments() {
    let input = """
      let foo =
          // There is a comment before the first branch
          // which spans across multiple lines
          if let foo {
              foo
          }
          // And also a comment before the second branch
          // which spans across multiple lines
          else {
              bar
          }
      """

    testFormatting(for: input, rule: .indent)
  }

  @Test func sE0380Example() {
    let input = """
      let bullet =
          if isRoot && (count == 0 || !willExpand) { "" }
          else if count == 0 { "- " }
          else if maxDepth <= 0 { "▹ " }
          else { "▿ " }

      print(bullet)
      """
    let options = FormatOptions()
    testFormatting(
      for: input, rule: .indent, options: options,
      exclude: [.wrapConditionalBodies, .andOperator, .redundantParens],
    )
  }

  @Test func wrappedTernaryOperatorIndentsChainedCalls() {
    let input = """
      let ternary = condition
          ? values
              .map { $0.bar }
              .filter { $0.hasFoo }
              .last
          : other.values
              .compactMap { $0 }
              .first?
              .with(property: updatedValue)
      """

    let options = FormatOptions(wrapTernaryOperators: .beforeOperators, maxWidth: 60)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func indentSwitchCaseWhere() {
    let input = """
      switch testKey {
          case "organization"
          where testValues.map(String.init).compactMap { try? Entity.ID($0, format: .number) }
          .contains(Self.sessionInteractor.stage.value?.membership?.organization.id ?? .zero): // 2
              continue

          case "user"
          where testValues.map(String.init).compactMap { try? Entity.ID($0, format: .number) }
          .contains(Self.sessionInteractor.stage.value?.session?.user.id ?? .zero): // 3
              continue
      }
      """

    let options = FormatOptions(indentCase: true)
    testFormatting(
      for: input, rule: .indent, options: options,
      exclude: [
        .wrap,
        .wrapMultilineFunctionChains,
      ],
    )
  }

  @Test func guardElseIndentAfterParenthesizedExpression() {
    let input = """
      func format() {
          guard
              let result = foo(
                  bar: 5,
                  baz: 6
              )
          else {
              return
          }

          print(result)
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func guardElseIndentAfterSwitchExpression() {
    let input = """
      func format(foo: String?) {
          guard
              let result =
                  switch foo {
                  case .none: "none"
                  case .some: "some"
                  }
          else {
              return
          }

          print(result)
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func guardElseIndentAfterIfExpression() {
    let input = """
      func format(foo: Bool) {
          guard
              let result =
                  if foo {
                      bar
                  } else {
                      nil
                  }
          else {
              return
          }

          print(result)
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func ifElseIndentAfterSwitchExpression() {
    let input = """
      func format(foo: String?) {
          if
              let result =
                  switch foo {
                  case .none: "none"
                  case .some: "some"
                  }
          {
              return true
          } else {
              return false
          }

          print(result)
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentConditionalCompiledMacroInvocations() {
    let input = """
      #if true
          #warning("Warning")
      #else
          #warning("Warning")
      #endif
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentMacroInvocationsInCollection() {
    let input = """
      let urls = [
          googleURL,
          #URL("github.com"),
          #URL("apple.com"),
      ]
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func returnMacroInvocation() {
    let input = """
      func foo() {
          return
          #URL("github.com")
      }
      """
    let output = """
      func foo() {
          return
              #URL("github.com")
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }
}
