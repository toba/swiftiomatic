import Testing

@testable import Swiftiomatic

@Suite struct IndentTests {
  @Test func reduceIndentAtStartOfFile() {
    let input = """
          foo()
      """
    let output = """
      foo()
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func reduceIndentAtEndOfFile() {
    let input = """
      foo()
         bar()
      """
    let output = """
      foo()
      bar()
      """
    testFormatting(for: input, output, rule: .indent)
  }

  // indent parens

  @Test func simpleScope() {
    let input = """
      foo(
      bar
      )
      """
    let output = """
      foo(
          bar
      )
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func nestedScope() {
    let input = """
      foo(
      bar {
      }
      )
      """
    let output = """
      foo(
          bar {
          }
      )
      """
    testFormatting(for: input, output, rule: .indent, exclude: [.emptyBraces])
  }

  @Test func nestedScopeOnSameLine() {
    let input = """
      foo(bar(
      baz
      ))
      """
    let output = """
      foo(bar(
          baz
      ))
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func nestedScopeOnSameLine2() {
    let input = """
      foo(bar(in:
      baz))
      """
    let output = """
      foo(bar(in:
          baz))
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentNestedArrayLiteral() {
    let input = """
      foo(bar: [
      .baz,
      ])
      """
    let output = """
      foo(bar: [
          .baz,
      ])
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func closingScopeAfterContent() {
    let input = """
      foo(
      bar
      )
      """
    let output = """
      foo(
          bar
      )
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func closingNestedScopeAfterContent() {
    let input = """
      foo(bar(
      baz
      ))
      """
    let output = """
      foo(bar(
          baz
      ))
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func wrappedFunctionArguments() {
    let input = """
      foo(
      bar,
      baz
      )
      """
    let output = """
      foo(
          bar,
          baz
      )
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func functionArgumentsWrappedAfterFirst() {
    let input = """
      func foo(bar: Int,
      baz: Int)
      """
    let output = """
      func foo(bar: Int,
               baz: Int)
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentPreservedForNestedWrappedParameters() {
    let input = """
      let loginResponse = LoginResponse(status: .success(.init(accessToken: session,
                                                               status: .enabled)),
                                        invoicingURL: .invoicing,
                                        paymentFormURL: .paymentForm)
      """
    let options = FormatOptions(wrapParameters: .preserve)
    testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
  }

  @Test func indentPreservedForNestedWrappedParameters2() {
    let input = """
      let loginResponse = LoginResponse(status: .success(.init(accessToken: session,
                                                               status: .enabled),
                                                         invoicingURL: .invoicing,
                                                         paymentFormURL: .paymentForm))
      """
    let options = FormatOptions(wrapParameters: .preserve)
    testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
  }

  @Test func indentPreservedForNestedWrappedParameters3() {
    let input = """
      let loginResponse = LoginResponse(
          status: .success(.init(accessToken: session,
                                 status: .enabled),
                           invoicingURL: .invoicing,
                           paymentFormURL: .paymentForm)
      )
      """
    let options = FormatOptions(wrapParameters: .preserve)
    testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
  }

  @Test func indentTrailingClosureInParensContainingUnwrappedArguments() {
    let input = """
      let foo = bar(baz {
          quux(foo, bar)
      })
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentTrailingClosureInParensContainingWrappedArguments() {
    let input = """
      let foo = bar(baz {
          quux(foo,
               bar)
      })
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentTrailingClosureInParensContainingWrappedArguments2() {
    let input = """
      let foo = bar(baz {
          quux(
              foo,
              bar
          )
      })
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentImbalancedNestedClosingParens() {
    let input = """
      Foo(bar:
          Bar(
              baz: quux
          ))
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentChainedCallAfterClosingParen() {
    let input = """
      foo(
          bar: { baz in
              baz()
          })
          .quux {
              View()
          }
      """
    testFormatting(for: input, rule: .indent, exclude: [.wrapArguments])
  }

  @Test func indentChainedCallAfterClosingParen2() {
    let input = """
      func makeEpoxyModel() -> EpoxyModeling {
          LegacyEpoxyModelBuilder<BasicRow>(
              dataID: DataID.dismissModalBody.rawValue,
              content: .init(titleText: content.title, subtitleText: content.bodyHtml),
              style: Style.standard
                  .with(property: newValue)
                  .with(anotherProperty: newValue))
              .with(configurer: { view, content, _, _ in
                  view.setHTMLText(content.subtitleText?.unstyledText)
              })
              .build()
      }
      """
    let options = FormatOptions(closingParenPosition: .sameLine)
    testFormatting(for: input, rule: .indent, options: options)
  }

  // indent modifiers

  @Test func noIndentWrappedModifiersForProtocol() {
    let input = """
      @objc
      private
      protocol Foo {}
      """
    testFormatting(for: input, rule: .indent, exclude: [.modifiersOnSameLine])
  }

}
