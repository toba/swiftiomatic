import Testing

@testable import Swiftiomatic

@Suite struct FormatterTests {
  @Test func removeCurrentTokenWhileEnumerating() {
    let input: [Token] = [
      .identifier("foo"),
      .identifier("bar"),
      .identifier("baz"),
    ]
    var output: [Token] = []
    let formatter = Formatter(input, options: .default)
    formatter.forEachToken { i, token in
      output.append(token)
      if i == 1 {
        formatter.removeToken(at: i)
      }
    }
    #expect(output == input)
  }

  @Test func removePreviousTokenWhileEnumerating() {
    let input: [Token] = [
      .identifier("foo"),
      .identifier("bar"),
      .identifier("baz"),
    ]
    var output: [Token] = []
    let formatter = Formatter(input, options: .default)
    formatter.forEachToken { i, token in
      output.append(token)
      if i == 1 {
        formatter.removeToken(at: i - 1)
      }
    }
    #expect(output == input)
  }

  @Test func removeNextTokenWhileEnumerating() {
    let input: [Token] = [
      .identifier("foo"),
      .identifier("bar"),
      .identifier("baz"),
    ]
    var output: [Token] = []
    let formatter = Formatter(input, options: .default)
    formatter.forEachToken { i, token in
      output.append(token)
      if i == 1 {
        formatter.removeToken(at: i + 1)
      }
    }
    #expect(output == [Token](input.dropLast()))
  }

  @Test func indexBeforeComment() {
    let input: [Token] = [
      .identifier("foo"),
      .startOfScope("//"),
      .space(" "),
      .commentBody("bar"),
      .linebreak("\n", 1),
    ]
    let formatter = Formatter(input, options: .default)
    let index = formatter.index(before: 4, where: { !$0.isSpaceOrComment })
    #expect(index == 0)
  }

  @Test func indexBeforeMultilineComment() {
    let input: [Token] = [
      .identifier("foo"),
      .startOfScope("/*"),
      .space(" "),
      .commentBody("bar"),
      .space(" "),
      .endOfScope("*/"),
      .linebreak("\n", 1),
    ]
    let formatter = Formatter(input, options: .default)
    let index = formatter.index(before: 6, where: { !$0.isSpaceOrComment })
    #expect(index == 0)
  }

  // MARK: enable/disable directives

  @Test func disableRule() throws {
    let input = "//sm:disable spaceAroundOperators\nlet foo : Int=5;"
    let output = "// sm:disable spaceAroundOperators\nlet foo : Int=5\n"
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func directiveInMiddleOfComment() throws {
    let input = "//fixme: sm:disable spaceAroundOperators - bug\nlet foo : Int=5;"
    let output = "// FIXME: sm:disable spaceAroundOperators - bug\nlet foo : Int=5\n"
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func disableAndReEnableRules() throws {
    let input = """
      // sm:disable indent blankLinesBetweenScopes redundantSelf
      class Foo {
      let _foo = "foo"
      func foo() {
      print(self._foo)
      }
      }
      // sm:enable indent redundantSelf
      class Bar {
      let _bar = "bar"
      func bar() {
      print(_bar)
      }
      }
      """
    let output = """
      // sm:disable indent blankLinesBetweenScopes redundantSelf
      class Foo {
      let _foo = "foo"
      func foo() {
      print(self._foo)
      }
      }
      // sm:enable indent redundantSelf
      class Bar {
          let _bar = "bar"
          func bar() {
              print(_bar)
          }
      }
      """
    #expect(try format(input + "\n", rules: FormatRules.default).output == output + "\n")
  }

  @Test func disableAllRules() throws {
    let input = "//sm:disable all\nlet foo : Int=5;"
    #expect(try format(input, rules: FormatRules.default).output == input)
  }

  @Test func disableAndReEnableAllRules() throws {
    let input = """
      // sm:disable all
      class Foo {
      let _foo = "foo"
      func foo() {
      print(self._foo)
      }
      }
      // sm:enable all
      class Bar {
      let _bar = "bar"
      func bar() {
      print(_bar)
      }
      }
      """
    let output = """
      // sm:disable all
      class Foo {
      let _foo = "foo"
      func foo() {
      print(self._foo)
      }
      }
      // sm:enable all
      class Bar {
          let _bar = "bar"
          func bar() {
              print(_bar)
          }
      }
      """
    #expect(try format(input + "\n", rules: FormatRules.default).output == output + "\n")
  }

  @Test func disableAllRulesAndReEnableOneRule() throws {
    let input =
      "//sm:disable all\nlet foo : Int=5;\n//sm:enable linebreakAtEndOfFile"
    let output =
      "//sm:disable all\nlet foo : Int=5;\n//sm:enable linebreakAtEndOfFile\n"
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func disableNext() throws {
    let input = "//sm:disable:next all\nlet foo : Int=5;\nlet foo : Int=5;"
    let output = "// sm:disable:next all\nlet foo : Int=5;\nlet foo: Int = 5\n"
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func enableNext() throws {
    let input =
      "//sm:disable all\n//sm:enable:next all\nlet foo : Int=5;\nlet foo : Int=5;"
    let output =
      "//sm:disable all\n//sm:enable:next all\nlet foo: Int = 5\nlet foo : Int=5;"
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func disableThis() throws {
    let input = "let foo : Int=5; // sm:disable:this all\nlet foo : Int=5;"
    let output = "let foo : Int=5; // sm:disable:this all\nlet foo: Int = 5\n"
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func enableThis() throws {
    let input =
      "//sm:disable all\nlet foo : Int=5; //sm:enable:this all\nlet foo : Int=5;"
    let output =
      "//sm:disable all\nlet foo: Int = 5 // sm:enable:this all\nlet foo : Int=5;"
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func disableRuleWithMultilineComment() throws {
    let input = "/*sm:disable spaceAroundOperators*/let foo : Int=5;"
    let output = "/* sm:disable spaceAroundOperators */ let foo : Int=5\n"
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func disableAllRulesWithMultilineComment() throws {
    let input = "/*sm:disable all*/let foo : Int=5;"
    let output = "/*sm:disable all*/let foo : Int=5;"
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func disableAndReenableAllRulesWithMultilineComment() throws {
    let input = """
      /*sm:disable all*/let foo : Int=5;/*sm:enable all*/let foo : Int=5;
      """
    let output = """
      /*sm:disable all*/let foo : Int=5; /* sm:enable all */ let foo: Int = 5

      """
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func disableNextWithMultilineComment() throws {
    let input = "/*sm:disable:next all*/\nlet foo : Int=5;\nlet foo : Int=5;"
    let output = "/* sm:disable:next all */\nlet foo : Int=5;\nlet foo: Int = 5\n"
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func enableNextWithMultilineComment() throws {
    let input =
      "//sm:disable all\n/*sm:enable:next all*/\nlet foo : Int=5;\nlet foo : Int=5;"
    let output =
      "//sm:disable all\n/*sm:enable:next all*/\nlet foo: Int = 5\nlet foo : Int=5;"
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test func disableLinewrap() throws {
    let input = """
      // sm:disable all
      let foo = bar.baz(some: param).quux("a string of some sort")
      """
    let options = FormatOptions(maxWidth: 10)
    #expect(try format(input, rules: FormatRules.default, options: options).output == input)
  }

  @Test func malformedDirective() {
    let input = "// sm:disbible all"
    do {
      _ = try format(input, rules: FormatRules.default).output
      Issue.record("Expected error")
    } catch {
      #expect("\(error)" == "Unknown directive 'sm:disbible' on line 1")
    }
  }

  @Test func malformedDirective2() {
    let input = "// sm: --disable all"
    do {
      _ = try format(input, rules: FormatRules.default).output
      Issue.record("Expected error")
    } catch {
      #expect("\(error)" == "Expected directive after 'sm:' prefix on line 1")
    }
  }

  // MARK: options directive

  @Test(.disabled("Inline sm:options not supported")) func allmanOption() throws {
    let input = """
      // sm:options --allman true
      func foo() {
          print("bar")
      }

      """
    let output = """
      // sm:options --allman true
      func foo()
      {
          print("bar")
      }

      """
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test(.disabled("Inline sm:options not supported")) func allmanThis() throws {
    let input = """
      func foo() // sm:options:this --allman true
      {
          print("bar")
      }

      func foo()
      { // sm:options:this --allman true
          print("bar")
      }

      """
    #expect(try format(input, rules: FormatRules.default).output == input)
  }

  @Test(.disabled("Inline sm:options not supported")) func allmanNext() throws {
    let input = """
      func foo() // sm:options:next --allman true
      {
          print("bar")
      }

      """
    #expect(try format(input, rules: FormatRules.default).output == input)
  }

  @Test(.disabled("Inline sm:options not supported")) func allmanPrevious() throws {
    let input = """
      func foo()
      {
          // sm:options:previous --allman true
          print("bar")
      }

      """
    #expect(try format(input, rules: FormatRules.default).output == input)
  }

  @Test(.disabled("Inline sm:options not supported")) func indentNext() throws {
    let input = """
      class Foo {
          // sm:options:next --indent 2
          func bar() {
              print("bar")
          }

          func baz() {
              print("bar")
          }
      }

      """
    let output = """
      class Foo {
          // sm:options:next --indent 2
          func bar() {
            print("bar")
          }

          func baz() {
              print("bar")
          }
      }

      """
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test(.disabled("Inline sm:options not supported")) func swiftVersionNext() throws {
    let input = """
      // sm:options:next --swiftversion 5.2
      let foo1 = bar.map { $0.foo }
      let foo2 = bar.map { $0.foo }

      """
    let output = """
      // sm:options:next --swiftversion 5.2
      let foo1 = bar.map(\\.foo)
      let foo2 = bar.map { $0.foo }

      """
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test(.disabled("Inline sm:options not supported")) func cumulativeOptions() throws {
    let input = """
      // sm:options --self insert
      // sm:options:next --swiftversion 5.2
      let foo1 = self.map { $0.foo }
      // sm:options --self remove
      let foo2 = self.map { $0.foo }

      """
    let output = """
      // sm:options --self insert
      // sm:options:next --swiftversion 5.2
      let foo1 = self.map(\\.foo)
      // sm:options --self remove
      let foo2 = map { $0.foo }

      """
    #expect(try format(input, rules: FormatRules.default).output == output)
  }

  @Test(.disabled("Inline sm:options not supported")) func malformedOption() {
    let input = """
      // sm:options blooblahbleh
      """
    do {
      _ = try format(input, rules: FormatRules.default).output
      Issue.record("Expected error")
    } catch {
      #expect("\(error)".contains("Unknown option blooblahbleh"))
    }
  }

  @Test(.disabled("Inline sm:options not supported")) func invalidOption() {
    let input = """
      // sm:options --foobar baz
      """
    do {
      _ = try format(input, rules: FormatRules.default).output
      Issue.record("Expected error")
    } catch {
      #expect("\(error)".contains("Unknown option --foobar"))
    }
  }

  @Test(.disabled("Inline sm:options not supported")) func invalidOptionValue() {
    let input = """
      // sm:options --indent baz
      """
    do {
      _ = try format(input, rules: FormatRules.default).output
      Issue.record("Expected error")
    } catch {
      #expect("\(error)" == "Unsupported --indent value 'baz' on line 1")
    }
  }

  @Test(.disabled("Inline sm:options not supported")) func invalidEnumOptionValue() {
    let input = """
      // sm:options --else-position prev-line
      """
    do {
      _ = try format(input, rules: FormatRules.default).output
      Issue.record("Expected error")
    } catch {
      #expect(
        "\(error)" == """
          Unsupported --else-position value 'prev-line' on line 1. Valid options are "same-line" or "next-line"
          """,
      )
    }
  }

  @Test(.disabled("Inline sm:options not supported")) func invalidEnumOptionValue2() {
    let input = """
      // sm:options --else-position next
      """
    do {
      _ = try format(input, rules: FormatRules.default).output
      Issue.record("Expected error")
    } catch {
      #expect(
        "\(error)" == """
          Unsupported --else-position value 'next' on line 1. Did you mean 'next-line'?
          """,
      )
    }
  }

  @Test(.disabled("Inline sm:options not supported")) func invalidBoolOptionValue() {
    let input = """
      // sm:options --allman always
      """
    do {
      _ = try format(input, rules: FormatRules.default).output
      Issue.record("Expected error")
    } catch {
      #expect(
        "\(error)" == """
          Unsupported --allman value 'always' on line 1. Valid options are "true" or "false"
          """,
      )
    }
  }

  @Test(.disabled("Inline sm:options not supported")) func deprecatedOptionValue() {
    let input = """
      // sm:options --ranges spaced
      """
    #expect(throws: Never.self) { try format(input, rules: FormatRules.default).output }
  }

  // MARK: linebreaks

  @Test func linebreakAfterLinebreakReturnsCorrectIndex() {
    let formatter = Formatter([
      .linebreak("\n", 1),
      .linebreak("\n", 1),
    ])
    #expect(formatter.linebreakToken(for: 1) == .linebreak("\n", 1))
  }

  @Test func originalLinePreservedAfterFormatting() {
    let formatter = Formatter([
      .identifier("foo"),
      .space(" "),
      .startOfScope("{"),
      .linebreak("\n", 1),
      .linebreak("\n", 2),
      .space("    "),
      .identifier("bar"),
      .linebreak("\n", 3),
      .endOfScope("}"),
    ])
    FormatRule.blankLinesAtStartOfScope.apply(with: formatter)
    #expect(
      formatter.tokens == [
        .identifier("foo"),
        .space(" "),
        .startOfScope("{"),
        .linebreak("\n", 2),
        .space("    "),
        .identifier("bar"),
        .linebreak("\n", 3),
        .endOfScope("}"),
      ],
    )
  }

  // MARK: Format range

  @Test func codeOutsideRangeNotFormatted() throws {
    let input = tokenize(
      """
      func foo () {

          var  bar = 5
      }
      """,
    )
    for range in [0..<2, 5..<7, 14..<16, 17..<19] {
      #expect(
        try sourceCode(
          for: format(
            input,
            rules: FormatRules.all,
            range: range,
          ).tokens,
        ) == sourceCode(for: input), "range \(range)",
      )
    }
    let output1 = tokenize(
      """
      func foo () {

          var bar = 5
      }
      """,
    )
    #expect(
      try format(
        input,
        rules: [.consecutiveSpaces],
        range: 10..<13,
      ).tokens == output1,
    )
    let output2 = """
      func foo () {
          var  bar = 5
      }
      """
    #expect(
      try sourceCode(
        for: format(
          input,
          rules: [.blankLinesAtStartOfScope],
          range: 6..<9,
        ).tokens,
      ) == output2,
    )
  }

  // MARK: format line range

  @Test func formattingRange() throws {
    let input = """
      let  badlySpaced1:Int   = 5
      let   badlySpaced2:Int=5
      let   badlySpaced3 : Int = 5
      """
    let output = """
      let  badlySpaced1:Int   = 5
      let badlySpaced2: Int = 5
      let   badlySpaced3 : Int = 5
      """
    #expect(try format(input, lineRange: 2...2).output == output)
  }

  @Test func formattingRange2() throws {
    let input = """
      enum ImagesToShow {
      case none
      case mentioned
      case all
      }
      """
    let output = """
      enum ImagesToShow
      {
          case none
      case mentioned
      case all
      }
      """
    let options = FormatOptions(allmanBraces: true)
    #expect(try format(input, options: options, lineRange: 1...2).output == output)
  }

  @Test func formattingRangeNoCrash() throws {
    let input = """
      func foo() {
        if bar {
          print(  "foo")
        }
      }
      """
    let output = """
      func foo() {
        if bar {
              print("foo")
          }
      }
      """
    let inputTokens = tokenize(input)
    let outputTokens = tokenize(output)
    #expect(tokenRange(forLineRange: 3...4, in: inputTokens) == 14..<26)
    #expect(tokenRange(forLineRange: 3...4, in: outputTokens) == 14..<25)
    #expect(try format(input, lineRange: 3...4).output == output)
  }

  // MARK: endOfScope

  @Test func endOfScopeInSwitch() {
    let formatter = Formatter(
      tokenize(
        """
        switch foo {
        case bar: break
        }
        """,
      ),
    )
    #expect(formatter.endOfScope(at: 4) == 13)
  }

  // MARK: change tracking

  @Test func trackChangesInFirstLine() {
    let formatter = Formatter(tokenize("foo bar\nbaz"), trackChanges: true)
    let tokens = formatter.tokens
    formatter.removeLastToken()
    #expect(formatter.tokens != tokens)
    #expect(formatter.changes.count == 1)
    #expect(formatter.changes.first?.line == 2)
  }

  @Test func trackChangesInSecondLine() throws {
    let formatter = Formatter(tokenize("foo\nbar\nbaz"), trackChanges: true)
    let tokens = formatter.tokens
    try formatter.removeToken(at: #require(formatter.tokens.firstIndex(of: .identifier("bar"))))
    #expect(formatter.tokens != tokens)
    #expect(formatter.changes.count == 1)
    #expect(formatter.changes.first?.line == 2)
  }

  @Test func trackChangesInLastLine() {
    let formatter = Formatter(tokenize("foo\nbar\nbaz"), trackChanges: true)
    let tokens = formatter.tokens
    formatter.removeLastToken()
    #expect(formatter.tokens != tokens)
    #expect(formatter.changes.count == 1)
    #expect(formatter.changes.first?.line == 3)
  }

  @Test func trackChangesInSingleLine() {
    let formatter = Formatter(tokenize("foo bar"), trackChanges: true)
    let tokens = formatter.tokens
    formatter.removeToken(at: 0)
    #expect(formatter.tokens != tokens)
    #expect(formatter.changes.count == 1)
  }

  @Test func trackChangesIgnoresLinebreakIndex() {
    let formatter = Formatter(tokenize("\n\n"), trackChanges: true)
    var tokens = formatter.tokens
    tokens.insert(tokens.removeLast(), at: 0)
    #expect(formatter.tokens != tokens)
    formatter.replaceTokens(in: 0..<2, with: tokens)
    #expect(formatter.changes.isEmpty)
  }

  @Test func trackRemovalOfBlankLineFollowedByBlankLine() {
    let formatter = Formatter(tokenize("foo\n\n\n"), trackChanges: true)
    let tokens = formatter.tokens
    formatter.removeToken(at: 2)
    #expect(formatter.tokens != tokens)
    #expect(formatter.changes.count == 1)
    #expect(formatter.changes.first?.line == 2)
  }

  @Test func trackRemovalOfBlankLineAfterBlankLine() {
    let formatter = Formatter(tokenize("foo\n\n\n"), trackChanges: true)
    let tokens = formatter.tokens
    formatter.removeLastToken()
    #expect(formatter.tokens != tokens)
    #expect(formatter.changes.count == 1)
    #expect(formatter.changes.first?.line == 3)
  }

  @Test func moveTokensToEarlierPositionTrackedAsMoves() {
    let formatter = Formatter(tokenize("foo()\nbar()\n"), trackChanges: true)
    formatter.moveTokens(in: 4...7, to: 0)
    #expect(sourceCode(for: formatter.tokens) == "bar()\nfoo()\n")
    #expect(!formatter.changes.isEmpty)
    #expect(formatter.changes.filter { !$0.isMove }.isEmpty)
  }

  @Test func moveTokensToFollowingPositionTrackedAsMoves() {
    let formatter = Formatter(tokenize("foo()\nbar()\n"), trackChanges: true)
    formatter.moveTokens(in: 0...3, to: 8)
    #expect(sourceCode(for: formatter.tokens) == "bar()\nfoo()\n")
    #expect(!formatter.changes.isEmpty)
    #expect(formatter.changes.filter { !$0.isMove }.isEmpty)
  }

  @Test func replaceAllTokensTracksMoves() {
    let input: [Token] = [
      tokenize("foo()"), [.linebreak("\n", 0)],
      [.linebreak("\n", 1)],
      tokenize("foobar()"), [.linebreak("\n", 2)],
      [.linebreak("\n", 3)],
      tokenize("bar()"), [.linebreak("\n", 4)],
      [.linebreak("\n", 5)],
      tokenize("baaz()"), [.linebreak("\n", 6)],
    ].flatMap(\.self)

    let output: [Token] = [
      tokenize("bar()"), [.linebreak("\n", 4)],
      [.linebreak("\n", 1)],
      tokenize("barfoo()"), [.linebreak("\n", 2)],
      [.linebreak("\n", 3)],
      tokenize("foo()"), [.linebreak("\n", 0)],
      [.linebreak("\n", 5)],
      tokenize("quux()"), [.linebreak("\n", 6)],
    ].flatMap(\.self)

    let formatter = Formatter(input, trackChanges: true)
    formatter.diffAndReplaceTokens(in: ClosedRange(formatter.tokens.indices), with: output)
    #expect(sourceCode(for: formatter.tokens) == sourceCode(for: output))

    // The changes should include both moves and non-moves
    #expect(formatter.changes.contains(where: \.isMove))
    #expect(formatter.changes.contains { !$0.isMove })
  }
}
