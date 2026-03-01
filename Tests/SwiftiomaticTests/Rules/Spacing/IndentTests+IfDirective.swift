import Testing

@testable import Swiftiomatic

extension IndentTests {
  // indent #if/#else/#elseif/#endif

  @Test(.disabled("Indent behavior differs from upstream SwiftFormat"))
  func ifDefIndentModes() {
    let input = """
      struct ContentView: View {
          var body: some View {
              // sm:options --ifdef indent

              Text("Hello, world!")
              // Comment above
              #if os(macOS)
                  .padding()
              #endif

              Text("Hello, world!")
              #if os(macOS)
                  // Comment inside
                  .padding()
              #endif

              // sm:options --ifdef no-indent

              Text("Hello, world!")
              // Comment above
              #if os(macOS)
                  .padding()
              #endif

              Text("Hello, world!")
              #if os(macOS)
                  // Comment inside
                  .padding()
              #endif

              // sm:options --ifdef outdent

              Text("Hello, world!")
              // Comment above
              #if os(macOS)
                  .padding()
              #endif

              Text("Hello, world!")
              #if os(macOS)
                  // Comment inside
                  .padding()
              #endif
          }
      }
      """
    let output = """
      struct ContentView: View {
          var body: some View {
              // sm:options --ifdef indent

              Text("Hello, world!")
              // Comment above
              #if os(macOS)
                  .padding()
              #endif

              Text("Hello, world!")
              #if os(macOS)
                  // Comment inside
                  .padding()
              #endif

              // sm:options --ifdef no-indent

              Text("Hello, world!")
              // Comment above
              #if os(macOS)
                  .padding()
              #endif

              Text("Hello, world!")
              #if os(macOS)
                  // Comment inside
                  .padding()
              #endif

              // sm:options --ifdef outdent

              Text("Hello, world!")
      // Comment above
      #if os(macOS)
                  .padding()
      #endif

              Text("Hello, world!")
      #if os(macOS)
                  // Comment inside
                  .padding()
      #endif
          }
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  // indent #if/#else/#elseif/#endif (mode: indent)

  @Test func ifEndifIndenting() {
    let input = """
      #if x
      // foo
      #endif
      """
    let output = """
      #if x
          // foo
      #endif
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentedIfEndifIndenting() {
    let input = """
      {
      #if x
      // foo
      foo()
      #endif
      }
      """
    let output = """
      {
          #if x
              // foo
              foo()
          #endif
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func ifElseEndifIndenting() {
    let input = """
      #if x
          // foo
      foo()
      #else
          // bar
      #endif
      """
    let output = """
      #if x
          // foo
          foo()
      #else
          // bar
      #endif
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func enumIfCaseEndifIndenting() {
    let input = """
      enum Foo {
      case bar
      #if x
      case baz
      #endif
      }
      """
    let output = """
      enum Foo {
          case bar
          #if x
              case baz
          #endif
      }
      """
    let options = FormatOptions(indentCase: false)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func switchIfCaseEndifIndenting() {
    let input = """
      switch foo {
      case .bar: break
      #if x
      case .baz: break
      #endif
      }
      """
    let output = """
      switch foo {
      case .bar: break
      #if x
          case .baz: break
      #endif
      }
      """
    let options = FormatOptions(indentCase: false)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func switchIfCaseEndifIndenting2() {
    let input = """
      switch foo {
      case .bar: break
      #if x
      case .baz: break
      #endif
      }
      """
    let output = """
      switch foo {
          case .bar: break
          #if x
              case .baz: break
          #endif
      }
      """
    let options = FormatOptions(indentCase: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func switchIfCaseEndifIndenting3() {
    let input = """
      switch foo {
      #if x
      case .bar: break
      case .baz: break
      #endif
      }
      """
    let output = """
      switch foo {
      #if x
          case .bar: break
          case .baz: break
      #endif
      }
      """
    let options = FormatOptions(indentCase: false)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func switchIfCaseEndifIndenting4() {
    let input = """
      switch foo {
      #if x
      case .bar:
      break
      case .baz:
      break
      #endif
      }
      """
    let output = """
      switch foo {
          #if x
              case .bar:
                  break
              case .baz:
                  break
          #endif
      }
      """
    let options = FormatOptions(indentCase: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func switchIfCaseElseCaseEndifIndenting() {
    let input = """
      switch foo {
      #if x
      case .bar: break
      #else
      case .baz: break
      #endif
      }
      """
    let output = """
      switch foo {
      #if x
          case .bar: break
      #else
          case .baz: break
      #endif
      }
      """
    let options = FormatOptions(indentCase: false)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func switchIfCaseElseCaseEndifIndenting2() {
    let input = """
      switch foo {
      #if x
      case .bar: break
      #else
      case .baz: break
      #endif
      }
      """
    let output = """
      switch foo {
          #if x
              case .bar: break
          #else
              case .baz: break
          #endif
      }
      """
    let options = FormatOptions(indentCase: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func switchIfEndifInsideCaseIndenting() {
    let input = """
      switch foo {
      case .bar:
      #if x
      bar()
      #endif
      baz()
      case .baz: break
      }
      """
    let output = """
      switch foo {
      case .bar:
          #if x
              bar()
          #endif
          baz()
      case .baz: break
      }
      """
    let options = FormatOptions(indentCase: false)
    testFormatting(
      for: input, output, rule: .indent, options: options,
      exclude: [.blankLineAfterSwitchCase],
    )
  }

  @Test func switchIfEndifInsideCaseIndenting2() {
    let input = """
      switch foo {
      case .bar:
      #if x
      bar()
      #endif
      baz()
      case .baz: break
      }
      """
    let output = """
      switch foo {
          case .bar:
              #if x
                  bar()
              #endif
              baz()
          case .baz: break
      }
      """
    let options = FormatOptions(indentCase: true)
    testFormatting(
      for: input, output, rule: .indent, options: options,
      exclude: [.blankLineAfterSwitchCase],
    )
  }

  @Test func ifUnknownCaseEndifIndenting() {
    let input = """
      switch foo {
      case .bar: break
      #if x
          @unknown case _: break
      #endif
      }
      """
    let options = FormatOptions(indentCase: false, ifdefIndent: .indent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifUnknownCaseEndifIndenting2() {
    let input = """
      switch foo {
          case .bar: break
          #if x
              @unknown case _: break
          #endif
      }
      """
    let options = FormatOptions(indentCase: true, ifdefIndent: .indent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifEndifInsideEnumIndenting() {
    let input = """
      enum Foo {
          case bar
          #if x
              case baz
          #endif
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func ifEndifInsideEnumWithTrailingCommentIndenting() {
    let input = """
      enum Foo {
          case bar
          #if x
              case baz
          #endif // ends
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func noIndentCommentBeforeIfdefAroundCase() {
    let input = """
      switch x {
      // foo
      case .foo:
          break
      // conditional
      // bar
      #if BAR
          case .bar:
              break
      // baz
      #else
          case .baz:
              break
      #endif
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func noIndentCommentedCodeBeforeIfdefAroundCase() {
    let input = """
      func foo() {
      //    foo()
          #if BAR
      //        bar()
          #else
      //        baz()
          #endif
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func noIndentIfdefFollowedByCommentAroundCase() {
    let input = """
      switch x {
      case .foo:
          break
      #if BAR
          // bar
          case .bar:
              break
      #else
          // baz
          case .baz:
              break
      #endif
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentIfDefPostfixMemberSyntax() {
    let input = """
      class Bar {
          func foo() {
              Text("Hello")
              #if os(iOS)
              .font(.largeTitle)
              #elseif os(macOS)
                      .font(.headline)
              #else
                  .font(.headline)
              #endif
          }
      }
      """
    let output = """
      class Bar {
          func foo() {
              Text("Hello")
              #if os(iOS)
                  .font(.largeTitle)
              #elseif os(macOS)
                  .font(.headline)
              #else
                  .font(.headline)
              #endif
          }
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentIfDefPostfixMemberSyntax2() {
    let input = """
      class Bar {
          func foo() {
              Text("Hello")
              #if os(iOS)
                  .font(.largeTitle)
              #endif
                  .color(.red)
          }
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func noIndentDotExpressionInsideIfdef() {
    let input = """
      let current: Platform = {
          #if os(macOS)
              .mac
          #elseif os(Linux)
              .linux
          #elseif os(Windows)
              .windows
          #else
              fatalError("Unknown OS not supported")
          #endif
      }()
      """
    testFormatting(for: input, rule: .indent)
  }

  // indent #if/#else/#elseif/#endif (mode: noindent)

  @Test func ifEndifNoIndenting() {
    let input = """
      #if x
      // foo
      #endif
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func indentedIfEndifNoIndenting() {
    let input = """
      {
      #if x
      // foo
      #endif
      }
      """
    let output = """
      {
          #if x
          // foo
          #endif
      }
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func ifElseEndifNoIndenting() {
    let input = """
      #if x
      // foo
      #else
      // bar
      #endif
      """
    let options = FormatOptions(ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifCaseEndifNoIndenting() {
    let input = """
      switch foo {
      case .bar: break
      #if x
      case .baz: break
      #endif
      }
      """
    let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifCaseEndifNoIndenting2() {
    let input = """
      switch foo {
      case .bar: break
      #if x
      case .baz: break
      #endif
      }
      """
    let output = """
      switch foo {
          case .bar: break
          #if x
          case .baz: break
          #endif
      }
      """
    let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func ifUnknownCaseEndifNoIndenting() {
    let input = """
      switch foo {
      case .bar: break
      #if x
      @unknown case _: break
      #endif
      }
      """
    let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifUnknownCaseEndifNoIndenting2() {
    let input = """
      switch foo {
          case .bar: break
          #if x
          @unknown case _: break
          #endif
      }
      """
    let options = FormatOptions(indentCase: true, ifdefIndent: .noIndent)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func ifEndifInsideCaseNoIndenting() {
    let input = """
      switch foo {
      case .bar:
      #if x
      bar()
      #endif
      baz()
      case .baz: break
      }
      """
    let output = """
      switch foo {
      case .bar:
          #if x
          bar()
          #endif
          baz()
      case .baz: break
      }
      """
    let options = FormatOptions(indentCase: false, ifdefIndent: .noIndent)
    testFormatting(
      for: input, output, rule: .indent, options: options,
      exclude: [.blankLineAfterSwitchCase],
    )
  }

}
