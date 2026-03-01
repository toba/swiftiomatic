import Testing

@testable import Swiftiomatic

extension IndentTests {
  @Test func noDoubleIndentForInInsideFunction() {
    let input = """
      func foo() { // comment here
          for idx in 0 ..< 100 {
              print(idx)
          }
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func noUnindentTrailingClosure() {
    let input = """
      private final class Foo {
          func animateTransition() {
              guard let fromVC = transitionContext.viewController(forKey: .from),
                    let toVC = transitionContext.viewController(forKey: .to) else {
                  return
              }

              UIView.transition(
                  with: transitionContext.containerView,
                  duration: transitionDuration(using: transitionContext),
                  options: []) {
                      fromVC.view.alpha = 0
                      transitionContext.containerView.addSubview(toVC.view)
                      toVC.view.frame = transitionContext.finalFrame(for: toVC)
                      toVC.view.alpha = 1
                  } completion: { _ in
                      transitionContext.completeTransition(true)
                      fromVC.view.removeFromSuperview()
                  }
          }
      }
      """
    testFormatting(
      for: input, rule: .indent,
      exclude: [.wrapArguments, .wrapMultilineStatementBraces],
    )
  }

  @Test func indentChainedPropertiesAfterFunctionCall() {
    let input = """
      let foo = Foo(
          bar: baz
      )
      .bar
      .baz
      """
    testFormatting(for: input, rule: .indent, exclude: [.propertyTypes])
  }

  @Test func indentChainedPropertiesAfterFunctionCallWithXcodeIndentation() {
    let input = """
      let foo = Foo(
          bar: baz
      )
      .bar
      .baz
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, rule: .indent, options: options, exclude: [.propertyTypes])
  }

  @Test func indentChainedPropertiesAfterFunctionCall2() {
    let input = """
      let foo = Foo({
          print("")
      })
      .bar
      .baz
      """
    testFormatting(
      for: input, rule: .indent,
      exclude: [.trailingClosures, .propertyTypes],
    )
  }

  @Test func indentChainedPropertiesAfterFunctionCallWithXcodeIndentation2() {
    let input = """
      let foo = Foo({
          print("")
      })
      .bar
      .baz
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(
      for: input, rule: .indent, options: options,
      exclude: [.trailingClosures, .propertyTypes],
    )
  }

  @Test func indentChainedMethodsAfterTrailingClosure() {
    let input = """
      func foo() -> some View {
          HStack(spacing: 0) {
              foo()
          }
          .bar()
          .baz()
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentChainedMethodsAfterTrailingClosureWithXcodeIndentation() {
    let input = """
      func foo() -> some View {
          HStack(spacing: 0) {
              foo()
          }
          .bar()
          .baz()
      }
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func indentChainedMethodsAfterWrappedMethodAfterTrailingClosure() {
    let input = """
      func foo() -> some View {
          HStack(spacing: 0) {
              foo()
          }
          .bar(foo: 1,
               bar: baz ? 2 : 3)
          .baz()
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentChainedMethodsAfterWrappedMethodAfterTrailingClosureWithXcodeIndentation() {
    let input = """
      func foo() -> some View {
          HStack(spacing: 0) {
              foo()
          }
          .bar(foo: 1,
               bar: baz ? 2 : 3)
          .baz()
      }
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func chainedFunctionOnNewLineWithXcodeIndentation() {
    let input = """
      bar(a: "A", b: "B")
      .baz()!
      .quux
      """
    let output = """
      bar(a: "A", b: "B")
          .baz()!
          .quux
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func chainedFunctionOnNewLineWithXcodeIndentation2() {
    let input = """
      let foo = bar
          .baz { _ in
              true
          }
          .quux { _ in
              false
          }
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func commentSeparatedChainedFunctionAfterBraceWithXcodeIndentation() {
    let input = """
      func foo() {
          bar {
              doSomething()
          }
          // baz
          .baz()
      }
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func chainedFunctionsInPropertySetterOnNewLineWithXcodeIndentation() {
    let input = """
      private let foo =
      bar(a: "A", b: "B")
      .baz()!
      .quux
      """
    let output = """
      private let foo =
          bar(a: "A", b: "B")
          .baz()!
          .quux
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func chainedFunctionsInFunctionWithReturnOnNewLineWithXcodeIndentation() {
    let input = """
      func foo() -> Bool {
      return
      bar(a: "A", b: "B")
      .baz()!
      .quux
      }
      """
    let output = """
      func foo() -> Bool {
          return
              bar(a: "A", b: "B")
              .baz()!
              .quux
      }
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func chainedFunctionInGuardIndentation() {
    let input = """
      guard
          let baz = foo
          .bar
          .baz
      else { return }
      """
    testFormatting(
      for: input, rule: .indent,
      exclude: [.wrapConditionalBodies],
    )
  }

  @Test func chainedFunctionInGuardWithXcodeIndentation() {
    let input = """
      guard
          let baz = foo
          .bar
          .baz
      else { return }
      """
    let output = """
      guard
          let baz = foo
              .bar
              .baz
      else { return }
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(
      for: input, output, rule: .indent,
      options: options, exclude: [.wrapConditionalBodies],
    )
  }

  @Test func chainedFunctionInGuardIndentation2() {
    let input = """
      guard aBool,
            anotherBool,
            aTestArray
            .map { $0 * 2 }
            .filter { $0 == 4 }
            .isEmpty,
            yetAnotherBool
      else { return }
      """
    testFormatting(
      for: input, rule: .indent,
      exclude: [.wrapConditionalBodies],
    )
  }

  @Test func chainedFunctionInGuardWithXcodeIndentation2() {
    let input = """
      guard aBool,
            anotherBool,
            aTestArray
            .map { $0 * 2 }
          .filter { $0 == 4 }
          .isEmpty,
          yetAnotherBool
      else { return }
      """
    // TODO: fix indent for `yetAnotherBool`
    let output = """
      guard aBool,
            anotherBool,
            aTestArray
                .map { $0 * 2 }
                .filter { $0 == 4 }
                .isEmpty,
                yetAnotherBool
      else { return }
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(
      for: input, output, rule: .indent,
      options: options, exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements],
    )
  }

  @Test func wrappedChainedFunctionsWithNestedScopeIndent() {
    let input = """
      var body: some View {
          VStack {
              ZStack {
                  Text()
              }
              .gesture(DragGesture()
                  .onChanged { value in
                      print(value)
                  })
          }
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func conditionalInitArgumentIndentAfterBrace() {
    let input = """
      struct Foo: Codable {
          let value: String
          let number: Int

          enum CodingKeys: String, CodingKey {
              case value
              case number
          }

          #if DEBUG
              init(
                  value: String,
                  number: Int
              ) {
                  self.value = value
                  self.number = number
              }
          #endif
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func conditionalInitArgumentIndentAfterBraceNoIndent() {
    let input = """
      struct Foo: Codable {
          let value: String
          let number: Int

          enum CodingKeys: String, CodingKey {
              case value
              case number
          }

          #if DEBUG
          init(
              value: String,
              number: Int
          ) {
              self.value = value
              self.number = number
          }
          #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func conditionalCompiledWrappedChainedFunctionIndent() {
    let input = """
      var body: some View {
          VStack {
              // some view
          }
          #if os(macOS)
              .frame(minWidth: 200)
          #elseif os(macOS)
                  .frame(minWidth: 150)
          #else
                      .frame(minWidth: 0)
          #endif
      }
      """
    let output = """
      var body: some View {
          VStack {
              // some view
          }
          #if os(macOS)
          .frame(minWidth: 200)
          #elseif os(macOS)
          .frame(minWidth: 150)
          #else
          .frame(minWidth: 0)
          #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .indent)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func conditionalCompiledWrappedChainedFunctionIndent2() {
    let input = """
      var body: some View {
          Text(
              "Hello"
          )
          #if os(macOS)
              .frame(minWidth: 200)
          #elseif os(macOS)
                  .frame(minWidth: 150)
          #else
                      .frame(minWidth: 0)
          #endif
      }
      """
    let output = """
      var body: some View {
          Text(
              "Hello"
          )
          #if os(macOS)
          .frame(minWidth: 200)
          #elseif os(macOS)
          .frame(minWidth: 150)
          #else
          .frame(minWidth: 0)
          #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .indent)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func conditionalCompiledWrappedChainedFunctionWithIfdefNoIndent() {
    let input = """
      var body: some View {
          VStack {
              // some view
          }
          #if os(macOS)
              .frame(minWidth: 200)
          #elseif os(macOS)
                  .frame(minWidth: 150)
          #else
                      .frame(minWidth: 0)
          #endif
      }
      """
    let output = """
      var body: some View {
          VStack {
              // some view
          }
          #if os(macOS)
          .frame(minWidth: 200)
          #elseif os(macOS)
          .frame(minWidth: 150)
          #else
          .frame(minWidth: 0)
          #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func conditionalCompiledWrappedChainedFunctionWithIfdefOutdent() {
    let input = """
      var body: some View {
          VStack {
              // some view
          }
      #if os(macOS)
      .frame(minWidth: 200)
      #elseif os(macOS)
              .frame(minWidth: 150)
      #else
                  .frame(minWidth: 0)
      #endif
      }
      """
    let output = """
      var body: some View {
          VStack {
              // some view
          }
      #if os(macOS)
          .frame(minWidth: 200)
      #elseif os(macOS)
          .frame(minWidth: 150)
      #else
          .frame(minWidth: 0)
      #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .outdent)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func chainedOrOperatorsInFunctionWithReturnOnNewLine() {
    let input = """
      func foo(lhs: Bool, rhs: Bool) -> Bool {
      return
      lhs == rhs &&
      lhs == rhs &&
      lhs == rhs
      }
      """
    let output = """
      func foo(lhs: Bool, rhs: Bool) -> Bool {
          return
              lhs == rhs &&
              lhs == rhs &&
              lhs == rhs
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func wrappedSingleLineClosureOnNewLine() {
    let input = """
      func foo() {
          let bar =
              { print("foo") }
      }
      """
    testFormatting(for: input, rule: .indent, exclude: [.braces])
  }

  @Test func wrappedMultilineClosureOnNewLine() {
    let input = """
      func foo() {
          let bar =
              {
                  print("foo")
              }
      }
      """
    testFormatting(for: input, rule: .indent, exclude: [.braces])
  }

  @Test func wrappedMultilineClosureOnNewLineWithAllmanBraces() {
    let input = """
      func foo() {
          let bar =
          {
              print("foo")
          }
      }
      """
    let options = FormatOptions(allmanBraces: true)
    testFormatting(
      for: input, rule: .indent, options: options,
      exclude: [.braces],
    )
  }

  @Test func indentChainedPropertiesAfterMultilineStringXcode() {
    let input = """
      let foo = \"\""
      bar
      \"\""
          .bar
          .baz
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func wrappedExpressionIndentAfterTryInClosure() {
    let input = """
      getter = { in
          try foo ??
              bar
      }
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func noIndentTryAfterCommaInCollection() {
    let input = """
      let expectedTabs: [Pet] = [
          viewModel.bird,
          try #require(viewModel.cat),
          try #require(viewModel.dog),
          viewModel.snake,
      ]
      """
    testFormatting(for: input, rule: .indent, exclude: [.hoistTry])
  }

  @Test func indentChainedFunctionAfterTryInParens() {
    let input = """
      func fooify(_ array: [FooBar]) -> [Foo] {
          return (
              try? array
                  .filter { !$0.isBar }
                  .compactMap { $0.foo }
          ) ?? []
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentLabelledTrailingClosure() {
    let input = """
      var buttonLabel: some View {
          label()
              .if(isInline) {
                  $0.font(.hsBody)
              }
              else: {
                  $0.font(.hsControl)
              }
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentLinewrappedMultipleTrailingClosures() {
    let input = """
      UIView.animate(withDuration: 0) {
          fromView.transform = .identity
      }
      completion: { finished in
          context.completeTransition(finished)
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentLinewrappedMultipleTrailingClosures2() {
    let input = """
      func foo() {
          UIView.animate(withDuration: 0) {
              fromView.transform = .identity
          }
          completion: { finished in
              context.completeTransition(finished)
          }
      }
      """
    testFormatting(for: input, rule: .indent)
  }

}
