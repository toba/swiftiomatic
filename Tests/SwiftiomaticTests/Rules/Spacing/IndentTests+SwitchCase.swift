import Testing

@testable import Swiftiomatic

extension IndentTests {
  // indent switch/case

  @Test func switchCaseIndenting() {
    let input = """
      switch x {
      case foo:
      break
      case bar:
      break
      default:
      break
      }
      """
    let output = """
      switch x {
      case foo:
          break
      case bar:
          break
      default:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func switchWrappedCaseIndenting() {
    let input = """
      switch x {
      case foo,
      bar,
          baz:
          break
      default:
          break
      }
      """
    let output = """
      switch x {
      case foo,
           bar,
           baz:
          break
      default:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
  }

  @Test func switchWrappedEnumCaseIndenting() {
    let input = """
      switch x {
      case .foo,
      .bar,
          .baz:
          break
      default:
          break
      }
      """
    let output = """
      switch x {
      case .foo,
           .bar,
           .baz:
          break
      default:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
  }

  @Test func switchWrappedEnumCaseIndentingVariant2() {
    let input = """
      switch x {
      case
      .foo,
      .bar,
          .baz:
          break
      default:
          break
      }
      """
    let output = """
      switch x {
      case
          .foo,
          .bar,
          .baz:
          break
      default:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
  }

  @Test func switchWrappedEnumCaseIsIndenting() {
    let input = """
      switch x {
      case is Foo.Type,
          is Bar.Type:
          break
      default:
          break
      }
      """
    let output = """
      switch x {
      case is Foo.Type,
           is Bar.Type:
          break
      default:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent, exclude: [.sortSwitchCases])
  }

  @Test func switchCaseIsDictionaryIndenting() {
    let input = """
      switch x {
      case foo is [Key: Value]:
      fallthrough
      default:
      break
      }
      """
    let output = """
      switch x {
      case foo is [Key: Value]:
          fallthrough
      default:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func enumCaseIndenting() {
    let input = """
      enum Foo {
      case Bar
      case Baz
      }
      """
    let output = """
      enum Foo {
          case Bar
          case Baz
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func enumCaseIndentingCommas() {
    let input = """
      enum Foo {
      case Bar,
      Baz
      }
      """
    let output = """
      enum Foo {
          case Bar,
               Baz
      }
      """
    testFormatting(for: input, output, rule: .indent, exclude: [.wrapEnumCases])
  }

  @Test func genericEnumCaseIndenting() {
    let input = """
      enum Foo<T> {
      case Bar
      case Baz
      }
      """
    let output = """
      enum Foo<T> {
          case Bar
          case Baz
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentSwitchAfterRangeCase() {
    let input = """
      switch x {
      case 0 ..< 2:
          switch y {
          default:
              break
          }
      default:
          break
      }
      """
    testFormatting(for: input, rule: .indent, exclude: [.blankLineAfterSwitchCase])
  }

  @Test func indentEnumDeclarationInsideSwitchCase() {
    let input = """
      switch x {
      case y:
      enum Foo {
      case z
      }
      bar()
      default: break
      }
      """
    let output = """
      switch x {
      case y:
          enum Foo {
              case z
          }
          bar()
      default: break
      }
      """
    testFormatting(for: input, output, rule: .indent, exclude: [.blankLineAfterSwitchCase])
  }

  @Test func indentEnumCaseBodyAfterWhereClause() {
    let input = """
      switch foo {
      case _ where baz < quux:
          print(1)
          print(2)
      default:
          break
      }
      """
    testFormatting(for: input, rule: .indent, exclude: [.blankLineAfterSwitchCase])
  }

  @Test func indentSwitchCaseCommentsCorrectly() {
    let input = """
      switch x {
      // comment
      case y:
      // comment
      break
      // comment
      case z:
      break
      }
      """
    let output = """
      switch x {
      // comment
      case y:
          // comment
          break
      // comment
      case z:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent, exclude: [.blankLineAfterSwitchCase])
  }

  @Test func indentMultilineSwitchCaseCommentsCorrectly() {
    let input = """
      switch x {
      /*
       * comment
       */
      case y:
      break
      /*
       * comment
       */
      default:
      break
      }
      """
    let output = """
      switch x {
      /*
       * comment
       */
      case y:
          break
      /*
       * comment
       */
      default:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentEnumCaseComment() {
    let input = """
      enum Foo {
         /// bar
         case bar
      }
      """
    let output = """
      enum Foo {
          /// bar
          case bar
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentMultipleSingleLineSwitchCaseCommentsCorrectly() {
    let input = """
      switch x {
      // comment 1
      // comment 2
      case y:
      // comment
      break
      }
      """
    let output = """
      switch x {
      // comment 1
      // comment 2
      case y:
          // comment
          break
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentIfCase() {
    let input = """
      {
      if case let .foo(msg) = error {}
      }
      """
    let output = """
      {
          if case let .foo(msg) = error {}
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentGuardCase() {
    let input = """
      {
      guard case .Foo = error else {}
      }
      """
    let output = """
      {
          guard case .Foo = error else {}
      }
      """
    testFormatting(
      for: input, output, rule: .indent,
      exclude: [.wrapConditionalBodies],
    )
  }

  @Test func indentIfElse() {
    let input = """
      if foo {
      } else if let bar = baz,
                let baz = quux {}
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func nestedIndentIfElse() {
    let input = """
      if bar {} else if baz,
                        quux
      {
          if foo {
          } else if let bar = baz,
                    let baz = quux {}
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentIfCaseLet() {
    let input = """
      if case let foo = foo,
         let bar = bar {}
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentMultipleIfLet() {
    let input = """
      if let foo = foo, let bar = bar,
         let baz = baz {}
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentWrappedConditionAlignsWithParen() {
    let input = """
      do {
          if let foo = foo(
              bar: 5
          ), let bar = bar,
          baz == quux {
              baz()
          }
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentWrappedConditionAlignsWithParen2() {
    let input = """
      do {
          if let foo = foo({
              bar()
          }), bar == baz,
          let quux == baz {
              baz()
          }
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentUnknownDefault() {
    let input = """
      switch foo {
          case .bar:
              break
          @unknown default:
              break
      }
      """
    let output = """
      switch foo {
      case .bar:
          break
      @unknown default:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentUnknownDefaultOnOwnLine() {
    let input = """
      switch foo {
          case .bar:
              break
          @unknown
          default:
              break
      }
      """
    let output = """
      switch foo {
      case .bar:
          break
      @unknown
      default:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentUnknownCase() {
    let input = """
      switch foo {
          case .bar:
              break
          @unknown case _:
              break
      }
      """
    let output = """
      switch foo {
      case .bar:
          break
      @unknown case _:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentUnknownCaseOnOwnLine() {
    let input = """
      switch foo {
          case .bar:
              break
          @unknown
          case _:
              break
      }
      """
    let output = """
      switch foo {
      case .bar:
          break
      @unknown
      case _:
          break
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func wrappedClassDeclaration() {
    let input = """
      class Foo: Bar,
          Baz {
          init() {}
      }
      """
    testFormatting(
      for: input, rule: .indent,
      exclude: [.wrapMultilineStatementBraces],
    )
  }

  @Test func wrappedClassDeclarationLikeXcode() {
    let input = """
      class Foo: Bar,
          Baz {
          init() {}
      }
      """
    let output = """
      class Foo: Bar,
      Baz {
          init() {}
      }
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func wrappedClassDeclarationWithBracesOnSameLineLikeXcode() {
    let input = """
      class Foo: Bar,
      Baz {}
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func wrappedClassDeclarationWithBraceOnNextLineLikeXcode() {
    let input = """
      class Foo: Bar,
          Baz
      {
          init() {}
      }
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func wrappedClassWhereDeclarationLikeXcode() {
    let input = """
      class Foo<T>: Bar
          where T: Baz {
          init() {}
      }
      """
    let output = """
      class Foo<T>: Bar
      where T: Baz {
          init() {}
      }
      """
    let options = FormatOptions(xcodeIndentation: true)
    testFormatting(
      for: input, output, rule: .indent, options: options,
      exclude: [.simplifyGenericConstraints],
    )
  }

  @Test func indentSwitchCaseDo() {
    let input = """
      switch foo {
      case .bar: do {
              baz()
          }
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  // indentCase = true

  @Test func switchCaseWithIndentCaseTrue() {
    let input = """
      switch x {
      case foo:
      break
      case bar:
      break
      default:
      break
      }
      """
    let output = """
      switch x {
          case foo:
              break
          case bar:
              break
          default:
              break
      }
      """
    let options = FormatOptions(indentCase: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func switchWrappedEnumCaseWithIndentCaseTrue() {
    let input = """
      switch x {
      case .foo,
      .bar,
          .baz:
          break
      default:
          break
      }
      """
    let output = """
      switch x {
          case .foo,
               .bar,
               .baz:
              break
          default:
              break
      }
      """
    let options = FormatOptions(indentCase: true)
    testFormatting(
      for: input,
      output,
      rule: .indent,
      options: options,
      exclude: [.sortSwitchCases],
    )
  }

  @Test func indentMultilineSwitchCaseCommentsWithIndentCaseTrue() {
    let input = """
      switch x {
      /*
       * comment
       */
      case y:
      break
      /*
       * comment
       */
      default:
      break
      }
      """
    let output = """
      switch x {
          /*
           * comment
           */
          case y:
              break
          /*
           * comment
           */
          default:
              break
      }
      """
    let options = FormatOptions(indentCase: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func noMangleLabelWhenIndentCaseTrue() {
    let input = """
      foo: while true {
          break foo
      }
      """
    let options = FormatOptions(indentCase: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test
  func indentMultipleSingleLineSwitchCaseCommentsWithCommentsIgnoredCorrectlyWhenIndentCaseTrue() {
    let input = """
      switch x {
          // bar
          case .y: return 1
          // baz
          case .z: return 2
      }
      """
    let options = FormatOptions(indentCase: true, indentComments: false)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func indentUnknownDefaultCorrectlyWhenIndentCaseTrue() {
    let input = """
      switch foo {
      case .bar:
          break
      @unknown default:
          break
      }
      """
    let output = """
      switch foo {
          case .bar:
              break
          @unknown default:
              break
      }
      """
    let options = FormatOptions(indentCase: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func indentUnknownCaseCorrectlyWhenIndentCaseTrue() {
    let input = """
      switch foo {
      case .bar:
          break
      @unknown case _:
          break
      }
      """
    let output = """
      switch foo {
          case .bar:
              break
          @unknown case _:
              break
      }
      """
    let options = FormatOptions(indentCase: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func indentSwitchCaseDoWhenIndentCaseTrue() {
    let input = """
      switch foo {
          case .bar: do {
                  baz()
              }
      }
      """
    let options = FormatOptions(indentCase: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

}
