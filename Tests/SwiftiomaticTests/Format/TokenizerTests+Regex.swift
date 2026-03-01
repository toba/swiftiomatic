import Testing

@testable import Swiftiomatic

extension TokenizerTests {
  // MARK: Regex literals

  @Test func singleLineRegexLiteral() {
    let input = "let regex = /(\\w+)\\s\\s+(\\S+)\\s\\s+((?:(?!\\s\\s).)*)\\s\\s+(.*)/"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("regex"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("/"),
      .stringBody("(\\w+)\\s\\s+(\\S+)\\s\\s+((?:(?!\\s\\s).)*)\\s\\s+(.*)"),
      .endOfScope("/"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func anchoredSingleLineRegexLiteral() {
    let input = "let _ = /^foo$/"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("_"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("/"),
      .stringBody("^foo$"),
      .endOfScope("/"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func singleLineRegexLiteralStartingWithEscapeSequence() {
    let input = "let regex = /\\w+/"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("regex"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("/"),
      .stringBody("\\w+"),
      .endOfScope("/"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func singleLineRegexLiteralWithEscapedParens() {
    let input = "let regex = /\\(foo\\)/"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("regex"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("/"),
      .stringBody("\\(foo\\)"),
      .endOfScope("/"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func singleLineRegexLiteralWithEscapedClosingParen() {
    let input = "let regex = /\\)/"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("regex"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("/"),
      .stringBody("\\)"),
      .endOfScope("/"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func singleLineRegexLiteralWithEscapedClosingParenAtStartOfFile() {
    let input = "/\\)/"
    let output: [Token] = [
      .startOfScope("/"),
      .stringBody("\\)"),
      .endOfScope("/"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func singleLineRegexLiteralWithEscapedClosingParenAtStartOfLine() {
    let input = """
      let a = b
      /\\)/
      """
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("a"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("b"),
      .linebreak("\n", 1),
      .startOfScope("/"),
      .stringBody("\\)"),
      .endOfScope("/"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func singleLineRegexLiteralPrecededByTry() {
    let input = "let regex=try/foo/"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("regex"),
      .operator("=", .infix),
      .keyword("try"),
      .startOfScope("/"),
      .stringBody("foo"),
      .endOfScope("/"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func singleLineRegexLiteralPrecededByOptionalTry() {
    let input = "let regex=try?/foo/"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("regex"),
      .operator("=", .infix),
      .keyword("try"),
      .operator("?", .postfix),
      .startOfScope("/"),
      .stringBody("foo"),
      .endOfScope("/"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func regexLiteralInArray() {
    let input = "[/foo/]"
    let output: [Token] = [
      .startOfScope("["),
      .startOfScope("/"),
      .stringBody("foo"),
      .endOfScope("/"),
      .endOfScope("]"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func regexLiteralAfterLabel() {
    let input = "foo(of: /http|https/)"
    let output: [Token] = [
      .identifier("foo"),
      .startOfScope("("),
      .identifier("of"),
      .delimiter(":"),
      .space(" "),
      .startOfScope("/"),
      .stringBody("http|https"),
      .endOfScope("/"),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func hashedSingleLineRegexLiteral() {
    let input = "let regex = #/foo/bar/#"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("regex"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("#/"),
      .stringBody("foo/bar"),
      .endOfScope("/#"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func multilineRegexLiteral() {
    let input = """
      let regex = #/
      foo
      /#
      """
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("regex"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("#/"),
      .linebreak("\n", 1),
      .stringBody("foo"),
      .linebreak("\n", 2),
      .endOfScope("/#"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func multilineRegexLiteral2() {
    let input = """
      let regex = ##/
      foo
      bar
      /##
      """
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("regex"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("##/"),
      .linebreak("\n", 1),
      .stringBody("foo"),
      .linebreak("\n", 2),
      .stringBody("bar"),
      .linebreak("\n", 3),
      .endOfScope("/##"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func divisionFollowedByCommentNotMistakenForRegexLiteral() {
    let input = "foo = bar / 100 // baz"
    let output: [Token] = [
      .identifier("foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("bar"),
      .space(" "),
      .operator("/", .infix),
      .space(" "),
      .number("100", .integer),
      .space(" "),
      .startOfScope("//"),
      .space(" "),
      .commentBody("baz"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func prefixPostfixSlashOperatorNotPermitted() {
    let input = "let x = /0; let y = 1/"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("x"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("/"),
      .stringBody("0; let y = 1"),
      .endOfScope("/"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func inlineSlashPairTreatedAsOperators() {
    let input = "x+/y/+z"
    let output: [Token] = [
      .identifier("x"),
      .operator("+/", .infix),
      .identifier("y"),
      .operator("/+", .infix),
      .identifier("z"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func casePathTreatedAsOperator() {
    let input = "let foo = /Foo.bar"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .operator("/", .prefix),
      .identifier("Foo"),
      .operator(".", .infix),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func casePathTreatedAsOperator2() {
    let input = "let foo = /Foo.bar\nbaz"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .operator("/", .prefix),
      .identifier("Foo"),
      .operator(".", .infix),
      .identifier("bar"),
      .linebreak("\n", 2),
      .identifier("baz"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func casePathInParenthesesTreatedAsOperator() {
    let input = "foo(/Foo.bar)"
    let output: [Token] = [
      .identifier("foo"),
      .startOfScope("("),
      .operator("/", .prefix),
      .identifier("Foo"),
      .operator(".", .infix),
      .identifier("bar"),
      .endOfScope(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func divideOperatorInParenthesesTreatedAsOperator() {
    let input = "return (/)\n"
    let output: [Token] = [
      .keyword("return"),
      .space(" "),
      .startOfScope("("),
      .operator("/", .none),
      .endOfScope(")"),
      .linebreak("\n", 2),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func prefixSlashCaretOperator() {
    let input = "let _ = /^foo"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("_"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .operator("/^", .prefix),
      .identifier("foo"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func prefixSlashQueryOperator() {
    let input = "let _ = /?foo"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("_"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .operator("/?", .prefix),
      .identifier("foo"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func prefixSlashOperatorFollowedByComment() {
    let input = "let _ = /Foo.bar//"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("_"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .operator("/", .prefix),
      .identifier("Foo"),
      .operator(".", .infix),
      .identifier("bar"),
      .startOfScope("//"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func regexCannotEndWithUnescapedSpace() {
    let input = "let _ = /foo / bar"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("_"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .operator("/", .prefix),
      .identifier("foo"),
      .space(" "),
      .operator("/", .infix),
      .space(" "),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func hashedRegexCanEndWithUnescapedSpace() {
    let input = "let _ = #/foo /#"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .identifier("_"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .startOfScope("#/"),
      .stringBody("foo "),
      .endOfScope("/#"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func standaloneSlashOperator() {
    let input = "/"
    let output: [Token] = [.operator("/", .none)]
    #expect(tokenize(input) == output)
  }

}
