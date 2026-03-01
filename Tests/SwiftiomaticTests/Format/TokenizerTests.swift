import Testing

@testable import Swiftiomatic

@Suite struct TokenizerTests {
  // MARK: Invalid input

  @Test func invalidToken() {
    let input = "let `foo = bar"
    let output: [Token] = [
      .keyword("let"),
      .space(" "),
      .error("`foo"),
      .space(" "),
      .operator("=", .infix),
      .space(" "),
      .identifier("bar"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func unclosedBraces() {
    let input = "func foo() {"
    let output: [Token] = [
      .keyword("func"),
      .space(" "),
      .identifier("foo"),
      .startOfScope("("),
      .endOfScope(")"),
      .space(" "),
      .startOfScope("{"),
      .error(""),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func unclosedMultilineComment() {
    let input = "/* comment"
    let output: [Token] = [
      .startOfScope("/*"),
      .space(" "),
      .commentBody("comment"),
      .error(""),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func unclosedString() {
    let input = "\"Hello World"
    let output: [Token] = [
      .startOfScope("\""),
      .stringBody("Hello World"),
      .error(""),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func unbalancedScopes() {
    let input = "array.map({ return $0 )"
    let output: [Token] = [
      .identifier("array"),
      .operator(".", .infix),
      .identifier("map"),
      .startOfScope("("),
      .startOfScope("{"),
      .space(" "),
      .keyword("return"),
      .space(" "),
      .identifier("$0"),
      .space(" "),
      .error(")"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func forwardBackslashOperator() {
    let input = "infix operator /\\"
    let output: [Token] = [
      .identifier("infix"),
      .space(" "),
      .keyword("operator"),
      .space(" "),
      .operator("/", .none),
      .operator("\\", .none),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: Hashbang

  @Test func hashbangOnItsOwnInFile() {
    let input = "#!/usr/bin/swift"
    let output: [Token] = [
      .startOfScope("#!"),
      .commentBody("/usr/bin/swift"),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func hashbangAtStartOfFile() {
    let input = "#!/usr/bin/swift \n"
    let output: [Token] = [
      .startOfScope("#!"),
      .commentBody("/usr/bin/swift"),
      .space(" "),
      .linebreak("\n", 1),
    ]
    #expect(tokenize(input) == output)
  }

  @Test func hashbangAfterFirstLine() {
    let input = "//Hello World\n#!/usr/bin/swift \n"
    let output: [Token] = [
      .startOfScope("//"),
      .commentBody("Hello World"),
      .linebreak("\n", 1),
      .error("#!/usr/bin/swift"),
      .space(" "),
      .linebreak("\n", 2),
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: Unescaping

  @Test func unescapeInteger() {
    let input = Token.number("1_000_000_000", .integer)
    let output = "1000000000"
    #expect(input.unescaped() == output)
  }

  @Test func unescapeDecimal() {
    let input = Token.number("1_000.00_5", .decimal)
    let output = "1000.005"
    #expect(input.unescaped() == output)
  }

  @Test func unescapeBinary() {
    let input = Token.number("0b010_1010_101", .binary)
    let output = "0101010101"
    #expect(input.unescaped() == output)
  }

  @Test func unescapeHex() {
    let input = Token.number("0xFF_764Ep1_345", .hex)
    let output = "FF764Ep1345"
    #expect(input.unescaped() == output)
  }

  @Test func unescapeIdentifier() {
    let input = Token.identifier("`for`")
    let output = "for"
    #expect(input.unescaped() == output)
  }

  @Test func unescapeLinebreak() {
    let input = Token.stringBody("Hello\\nWorld")
    let output = "Hello\nWorld"
    #expect(input.unescaped() == output)
  }

  @Test func unescapeQuotedString() {
    let input = Token.stringBody("\\\"Hello World\\\"")
    let output = "\"Hello World\""
    #expect(input.unescaped() == output)
  }

  @Test func unescapeUnicodeLiterals() {
    let input = Token.stringBody("\\u{1F1FA}\\u{1F1F8}")
    let output = "\u{1F1FA}\u{1F1F8}"
    #expect(input.unescaped() == output)
  }

  // MARK: Space

  @Test func spaces() {
    let input = "    "
    let output: [Token] = [
      .space("    ")
    ]
    #expect(tokenize(input) == output)
  }

  @Test func spacesAndTabs() {
    let input = "  \t  \t"
    let output: [Token] = [
      .space("  \t  \t")
    ]
    #expect(tokenize(input) == output)
  }

  // MARK: Linebreaks

  @Test func carriageReturnLinefeed() {
    let input = "\r\n"
    let output: [Token] = [
      .linebreak("\r\n", 1)
    ]
    #expect(tokenize(input) == output)
  }

  @Test func verticalTab() {
    let input = "\u{000B}"
    let output: [Token] = [
      .linebreak("\u{000B}", 1)
    ]
    #expect(tokenize(input) == output)
  }

  @Test func formfeed() {
    let input = "\u{000C}"
    let output: [Token] = [
      .linebreak("\u{000C}", 1)
    ]
    #expect(tokenize(input) == output)
  }

}
