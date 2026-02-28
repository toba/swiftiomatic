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
            .space("    "),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func spacesAndTabs() {
        let input = "  \t  \t"
        let output: [Token] = [
            .space("  \t  \t"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: Linebreaks

    @Test func carriageReturnLinefeed() {
        let input = "\r\n"
        let output: [Token] = [
            .linebreak("\r\n", 1),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func verticalTab() {
        let input = "\u{000B}"
        let output: [Token] = [
            .linebreak("\u{000B}", 1),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func formfeed() {
        let input = "\u{000C}"
        let output: [Token] = [
            .linebreak("\u{000C}", 1),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: Strings

    @Test func emptyString() {
        let input = "\"\""
        let output: [Token] = [
            .startOfScope("\""),
            .endOfScope("\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func simpleString() {
        let input = "\"foo\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("foo"),
            .endOfScope("\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func stringWithEscape() {
        let input = "\"hello\\tworld\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("hello\\tworld"),
            .endOfScope("\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func stringWithEscapedQuotes() {
        let input = "\"\\\"nice\\\" to meet you\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("\\\"nice\\\" to meet you"),
            .endOfScope("\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func stringWithEscapedLogic() {
        let input = "\"hello \\(name)\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("hello \\"),
            .startOfScope("("),
            .identifier("name"),
            .endOfScope(")"),
            .endOfScope("\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func stringWithEscapedBackslash() {
        let input = "\"\\\\\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("\\\\"),
            .endOfScope("\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func unterminatedString() {
        let input = "\"foo"
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("foo"),
            .error(""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func unterminatedString2() {
        let input = "\"foo\nbar"
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("foo"),
            .error(""),
            .linebreak("\n", 1),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func unterminatedString3() {
        let input = "\"foo\n\""
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("foo"),
            .error(""),
            .linebreak("\n", 1),
            .startOfScope("\""),
            .error(""),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: Multiline strings

    @Test func simpleMultilineString() {
        let input = "\"\"\"\n    hello\n    world\n    \"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .space("    "),
            .stringBody("hello"),
            .linebreak("\n", 2),
            .space("    "),
            .stringBody("world"),
            .linebreak("\n", 3),
            .space("    "),
            .endOfScope("\"\"\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func indentedSimpleMultilineString() {
        let input = "\"\"\"\n    hello\n    world\n\"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("    hello"),
            .linebreak("\n", 2),
            .stringBody("    world"),
            .linebreak("\n", 3),
            .endOfScope("\"\"\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func emptyMultilineString() {
        let input = "\"\"\"\n\"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .endOfScope("\"\"\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineStringWithEscapedLinebreak() {
        let input = "\"\"\"\n    hello \\\n    world\n\"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("    hello \\"),
            .linebreak("\n", 2),
            .stringBody("    world"),
            .linebreak("\n", 3),
            .endOfScope("\"\"\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineStringStartingWithInterpolation() {
        let input = "    \"\"\"\n    \\(String(describing: 1))\n    \"\"\""
        let output: [Token] = [
            .space("    "),
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .space("    "),
            .stringBody("\\"),
            .startOfScope("("),
            .identifier("String"),
            .startOfScope("("),
            .identifier("describing"),
            .delimiter(":"),
            .space(" "),
            .number("1", .integer),
            .endOfScope(")"),
            .endOfScope(")"),
            .linebreak("\n", 2),
            .space("    "),
            .endOfScope("\"\"\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineStringWithMultilineInterpolation() {
        let input = """
        \"\""
        \\(
            6
        )
        \"\""
        """
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("\\"),
            .startOfScope("("),
            .linebreak("\n", 2),
            .space("    "),
            .number("6", .integer),
            .linebreak("\n", 3),
            .endOfScope(")"),
            .linebreak("\n", 4),
            .endOfScope("\"\"\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func indentMultilineStringWithMultilineNestedInterpolation() {
        let input = """
        \"\""
            foo
                \\(bar {
                    \"\""
                        baz
                    \"\""
                })
            quux
        \"\""
        """
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("    foo"),
            .linebreak("\n", 2),
            .stringBody("        \\"),
            .startOfScope("("),
            .identifier("bar"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 3),
            .space("            "),
            .startOfScope("\"\"\""),
            .linebreak("\n", 4),
            .space("            "),
            .stringBody("    baz"),
            .linebreak("\n", 5),
            .space("            "),
            .endOfScope("\"\"\""),
            .linebreak("\n", 6),
            .space("        "),
            .endOfScope("}"),
            .endOfScope(")"),
            .linebreak("\n", 7),
            .stringBody("    quux"),
            .linebreak("\n", 8),
            .endOfScope("\"\"\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func indentMultilineStringWithMultilineNestedInterpolation2() {
        let input = """
        \"\""
            foo
                \\(bar {
                    \"\""
                        baz
                    \"\""
                    }
                )
            quux
        \"\""
        """
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("    foo"),
            .linebreak("\n", 2),
            .stringBody("        \\"),
            .startOfScope("("),
            .identifier("bar"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 3),
            .space("            "),
            .startOfScope("\"\"\""),
            .linebreak("\n", 4),
            .space("            "),
            .stringBody("    baz"),
            .linebreak("\n", 5),
            .space("            "),
            .endOfScope("\"\"\""),
            .linebreak("\n", 6),
            .space("            "),
            .endOfScope("}"),
            .linebreak("\n", 7),
            .space("        "),
            .endOfScope(")"),
            .linebreak("\n", 8),
            .stringBody("    quux"),
            .linebreak("\n", 9),
            .endOfScope("\"\"\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineStringWithEscapedTripleQuote() {
        let input = "\"\"\"\n\\\"\"\"\n\"\"\""
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("\\\"\"\""),
            .linebreak("\n", 2),
            .endOfScope("\"\"\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineStringWithTrailingSpaceAfterQuotes() {
        let input = "\"\"\"   \n    hello \\\n\"\"\" "
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .space("   "),
            .linebreak("\n", 1),
            .stringBody("    hello \\"),
            .linebreak("\n", 2),
            .endOfScope("\"\"\""),
            .space(" "),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineStringWithBlankLines() {
        let input = """
        \"\"\"
        Test

        \"\"\"
        """
        let output: [Token] = [
            .startOfScope("\"\"\""),
            .linebreak("\n", 1),
            .stringBody("Test"),
            .linebreak("\n", 2),
            .stringBody(""),
            .linebreak("\n", 3),
            .endOfScope("\"\"\""),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: Raw strings

    @Test func emptyRawString() {
        let input = "#\"\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .endOfScope("\"#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func emptyDoubleRawString() {
        let input = "##\"\"##"
        let output: [Token] = [
            .startOfScope("##\""),
            .endOfScope("\"##"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func unbalancedRawString() {
        let input = "##\"\"#"
        let output: [Token] = [
            .startOfScope("##\""),
            .stringBody("\"#"),
            .error(""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func unbalancedRawString2() {
        let input = "#\"\"##"
        let output: [Token] = [
            .startOfScope("#\""),
            .endOfScope("\"#"),
            .error("#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rawStringContainingUnescapedQuote() {
        let input = "#\" \" \"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody(" \" "),
            .endOfScope("\"#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rawStringContainingJustASingleUnescapedQuote() {
        let input = "#\"\"\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody("\""),
            .endOfScope("\"#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rawStringContainingJustTwoUnescapedQuotes() {
        let input = "#\"\"\"\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody("\"\""),
            .endOfScope("\"#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rawStringContainingUnhashedBackslash() {
        let input = "#\"\\\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody("\\"),
            .endOfScope("\"#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rawStringContainingHashedEscapeSequence() {
        let input = "#\"\\#n\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody("\\#n"),
            .endOfScope("\"#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rawStringContainingUnderhashedEscapeSequence() {
        let input = "##\"\\#n\"##"
        let output: [Token] = [
            .startOfScope("##\""),
            .stringBody("\\#n"),
            .endOfScope("\"##"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rawStringContainingUnhashedInterpolation() {
        let input = "#\"\\(5)\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody("\\(5)"),
            .endOfScope("\"#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rawStringContainingHashedInterpolation() {
        let input = "#\"\\#(5)\"#"
        let output: [Token] = [
            .startOfScope("#\""),
            .stringBody("\\#"),
            .startOfScope("("),
            .number("5", .integer),
            .endOfScope(")"),
            .endOfScope("\"#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rawStringContainingUnderhashedInterpolation() {
        let input = "##\"\\#(5)\"##"
        let output: [Token] = [
            .startOfScope("##\""),
            .stringBody("\\#(5)"),
            .endOfScope("\"##"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: Multiline raw strings

    @Test func simpleMultilineRawString() {
        let input = "#\"\"\"\n    hello\n    world\n    \"\"\"#"
        let output: [Token] = [
            .startOfScope("#\"\"\""),
            .linebreak("\n", 1),
            .space("    "),
            .stringBody("hello"),
            .linebreak("\n", 2),
            .space("    "),
            .stringBody("world"),
            .linebreak("\n", 3),
            .space("    "),
            .endOfScope("\"\"\"#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineRawStringContainingUnhashedInterpolation() {
        let input = "#\"\"\"\n    \\(5)\n    \"\"\"#"
        let output: [Token] = [
            .startOfScope("#\"\"\""),
            .linebreak("\n", 1),
            .space("    "),
            .stringBody("\\(5)"),
            .linebreak("\n", 2),
            .space("    "),
            .endOfScope("\"\"\"#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineRawStringContainingHashedInterpolation() {
        let input = "#\"\"\"\n    \\#(5)\n    \"\"\"#"
        let output: [Token] = [
            .startOfScope("#\"\"\""),
            .linebreak("\n", 1),
            .space("    "),
            .stringBody("\\#"),
            .startOfScope("("),
            .number("5", .integer),
            .endOfScope(")"),
            .linebreak("\n", 2),
            .space("    "),
            .endOfScope("\"\"\"#"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineRawStringContainingUnderhashedInterpolation() {
        let input = "##\"\"\"\n    \\#(5)\n    \"\"\"##"
        let output: [Token] = [
            .startOfScope("##\"\"\""),
            .linebreak("\n", 1),
            .space("    "),
            .stringBody("\\#(5)"),
            .linebreak("\n", 2),
            .space("    "),
            .endOfScope("\"\"\"##"),
        ]
        #expect(tokenize(input) == output)
    }

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

    // MARK: Single-line comments

    @Test func singleLineComment() {
        let input = "//foo"
        let output: [Token] = [
            .startOfScope("//"),
            .commentBody("foo"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func singleLineCommentWithSpace() {
        let input = "// foo "
        let output: [Token] = [
            .startOfScope("//"),
            .space(" "),
            .commentBody("foo"),
            .space(" "),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func singleLineCommentWithLinebreak() {
        let input = "//foo\nbar"
        let output: [Token] = [
            .startOfScope("//"),
            .commentBody("foo"),
            .linebreak("\n", 1),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: Multiline comments

    @Test func singleLineMultilineComment() {
        let input = "/*foo*/"
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("foo"),
            .endOfScope("*/"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func singleLineMultilineCommentWithSpace() {
        let input = "/* foo */"
        let output: [Token] = [
            .startOfScope("/*"),
            .space(" "),
            .commentBody("foo"),
            .space(" "),
            .endOfScope("*/"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineComment() {
        let input = "/*foo\nbar*/"
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("foo"),
            .linebreak("\n", 1),
            .commentBody("bar"),
            .endOfScope("*/"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineCommentWithSpace() {
        let input = "/*foo\n  bar*/"
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("foo"),
            .linebreak("\n", 1),
            .space("  "),
            .commentBody("bar"),
            .endOfScope("*/"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func commentIndentingWithTrailingClose() {
        let input = "/* foo\n */"
        let output: [Token] = [
            .startOfScope("/*"),
            .space(" "),
            .commentBody("foo"),
            .linebreak("\n", 1),
            .space(" "),
            .endOfScope("*/"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func nestedComments() {
        let input = "/*foo/*bar*/baz*/"
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("foo"),
            .startOfScope("/*"),
            .commentBody("bar"),
            .endOfScope("*/"),
            .commentBody("baz"),
            .endOfScope("*/"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func nestedCommentsWithSpace() {
        let input = "/* foo /* bar */ baz */"
        let output: [Token] = [
            .startOfScope("/*"),
            .space(" "),
            .commentBody("foo"),
            .space(" "),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("bar"),
            .space(" "),
            .endOfScope("*/"),
            .space(" "),
            .commentBody("baz"),
            .space(" "),
            .endOfScope("*/"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func preformattedMultilineComment() {
        let input = """
        /*
         func foo() {
           if bar {
             print(baz)
           }
         }
         */
        """
        let output: [Token] = [
            .startOfScope("/*"),
            .linebreak("\n", 1),
            .space(" "),
            .commentBody("func foo() {"),
            .linebreak("\n", 2),
            .space(" "),
            .commentBody("  if bar {"),
            .linebreak("\n", 3),
            .space(" "),
            .commentBody("    print(baz)"),
            .linebreak("\n", 4),
            .space(" "),
            .commentBody("  }"),
            .linebreak("\n", 5),
            .space(" "),
            .commentBody("}"),
            .linebreak("\n", 6),
            .space(" "),
            .endOfScope("*/"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func preformattedMultilineComment2() {
        let input = """
        /**
        func foo() {
            bar()
        }
        */
        """
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("*"),
            .linebreak("\n", 1),
            .commentBody("func foo() {"),
            .linebreak("\n", 2),
            .commentBody("    bar()"),
            .linebreak("\n", 3),
            .commentBody("}"),
            .linebreak("\n", 4),
            .endOfScope("*/"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func indentedNestedMultilineComment() {
        let input = """
        /*
         func foo() {
             /*
              * Nested comment
              */
             bar {}
         }
         */
        """
        let output: [Token] = [
            .startOfScope("/*"),
            .linebreak("\n", 1),
            .space(" "),
            .commentBody("func foo() {"),
            .linebreak("\n", 2),
            .space(" "),
            .commentBody("    "),
            .startOfScope("/*"),
            .linebreak("\n", 3),
            .space(" "),
            .commentBody("     * Nested comment"),
            .linebreak("\n", 4),
            .space(" "),
            .commentBody("     "),
            .endOfScope("*/"),
            .linebreak("\n", 5),
            .space(" "),
            .commentBody("    bar {}"),
            .linebreak("\n", 6),
            .space(" "),
            .commentBody("}"),
            .linebreak("\n", 7),
            .space(" "),
            .endOfScope("*/"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: Numbers

    @Test func zero() {
        let input = "0"
        let output: [Token] = [.number("0", .integer)]
        #expect(tokenize(input) == output)
    }

    @Test func smallInteger() {
        let input = "5"
        let output: [Token] = [.number("5", .integer)]
        #expect(tokenize(input) == output)
    }

    @Test func largeInteger() {
        let input = "12345678901234567890"
        let output: [Token] = [.number("12345678901234567890", .integer)]
        #expect(tokenize(input) == output)
    }

    @Test func negativeInteger() {
        let input = "-7"
        let output: [Token] = [
            .operator("-", .prefix),
            .number("7", .integer),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func invalidInteger() {
        let input = "123abc"
        let output: [Token] = [
            .number("123", .integer),
            .error("abc"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func smallFloat() {
        let input = "0.2"
        let output: [Token] = [.number("0.2", .decimal)]
        #expect(tokenize(input) == output)
    }

    @Test func largeFloat() {
        let input = "1234.567890"
        let output: [Token] = [.number("1234.567890", .decimal)]
        #expect(tokenize(input) == output)
    }

    @Test func negativeFloat() {
        let input = "-0.34"
        let output: [Token] = [
            .operator("-", .prefix),
            .number("0.34", .decimal),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func exponential() {
        let input = "1234e5"
        let output: [Token] = [.number("1234e5", .decimal)]
        #expect(tokenize(input) == output)
    }

    @Test func positiveExponential() {
        let input = "0.123e+4"
        let output: [Token] = [.number("0.123e+4", .decimal)]
        #expect(tokenize(input) == output)
    }

    @Test func negativeExponential() {
        let input = "0.123e-4"
        let output: [Token] = [.number("0.123e-4", .decimal)]
        #expect(tokenize(input) == output)
    }

    @Test func capitalExponential() {
        let input = "0.123E-4"
        let output: [Token] = [.number("0.123E-4", .decimal)]
        #expect(tokenize(input) == output)
    }

    @Test func invalidExponential() {
        let input = "123.e5"
        let output: [Token] = [
            .number("123", .integer),
            .operator(".", .infix),
            .identifier("e5"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func leadingZeros() {
        let input = "0005"
        let output: [Token] = [.number("0005", .integer)]
        #expect(tokenize(input) == output)
    }

    @Test func binary() {
        let input = "0b101010"
        let output: [Token] = [.number("0b101010", .binary)]
        #expect(tokenize(input) == output)
    }

    @Test func octal() {
        let input = "0o52"
        let output: [Token] = [.number("0o52", .octal)]
        #expect(tokenize(input) == output)
    }

    @Test func hex() {
        let input = "0x2A"
        let output: [Token] = [.number("0x2A", .hex)]
        #expect(tokenize(input) == output)
    }

    @Test func hexadecimalPower() {
        let input = "0xC3p0"
        let output: [Token] = [.number("0xC3p0", .hex)]
        #expect(tokenize(input) == output)
    }

    @Test func capitalHexadecimalPower() {
        let input = "0xC3P0"
        let output: [Token] = [.number("0xC3P0", .hex)]
        #expect(tokenize(input) == output)
    }

    @Test func negativeHexadecimalPower() {
        let input = "0xC3p-5"
        let output: [Token] = [.number("0xC3p-5", .hex)]
        #expect(tokenize(input) == output)
    }

    @Test func floatHexadecimalPower() {
        let input = "0xC.3p0"
        let output: [Token] = [.number("0xC.3p0", .hex)]
        #expect(tokenize(input) == output)
    }

    @Test func floatNegativeHexadecimalPower() {
        let input = "0xC.3p-5"
        let output: [Token] = [.number("0xC.3p-5", .hex)]
        #expect(tokenize(input) == output)
    }

    @Test func underscoresInInteger() {
        let input = "1_23_4_"
        let output: [Token] = [.number("1_23_4_", .integer)]
        #expect(tokenize(input) == output)
    }

    @Test func underscoresInFloat() {
        let input = "0_.1_2_"
        let output: [Token] = [.number("0_.1_2_", .decimal)]
        #expect(tokenize(input) == output)
    }

    @Test func underscoresInExponential() {
        let input = "0.1_2_e-3"
        let output: [Token] = [.number("0.1_2_e-3", .decimal)]
        #expect(tokenize(input) == output)
    }

    @Test func underscoresInBinary() {
        let input = "0b0000_0000_0001"
        let output: [Token] = [.number("0b0000_0000_0001", .binary)]
        #expect(tokenize(input) == output)
    }

    @Test func underscoresInOctal() {
        let input = "0o123_456"
        let output: [Token] = [.number("0o123_456", .octal)]
        #expect(tokenize(input) == output)
    }

    @Test func underscoresInHex() {
        let input = "0xabc_def"
        let output: [Token] = [.number("0xabc_def", .hex)]
        #expect(tokenize(input) == output)
    }

    @Test func underscoresInHexadecimalPower() {
        let input = "0xabc_p5"
        let output: [Token] = [.number("0xabc_p5", .hex)]
        #expect(tokenize(input) == output)
    }

    @Test func underscoresInFloatHexadecimalPower() {
        let input = "0xa.bc_p5"
        let output: [Token] = [.number("0xa.bc_p5", .hex)]
        #expect(tokenize(input) == output)
    }

    @Test func noLeadingUnderscoreInInteger() {
        let input = "_12345"
        let output: [Token] = [.identifier("_12345")]
        #expect(tokenize(input) == output)
    }

    @Test func noLeadingUnderscoreInHex() {
        let input = "0x_12345"
        let output: [Token] = [.error("0x_12345")]
        #expect(tokenize(input) == output)
    }

    @Test func hexPropertyAccess() {
        let input = "0x123.ee"
        let output: [Token] = [
            .number("0x123", .hex),
            .operator(".", .infix),
            .identifier("ee"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func invalidHexadecimal() {
        let input = "0x123.0"
        let output: [Token] = [
            .error("0x123.0"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func anotherInvalidHexadecimal() {
        let input = "0x123.0p"
        let output: [Token] = [
            .error("0x123.0p"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func invalidOctal() {
        let input = "0o1235678"
        let output: [Token] = [
            .number("0o123567", .octal),
            .error("8"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: Identifiers & keywords

    @Test func foo() {
        let input = "foo"
        let output: [Token] = [.identifier("foo")]
        #expect(tokenize(input) == output)
    }

    @Test func dollar0() {
        let input = "$0"
        let output: [Token] = [.identifier("$0")]
        #expect(tokenize(input) == output)
    }

    @Test func dollar() {
        // Note: support for this is deprecated in Swift 3
        let input = "$"
        let output: [Token] = [.identifier("$")]
        #expect(tokenize(input) == output)
    }

    @Test func fooDollar() {
        let input = "foo$"
        let output: [Token] = [.identifier("foo$")]
        #expect(tokenize(input) == output)
    }

    @Test func underscore() {
        let input = "_"
        let output: [Token] = [.identifier("_")]
        #expect(tokenize(input) == output)
    }

    @Test func underscoreFoo() {
        let input = "_foo"
        let output: [Token] = [.identifier("_foo")]
        #expect(tokenize(input) == output)
    }

    @Test func foo_bar() {
        let input = "foo_bar"
        let output: [Token] = [.identifier("foo_bar")]
        #expect(tokenize(input) == output)
    }

    @Test func atFoo() {
        let input = "@foo"
        let output: [Token] = [.keyword("@foo")]
        #expect(tokenize(input) == output)
    }

    @Test func hashFoo() {
        let input = "#foo"
        let output: [Token] = [.keyword("#foo")]
        #expect(tokenize(input) == output)
    }

    @Test func unicode() {
        let input = "µsec"
        let output: [Token] = [.identifier("µsec")]
        #expect(tokenize(input) == output)
    }

    #if os(macOS)
    @Test func emoji() {
        let input = "🙃"
        let output: [Token] = [.identifier("🙃")]
        #expect(tokenize(input) == output)
    }
    #endif

    @Test func backtickEscapedClass() {
        let input = "`class`"
        let output: [Token] = [.identifier("`class`")]
        #expect(tokenize(input) == output)
    }

    @Test func dotPrefixedKeyword() {
        let input = ".default"
        let output: [Token] = [
            .operator(".", .prefix),
            .identifier("default"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func namespacedAttribute() {
        let input = "@OuterType.Wrapper"
        let output: [Token] = [
            .keyword("@OuterType"),
            .operator(".", .infix),
            .identifier("Wrapper"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func attributeArguments() {
        let input = "@derivative(of: subscript.get)"
        let output: [Token] = [
            .keyword("@derivative"),
            .startOfScope("("),
            .identifier("of"),
            .delimiter(":"),
            .space(" "),
            .identifier("subscript"),
            .operator(".", .infix),
            .identifier("get"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordsAsArgumentLabelNames() {
        let input = "foo(for: bar, if: baz)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("("),
            .identifier("for"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .delimiter(","),
            .space(" "),
            .identifier("if"),
            .delimiter(":"),
            .space(" "),
            .identifier("baz"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordsAsArgumentLabelNames2() {
        let input = "foo(case: bar, default: baz)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("("),
            .identifier("case"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .delimiter(","),
            .space(" "),
            .identifier("default"),
            .delimiter(":"),
            .space(" "),
            .identifier("baz"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordsAsArgumentLabelNames3() {
        let input = "foo(switch: bar, case: baz)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("("),
            .identifier("switch"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .delimiter(","),
            .space(" "),
            .identifier("case"),
            .delimiter(":"),
            .space(" "),
            .identifier("baz"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordAsInternalArgumentLabelName() {
        let input = "func foo(all in: Array)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("all"),
            .space(" "),
            .identifier("in"),
            .delimiter(":"),
            .space(" "),
            .identifier("Array"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordAsExternalArgumentLabelName() {
        let input = "func foo(in array: Array)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("in"),
            .space(" "),
            .identifier("array"),
            .delimiter(":"),
            .space(" "),
            .identifier("Array"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordAsBothArgumentLabelNames() {
        let input = "func foo(for in: Array)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("for"),
            .space(" "),
            .identifier("in"),
            .delimiter(":"),
            .space(" "),
            .identifier("Array"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordAsSubscriptLabels() {
        let input = "foo[for: bar]"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("["),
            .identifier("for"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .endOfScope("]"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordAsClosureLabel() {
        let input = "foo.if(bar) { bar } else: { baz }"
        let output: [Token] = [
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("if"),
            .startOfScope("("),
            .identifier("bar"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .identifier("bar"),
            .space(" "),
            .endOfScope("}"),
            .space(" "),
            .identifier("else"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .identifier("baz"),
            .space(" "),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func numberedTupleVariableMember() {
        let input = "foo.2"
        let output: [Token] = [
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("2"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func numberedTupleExpressionMember() {
        let input = "(1,2).1"
        let output: [Token] = [
            .startOfScope("("),
            .number("1", .integer),
            .delimiter(","),
            .number("2", .integer),
            .endOfScope(")"),
            .operator(".", .infix),
            .identifier("1"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func xcodeToken() {
        let input = """
        test(image: <#T##UIImage#>)
        """
        let output: [Token] = [
            .identifier("test"),
            .startOfScope("("),
            .identifier("image"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##UIImage#>"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func xcodeWithArrayAndClosureToken() {
        let input = """
        monkey(smelly: <#T##Bool#>, happy: <#T##Bool#>, names: <#T##[String]#>, throw💩: <#T##((Int) -> Void)##((Int) -> Void)##(Int) -> Void#>)
        """
        let output: [Token] = [
            .identifier("monkey"),
            .startOfScope("("),
            .identifier("smelly"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##Bool#>"),
            .delimiter(","),
            .space(" "),
            .identifier("happy"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##Bool#>"),
            .delimiter(","),
            .space(" "),
            .identifier("names"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##[String]#>"),
            .delimiter(","),
            .space(" "),
            .identifier("throw💩"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##((Int) -> Void)##((Int) -> Void)##(Int) -> Void#>"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: Operators

    @Test func basicOperator() {
        let input = "+="
        let output: [Token] = [.operator("+=", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func divide() {
        let input = "a / b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("/", .infix),
            .space(" "),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func customOperator() {
        let input = "~="
        let output: [Token] = [.operator("~=", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func customOperator2() {
        let input = "a <> b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("<>", .infix),
            .space(" "),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func customOperator3() {
        let input = "a |> b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("|>", .infix),
            .space(" "),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func customOperator4() {
        let input = "a <<>> b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("<<>>", .infix),
            .space(" "),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func sequentialOperators() {
        let input = "a *= -b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("*=", .infix),
            .space(" "),
            .operator("-", .prefix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func dotPrefixedOperator() {
        let input = "..."
        let output: [Token] = [.operator("...", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func angleBracketSuffixedOperator() {
        let input = "..<"
        let output: [Token] = [.operator("..<", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func angleBracketSuffixedOperator2() {
        let input = "a..<b"
        let output: [Token] = [
            .identifier("a"),
            .operator("..<", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func unicodeOperator() {
        let input = "≥"
        let output: [Token] = [.operator("≥", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func operatorFollowedByComment() {
        let input = "a+/* b */b"
        let output: [Token] = [
            .identifier("a"),
            .operator("+", .postfix),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("b"),
            .space(" "),
            .endOfScope("*/"),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func operatorPrecededBySpaceFollowedByComment() {
        let input = "a +/* b */b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("+", .infix),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("b"),
            .space(" "),
            .endOfScope("*/"),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func operatorPrecededByComment() {
        let input = "a/* a */-b"
        let output: [Token] = [
            .identifier("a"),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("a"),
            .space(" "),
            .endOfScope("*/"),
            .operator("-", .prefix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func operatorPrecededByCommentFollowedBySpace() {
        let input = "a/* a */- b"
        let output: [Token] = [
            .identifier("a"),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("a"),
            .space(" "),
            .endOfScope("*/"),
            .operator("-", .infix),
            .space(" "),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func operatorMayContainDotIfStartsWithDot() {
        let input = ".*.."
        let output: [Token] = [.operator(".*..", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func operatorMayNotContainDotUnlessStartsWithDot() {
        let input = "*.."
        let output: [Token] = [
            .operator("*", .prefix), // TODO: should be postfix
            .operator("..", .none),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func operatorStitchingDoesNotCreateIllegalToken() {
        let input = "a*..b"
        let output: [Token] = [
            .identifier("a"),
            .operator("*", .postfix),
            .operator("..", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func nullCoalescingOperator() {
        let input = "foo ?? bar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("??", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func ternary() {
        let input = "a ? b() : c"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("?", .infix),
            .space(" "),
            .identifier("b"),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .operator(":", .infix),
            .space(" "),
            .identifier("c"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func ternaryWithOddSpacing() {
        let input = "a ?b(): c"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("?", .infix),
            .identifier("b"),
            .startOfScope("("),
            .endOfScope(")"),
            .operator(":", .infix),
            .space(" "),
            .identifier("c"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixOperatorBeforeLinebreak() {
        let input = "foo +\nbar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("+", .infix),
            .linebreak("\n", 1),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixOperatorAfterLinebreak() {
        let input = "foo\n+ bar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\n", 1),
            .operator("+", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixOperatorBeforeComment() {
        let input = "foo +/**/bar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("+", .infix),
            .startOfScope("/*"),
            .endOfScope("*/"),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixOperatorAfterComment() {
        let input = "foo/**/+ bar"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("/*"),
            .endOfScope("*/"),
            .operator("+", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func prefixMinusBeforeMember() {
        let input = "-.foo"
        let output: [Token] = [
            .operator("-", .prefix),
            .operator(".", .prefix),
            .identifier("foo"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixMinusBeforeMember() {
        let input = "foo - .bar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("-", .infix),
            .space(" "),
            .operator(".", .prefix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func postfixOperatorBeforeMember() {
        let input = "foo′.bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("′", .postfix),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func notOperator() {
        let input = "!foo"
        let output: [Token] = [
            .operator("!", .prefix),
            .identifier("foo"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func notOperatorAfterKeyword() {
        let input = "return !foo"
        let output: [Token] = [
            .keyword("return"),
            .space(" "),
            .operator("!", .prefix),
            .identifier("foo"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func stringDotMethod() {
        let input = "\"foo\".isEmpty"
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("foo"),
            .endOfScope("\""),
            .operator(".", .infix),
            .identifier("isEmpty"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func stringAssignment() {
        let input = "foo = \"foo\""
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("\""),
            .stringBody("foo"),
            .endOfScope("\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixNotEqualsInParens() {
        let input = "(!=)"
        let output: [Token] = [
            .startOfScope("("),
            .operator("!=", .none),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: chevrons (might be operators or generics)

    @Test func lessThanGreaterThan() {
        let input = "a<b == a>c"
        let output: [Token] = [
            .identifier("a"),
            .operator("<", .infix),
            .identifier("b"),
            .space(" "),
            .operator("==", .infix),
            .space(" "),
            .identifier("a"),
            .operator(">", .infix),
            .identifier("c"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func lessThanGreaterThanFollowedByOperator() {
        let input = "a > -x, a<x, b > -y, b<y"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .operator("-", .prefix),
            .identifier("x"),
            .delimiter(","),
            .space(" "),
            .identifier("a"),
            .operator("<", .infix),
            .identifier("x"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .operator("-", .prefix),
            .identifier("y"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .operator("<", .infix),
            .identifier("y"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericTypeAmpersandProtocol() {
        let input = "Foo<Int> & Bar"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Int"),
            .endOfScope(">"),
            .space(" "),
            .operator("&", .infix),
            .space(" "),
            .identifier("Bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func customChevronOperatorFollowedByParen() {
        let input = "foo <?> (bar)"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("<?>", .infix),
            .space(" "),
            .startOfScope("("),
            .identifier("bar"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rightShift() {
        let input = "a>>b"
        let output: [Token] = [
            .identifier("a"),
            .operator(">>", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func leftShift() {
        let input = "a<<b"
        let output: [Token] = [
            .identifier("a"),
            .operator("<<", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func tripleShift() {
        let input = "a>>>b"
        let output: [Token] = [
            .identifier("a"),
            .operator(">>>", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rightShiftEquals() {
        let input = "a>>=b"
        let output: [Token] = [
            .identifier("a"),
            .operator(">>=", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func leftShiftInsideTernary() {
        let input = "foo ? bar<<24 : 0"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("?", .infix),
            .space(" "),
            .identifier("bar"),
            .operator("<<", .infix),
            .number("24", .integer),
            .space(" "),
            .operator(":", .infix),
            .space(" "),
            .number("0", .integer),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func bitshiftThatLooksLikeAGeneric() {
        let input = "a<b, b<c, d>>e"
        let output: [Token] = [
            .identifier("a"),
            .operator("<", .infix),
            .identifier("b"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .operator("<", .infix),
            .identifier("c"),
            .delimiter(","),
            .space(" "),
            .identifier("d"),
            .operator(">>", .infix),
            .identifier("e"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func basicGeneric() {
        let input = "Foo<Bar, Baz>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .delimiter(","),
            .space(" "),
            .identifier("Baz"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func nestedGenerics() {
        let input = "Foo<Bar<Baz>>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .startOfScope("<"),
            .identifier("Baz"),
            .endOfScope(">"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func parameterPackGeneric() {
        let input = "Optional<(Wrapped, Other, repeat each Another)>"
        let output: [Token] = [
            .identifier("Optional"),
            .startOfScope("<"),
            .startOfScope("("),
            .identifier("Wrapped"),
            .delimiter(","),
            .space(" "),
            .identifier("Other"),
            .delimiter(","),
            .space(" "),
            .keyword("repeat"),
            .space(" "),
            .identifier("each"),
            .space(" "),
            .identifier("Another"),
            .endOfScope(")"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func functionThatLooksLikeGenericType() {
        let input = "y<CGRectGetMaxY(r)"
        let output: [Token] = [
            .identifier("y"),
            .operator("<", .infix),
            .identifier("CGRectGetMaxY"),
            .startOfScope("("),
            .identifier("r"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericClassDeclaration() {
        let input = "class Foo<T,U> {}"
        let output: [Token] = [
            .keyword("class"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .endOfScope(">"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericSubclassDeclaration() {
        let input = "class Foo<T,U>: Bar"
        let output: [Token] = [
            .keyword("class"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .endOfScope(">"),
            .delimiter(":"),
            .space(" "),
            .identifier("Bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericFunctionDeclaration() {
        let input = "func foo<T>(bar:T)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .startOfScope("("),
            .identifier("bar"),
            .delimiter(":"),
            .identifier("T"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericClassInit() {
        let input = "foo = Foo<Int,String>()"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Int"),
            .delimiter(","),
            .identifier("String"),
            .endOfScope(">"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericFollowedByDot() {
        let input = "Foo<Bar>.baz()"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .endOfScope(">"),
            .operator(".", .infix),
            .identifier("baz"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func constantThatLooksLikeGenericType() {
        let input = "(y<Pi)"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("y"),
            .operator("<", .infix),
            .identifier("Pi"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func tupleOfBoolsThatLooksLikeGeneric() {
        let input = "(Foo<T,U>V)"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("Foo"),
            .operator("<", .infix),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .operator(">", .infix),
            .identifier("V"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func tupleOfBoolsThatReallyLooksLikeGeneric() {
        let input = "(Foo<T,U>=V)"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("Foo"),
            .operator("<", .infix),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .operator(">=", .infix),
            .identifier("V"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericDeclarationThatLooksLikeTwoExpressions() {
        let input = "let d: a < b, b > = c"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("d"),
            .delimiter(":"),
            .space(" "),
            .identifier("a"),
            .space(" "),
            .startOfScope("<"),
            .space(" "),
            .identifier("b"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .space(" "),
            .endOfScope(">"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("c"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericDeclarationWithoutSpace() {
        let input = "let foo: Foo<String,Int>=[]"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .delimiter(":"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("String"),
            .delimiter(","),
            .identifier("Int"),
            .endOfScope(">"),
            .operator("=", .infix),
            .startOfScope("["),
            .endOfScope("]"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericClassInitThatLooksLikeTuple() {
        let input = "(Foo<String,Int>(Bar))"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("String"),
            .delimiter(","),
            .identifier("Int"),
            .endOfScope(">"),
            .startOfScope("("),
            .identifier("Bar"),
            .endOfScope(")"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func customChevronOperatorThatLooksLikeGeneric() {
        let input = "Foo<Bar,Baz>>>5"
        let output: [Token] = [
            .identifier("Foo"),
            .operator("<", .infix),
            .identifier("Bar"),
            .delimiter(","),
            .identifier("Baz"),
            .operator(">>>", .infix),
            .number("5", .integer),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func chevronOperatorDoesNotBreakScopeStack() {
        let input = "if a << b != 0 { let foo = bar() }"
        let output: [Token] = [
            .keyword("if"),
            .space(" "),
            .identifier("a"),
            .space(" "),
            .operator("<<", .infix),
            .space(" "),
            .identifier("b"),
            .space(" "),
            .operator("!=", .infix),
            .space(" "),
            .number("0", .integer),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("bar"),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericAsFunctionType() {
        let input = "Foo<Bar,Baz>->Void"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .delimiter(","),
            .identifier("Baz"),
            .endOfScope(">"),
            .operator("->", .infix),
            .identifier("Void"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericContainingFunctionType() {
        let input = "Foo<(Bar)->Baz>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("("),
            .identifier("Bar"),
            .endOfScope(")"),
            .operator("->", .infix),
            .identifier("Baz"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericContainingFunctionTypeWithMultipleArguments() {
        let input = "Foo<(Bar,Baz)->Quux>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("("),
            .identifier("Bar"),
            .delimiter(","),
            .identifier("Baz"),
            .endOfScope(")"),
            .operator("->", .infix),
            .identifier("Quux"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericContainingMultipleFunctionTypes() {
        let input = "Foo<(Bar)->Void,(Baz)->Void>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("("),
            .identifier("Bar"),
            .endOfScope(")"),
            .operator("->", .infix),
            .identifier("Void"),
            .delimiter(","),
            .startOfScope("("),
            .identifier("Baz"),
            .endOfScope(")"),
            .operator("->", .infix),
            .identifier("Void"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericContainingArrayType() {
        let input = "Foo<[Bar],Baz>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("["),
            .identifier("Bar"),
            .endOfScope("]"),
            .delimiter(","),
            .identifier("Baz"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericContainingTupleType() {
        let input = "Foo<(Bar,Baz)>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("("),
            .identifier("Bar"),
            .delimiter(","),
            .identifier("Baz"),
            .endOfScope(")"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericContainingArrayAndTupleType() {
        let input = "Foo<[Bar],(Baz)>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("["),
            .identifier("Bar"),
            .endOfScope("]"),
            .delimiter(","),
            .startOfScope("("),
            .identifier("Baz"),
            .endOfScope(")"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericFollowedByIn() {
        let input = "Foo<Bar,Baz> in"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .delimiter(","),
            .identifier("Baz"),
            .endOfScope(">"),
            .space(" "),
            .keyword("in"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func optionalGenericType() {
        let input = "Foo<T?,U>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .operator("?", .postfix),
            .delimiter(","),
            .identifier("U"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func trailingOptionalGenericType() {
        let input = "Foo<T?>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .operator("?", .postfix),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func nestedOptionalGenericType() {
        let input = "Foo<Bar<T?>>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .startOfScope("<"),
            .identifier("T"),
            .operator("?", .postfix),
            .endOfScope(">"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func deeplyNestedGenericType() {
        let input = "Foo<Bar<Baz<Quux>>>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .startOfScope("<"),
            .identifier("Baz"),
            .startOfScope("<"),
            .identifier("Quux"),
            .endOfScope(">"),
            .endOfScope(">"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericFollowedByGreaterThan() {
        let input = "Foo<T>\na=b>c"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .linebreak("\n", 1),
            .identifier("a"),
            .operator("=", .infix),
            .identifier("b"),
            .operator(">", .infix),
            .identifier("c"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericFollowedByElipsis() {
        let input = "foo<T>(bar: Baz<T>...)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .startOfScope("("),
            .identifier("bar"),
            .delimiter(":"),
            .space(" "),
            .identifier("Baz"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .operator("...", .postfix),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericOperatorFunction() {
        let input = "func ==<T>()"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .operator("==", .none),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericCustomOperatorFunction() {
        let input = "func ∘<T,U>()"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .operator("∘", .none),
            .startOfScope("<"),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .endOfScope(">"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericTypeContainingAmpersand() {
        let input = "Foo<Bar: Baz & Quux>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .delimiter(":"),
            .space(" "),
            .identifier("Baz"),
            .space(" "),
            .operator("&", .infix),
            .space(" "),
            .identifier("Quux"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericTypeFollowedByAndOperator() {
        let input = "Foo<Bar> && baz"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .endOfScope(">"),
            .space(" "),
            .operator("&&", .infix),
            .space(" "),
            .identifier("baz"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func customOperatorStartingWithOpenChevron() {
        let input = "foo<--bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("<--", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func customOperatorEndingWithCloseChevron() {
        let input = "foo-->bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("-->", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func greaterThanLessThanOperator() {
        let input = "foo><bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("><", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func lessThanGreaterThanOperator() {
        let input = "foo<>bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("<>", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericFollowedByAssign() {
        let input = "let foo: Bar<Baz> = 5"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .delimiter(":"),
            .space(" "),
            .identifier("Bar"),
            .startOfScope("<"),
            .identifier("Baz"),
            .endOfScope(">"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .number("5", .integer),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericInFailableInit() {
        let input = "init?<T>()"
        let output: [Token] = [
            .keyword("init"),
            .operator("?", .postfix),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixEqualsOperatorWithSpace() {
        let input = "operator == {}"
        let output: [Token] = [
            .keyword("operator"),
            .space(" "),
            .operator("==", .none),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixEqualsOperatorWithoutSpace() {
        let input = "operator =={}"
        let output: [Token] = [
            .keyword("operator"),
            .space(" "),
            .operator("==", .none),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixQuestionMarkChevronOperatorWithSpace() {
        let input = "operator ?< {}"
        let output: [Token] = [
            .keyword("operator"),
            .space(" "),
            .operator("?<", .none),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixQuestionMarkChevronOperatorWithoutSpace() {
        let input = "operator ?<{}"
        let output: [Token] = [
            .keyword("operator"),
            .space(" "),
            .operator("?<", .none),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixEqualsDoubleChevronOperator() {
        let input = "infix operator =<<"
        let output: [Token] = [
            .identifier("infix"),
            .space(" "),
            .keyword("operator"),
            .space(" "),
            .operator("=<<", .none),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixEqualsDoubleChevronGenericFunction() {
        let input = "func =<<<T>()"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .operator("=<<", .none),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func halfOpenRangeFollowedByComment() {
        let input = "1..<5\n//comment"
        let output: [Token] = [
            .number("1", .integer),
            .operator("..<", .infix),
            .number("5", .integer),
            .linebreak("\n", 1),
            .startOfScope("//"),
            .commentBody("comment"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func sortAscending() {
        let input = "sort(by: <)"
        let output: [Token] = [
            .identifier("sort"),
            .startOfScope("("),
            .identifier("by"),
            .delimiter(":"),
            .space(" "),
            .operator("<", .none),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func sortDescending() {
        let input = "sort(by: >)"
        let output: [Token] = [
            .identifier("sort"),
            .startOfScope("("),
            .identifier("by"),
            .delimiter(":"),
            .space(" "),
            .operator(">", .none),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func ifLessThanGreaterThanExpression() {
        let input = "if x < (y + z), y > (z * w) {}"
        let output: [Token] = [
            .keyword("if"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .operator("<", .infix),
            .space(" "),
            .startOfScope("("),
            .identifier("y"),
            .space(" "),
            .operator("+", .infix),
            .space(" "),
            .identifier("z"),
            .endOfScope(")"),
            .delimiter(","),
            .space(" "),
            .identifier("y"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .startOfScope("("),
            .identifier("z"),
            .space(" "),
            .operator("*", .infix),
            .space(" "),
            .identifier("w"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func ifLessThanIfGreaterThan() {
        let input = "if x < 0 {}\nif y > (0) {}"
        let output: [Token] = [
            .keyword("if"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .operator("<", .infix),
            .space(" "),
            .number("0", .integer),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
            .linebreak("\n", 1),
            .keyword("if"),
            .space(" "),
            .identifier("y"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .startOfScope("("),
            .number("0", .integer),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func lessThanEnumCase() {
        let input = "XCTAssertFalse(.never < .never)"
        let output: [Token] = [
            .identifier("XCTAssertFalse"),
            .startOfScope("("),
            .operator(".", .prefix),
            .identifier("never"),
            .space(" "),
            .operator("<", .infix),
            .space(" "),
            .operator(".", .prefix),
            .identifier("never"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func lessThanGreaterThanEnumCase() {
        let input = "if foo < .bar, baz > .quux"
        let output: [Token] = [
            .keyword("if"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("<", .infix),
            .space(" "),
            .operator(".", .prefix),
            .identifier("bar"),
            .delimiter(","),
            .space(" "),
            .identifier("baz"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .operator(".", .prefix),
            .identifier("quux"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericResultBuilder() {
        let input = "func foo(@SomeResultBuilder<Self> builder: () -> Void) {}"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .keyword("@SomeResultBuilder"),
            .startOfScope("<"),
            .identifier("Self"),
            .endOfScope(">"),
            .space(" "),
            .identifier("builder"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .operator("->", .infix),
            .space(" "),
            .identifier("Void"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericResultBuilder2() {
        let input = "func foo(@SomeResultBuilder<Store<MainState>> builder: () -> Void) {}"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .keyword("@SomeResultBuilder"),
            .startOfScope("<"),
            .identifier("Store"),
            .startOfScope("<"),
            .identifier("MainState"),
            .endOfScope(">"),
            .endOfScope(">"),
            .space(" "),
            .identifier("builder"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .operator("->", .infix),
            .space(" "),
            .identifier("Void"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericThrowingClosure() {
        let input = "let a = Thing<[(Int) throws -> [Int]]>([])"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("a"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("Thing"),
            .startOfScope("<"),
            .startOfScope("["),
            .startOfScope("("),
            .identifier("Int"),
            .endOfScope(")"),
            .space(" "),
            .keyword("throws"),
            .space(" "),
            .operator("->", .infix),
            .space(" "),
            .startOfScope("["),
            .identifier("Int"),
            .endOfScope("]"),
            .endOfScope("]"),
            .endOfScope(">"),
            .startOfScope("("),
            .startOfScope("["),
            .endOfScope("]"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: optionals

    @Test func assignOptional() {
        let input = "Int?=nil"
        let output: [Token] = [
            .identifier("Int"),
            .operator("?", .postfix),
            .operator("=", .infix),
            .identifier("nil"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func questionMarkEqualOperator() {
        let input = "foo ?= bar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("?=", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func optionalChaining() {
        let input = "foo!.bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("!", .postfix),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multipleOptionalChaining() {
        let input = "foo?!?.bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("?", .postfix),
            .operator("!", .postfix),
            .operator("?", .postfix),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func splitLineOptionalChaining() {
        let input = "foo?\n    .bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("?", .postfix),
            .linebreak("\n", 1),
            .space("    "),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: case statements

    @Test func singleLineEnum() {
        let input = "enum Foo {case Bar, Baz}"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .keyword("case"),
            .space(" "),
            .identifier("Bar"),
            .delimiter(","),
            .space(" "),
            .identifier("Baz"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func singleLineGenericEnum() {
        let input = "enum Foo<T> {case Bar, Baz}"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .space(" "),
            .startOfScope("{"),
            .keyword("case"),
            .space(" "),
            .identifier("Bar"),
            .delimiter(","),
            .space(" "),
            .identifier("Baz"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func multilineLineEnum() {
        let input = "enum Foo {\ncase Bar\ncase Baz\n}"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .keyword("case"),
            .space(" "),
            .identifier("Bar"),
            .linebreak("\n", 2),
            .keyword("case"),
            .space(" "),
            .identifier("Baz"),
            .linebreak("\n", 3),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchStatement() {
        let input = "switch x {\ncase 1:\nbreak\ncase 2:\nbreak\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("break"),
            .linebreak("\n", 3),
            .endOfScope("case"),
            .space(" "),
            .number("2", .integer),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 6),
            .keyword("break"),
            .linebreak("\n", 7),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchStatementWithEnumCases() {
        let input = "switch x {\ncase.foo,\n.bar:\nbreak\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .operator(".", .prefix),
            .identifier("foo"),
            .delimiter(","),
            .linebreak("\n", 2),
            .operator(".", .prefix),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n", 3),
            .keyword("break"),
            .linebreak("\n", 4),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 5),
            .keyword("break"),
            .linebreak("\n", 6),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchCaseContainingDictionaryDefault() {
        let input = "switch x {\ncase y: foo[\"z\", default: []]\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .identifier("y"),
            .startOfScope(":"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("["),
            .startOfScope("\""),
            .stringBody("z"),
            .endOfScope("\""),
            .delimiter(","),
            .space(" "),
            .identifier("default"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("["),
            .endOfScope("]"),
            .endOfScope("]"),
            .linebreak("\n", 2),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchCaseIsDictionaryStatement() {
        let input = "switch x {\ncase foo is [Key: Value]:\nbreak\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .keyword("is"),
            .space(" "),
            .startOfScope("["),
            .identifier("Key"),
            .delimiter(":"),
            .space(" "),
            .identifier("Value"),
            .endOfScope("]"),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("break"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchCaseContainingCaseIdentifier() {
        let input = "switch x {\ncase 1:\nfoo.case\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("case"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchCaseContainingDefaultIdentifier() {
        let input = "switch x {\ncase 1:\nfoo.default\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("default"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchCaseContainingIfCase() {
        let input = "switch x {\ncase 1:\nif case x = y {}\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("if"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("y"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchCaseContainingIfCaseCommaCase() {
        let input = "switch x {\ncase 1:\nif case w = x, case y = z {}\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("if"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("w"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("x"),
            .delimiter(","),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("y"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("z"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchCaseContainingGuardCase() {
        let input = "switch x {\ncase 1:\nguard case x = y else {}\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("guard"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("y"),
            .space(" "),
            .keyword("else"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchFollowedByEnum() {
        let input = "switch x {\ncase y: break\ndefault: break\n}\nenum Foo {\ncase z\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .identifier("y"),
            .startOfScope(":"),
            .space(" "),
            .keyword("break"),
            .linebreak("\n", 2),
            .endOfScope("default"),
            .startOfScope(":"),
            .space(" "),
            .keyword("break"),
            .linebreak("\n", 3),
            .endOfScope("}"),
            .linebreak("\n", 4),
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 5),
            .keyword("case"),
            .space(" "),
            .identifier("z"),
            .linebreak("\n", 6),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchCaseContainingSwitchIdentifierFollowedByEnum() {
        let input = "switch x {\ncase 1:\nfoo.switch\ndefault:\nbreak\n}\nenum Foo {\ncase z\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("1", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("switch"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("}"),
            .linebreak("\n", 6),
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 7),
            .keyword("case"),
            .space(" "),
            .identifier("z"),
            .linebreak("\n", 8),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchCaseContainingRangeOperator() {
        let input = "switch x {\ncase 0 ..< 2:\nbreak\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .number("0", .integer),
            .space(" "),
            .operator("..<", .infix),
            .space(" "),
            .number("2", .integer),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("break"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func enumDeclarationInsideSwitchCase() {
        let input = "switch x {\ncase y:\nenum Foo {\ncase z\n}\nbreak\ndefault: break\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .identifier("y"),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 3),
            .keyword("case"),
            .space(" "),
            .identifier("z"),
            .linebreak("\n", 4),
            .endOfScope("}"),
            .linebreak("\n", 5),
            .keyword("break"),
            .linebreak("\n", 6),
            .endOfScope("default"),
            .startOfScope(":"),
            .space(" "),
            .keyword("break"),
            .linebreak("\n", 7),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func defaultAfterWhereCondition() {
        let input = "switch foo {\ncase _ where baz < quux:\nbreak\ndefault:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .identifier("_"),
            .space(" "),
            .keyword("where"),
            .space(" "),
            .identifier("baz"),
            .space(" "),
            .operator("<", .infix),
            .space(" "),
            .identifier("quux"),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("break"),
            .linebreak("\n", 3),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 4),
            .keyword("break"),
            .linebreak("\n", 5),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func enumWithConditionalCase() {
        let input = "enum Foo {\ncase bar\n#if baz\ncase baz\n#endif\n}"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .keyword("case"),
            .space(" "),
            .identifier("bar"),
            .linebreak("\n", 2),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n", 3),
            .keyword("case"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n", 4),
            .endOfScope("#endif"),
            .linebreak("\n", 5),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchWithConditionalCase() {
        let input = "switch foo {\ncase bar:\nbreak\n#if baz\ndefault:\nbreak\n#endif\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .endOfScope("case"),
            .space(" "),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n", 2),
            .keyword("break"),
            .linebreak("\n", 3),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n", 4),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 5),
            .keyword("break"),
            .linebreak("\n", 6),
            .endOfScope("#endif"),
            .linebreak("\n", 7),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchWithConditionalCase2() {
        let input = "switch foo {\n#if baz\ndefault:\nbreak\n#else\ncase bar:\nbreak\n#endif\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n", 2),
            .endOfScope("default"),
            .startOfScope(":"),
            .linebreak("\n", 3),
            .keyword("break"),
            .linebreak("\n", 4),
            .keyword("#else"),
            .linebreak("\n", 5),
            .endOfScope("case"),
            .space(" "),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n", 6),
            .keyword("break"),
            .linebreak("\n", 7),
            .endOfScope("#endif"),
            .linebreak("\n", 8),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func switchWithConditionalCase3() {
        let input = "switch foo {\n#if baz\ncase foo:\nbreak\n#endif\ncase bar:\nbreak\n}"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .startOfScope("{"),
            .linebreak("\n", 1),
            .startOfScope("#if"),
            .space(" "),
            .identifier("baz"),
            .linebreak("\n", 2),
            .endOfScope("case"),
            .space(" "),
            .identifier("foo"),
            .startOfScope(":"),
            .linebreak("\n", 3),
            .keyword("break"),
            .linebreak("\n", 4),
            .endOfScope("#endif"),
            .linebreak("\n", 5),
            .endOfScope("case"),
            .space(" "),
            .identifier("bar"),
            .startOfScope(":"),
            .linebreak("\n", 6),
            .keyword("break"),
            .linebreak("\n", 7),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericEnumCase() {
        let input = "enum Foo<T>: Bar where T: Bar { case bar }"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .delimiter(":"),
            .space(" "),
            .identifier("Bar"),
            .space(" "),
            .keyword("where"),
            .space(" "),
            .identifier("T"),
            .delimiter(":"),
            .space(" "),
            .identifier("Bar"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("bar"),
            .space(" "),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func caseEnumValueWithoutSpaces() {
        let input = "switch x { case.foo:break }"
        let output: [Token] = [
            .keyword("switch"),
            .space(" "),
            .identifier("x"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .endOfScope("case"),
            .operator(".", .prefix),
            .identifier("foo"),
            .startOfScope(":"),
            .keyword("break"),
            .space(" "),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func uncheckedSendableEnum() {
        let input = "enum Foo: @unchecked Sendable { case bar }"
        let output: [Token] = [
            .keyword("enum"),
            .space(" "),
            .identifier("Foo"),
            .delimiter(":"),
            .space(" "),
            .keyword("@unchecked"),
            .space(" "),
            .identifier("Sendable"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("bar"),
            .space(" "),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func forCaseLetPreceededByAwait() {
        let input =
            "func forGroup(_ group: TaskGroup<String?>) async { for await case let value? in group { print(value.description) } }"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("forGroup"),
            .startOfScope("("),
            .identifier("_"),
            .space(" "),
            .identifier("group"),
            .delimiter(":"),
            .space(" "),
            .identifier("TaskGroup"),
            .startOfScope("<"),
            .identifier("String"),
            .operator("?", .postfix),
            .endOfScope(">"),
            .endOfScope(")"),
            .space(" "),
            .identifier("async"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .keyword("for"),
            .space(" "),
            .keyword("await"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .keyword("let"),
            .space(" "),
            .identifier("value"),
            .operator("?", .postfix),
            .space(" "),
            .keyword("in"),
            .space(" "),
            .identifier("group"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .identifier("print"),
            .startOfScope("("),
            .identifier("value"),
            .operator(".", .infix),
            .identifier("description"),
            .endOfScope(")"),
            .space(" "),
            .endOfScope("}"),
            .space(" "),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: dot prefix

    @Test func enumValueInDictionaryLiteral() {
        let input = "[.foo:.bar]"
        let output: [Token] = [
            .startOfScope("["),
            .operator(".", .prefix),
            .identifier("foo"),
            .delimiter(":"),
            .operator(".", .prefix),
            .identifier("bar"),
            .endOfScope("]"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func ifdefPrefixDot() {
        let input = """
        foo
        #if bar
        .bar
        #else
        .baz
        #endif
        .quux
        """
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\n", 1),
            .startOfScope("#if"),
            .space(" "),
            .identifier("bar"),
            .linebreak("\n", 2),
            .operator(".", .infix),
            .identifier("bar"),
            .linebreak("\n", 3),
            .keyword("#else"),
            .linebreak("\n", 4),
            .operator(".", .infix),
            .identifier("baz"),
            .linebreak("\n", 5),
            .endOfScope("#endif"),
            .linebreak("\n", 6),
            .operator(".", .infix),
            .identifier("quux"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: linebreaks

    @Test func lF() {
        let input = "foo\nbar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\n", 1),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func cR() {
        let input = "foo\rbar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\r", 1),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func cRLF() {
        let input = "foo\r\nbar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\r\n", 1),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func cRLFAfterComment() {
        let input = "//foo\r\n//bar"
        let output: [Token] = [
            .startOfScope("//"),
            .commentBody("foo"),
            .linebreak("\r\n", 1),
            .startOfScope("//"),
            .commentBody("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func cRLFInMultilineComment() {
        let input = "/*foo\r\nbar*/"
        let output: [Token] = [
            .startOfScope("/*"),
            .commentBody("foo"),
            .linebreak("\r\n", 1),
            .commentBody("bar"),
            .endOfScope("*/"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: keypaths

    @Test func namespacedKeyPath() {
        let input = "let foo = \\Foo.bar"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("\\", .prefix),
            .identifier("Foo"),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func anonymousKeyPath() {
        let input = "let foo = \\.bar"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("\\", .prefix),
            .operator(".", .prefix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func anonymousSubscriptKeyPath() {
        let input = "let foo = \\.[0].bar"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("\\", .prefix),
            .operator(".", .prefix),
            .startOfScope("["),
            .number("0", .integer),
            .endOfScope("]"),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func anonymousOptionalKeyPath() {
        let input = "let foo = \\.?.bar"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("\\", .prefix),
            .operator(".", .prefix),
            .operator("?", .postfix),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func anonymousOptionalSubscriptKeyPath() {
        let input = "let foo = \\.?[0].bar"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .operator("\\", .prefix),
            .operator(".", .prefix),
            .operator("?", .postfix),
            .startOfScope("["),
            .number("0", .integer),
            .endOfScope("]"),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func attributeInsideGenericArguments() {
        let input = "Foo<(@MainActor () -> Void)?>(nil)"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .startOfScope("("),
            .keyword("@MainActor"),
            .space(" "),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .operator("->", .infix),
            .space(" "),
            .identifier("Void"),
            .endOfScope(")"),
            .operator("?", .postfix),
            .endOfScope(">"),
            .startOfScope("("),
            .identifier("nil"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: Suppressed Conformances

    @Test func noncopyableStructDeclaration() {
        let input = "struct Foo: ~Copyable {}"
        let output: [Token] = [
            .keyword("struct"),
            .space(" "),
            .identifier("Foo"),
            .delimiter(":"),
            .space(" "),
            .operator("~", .prefix),
            .identifier("Copyable"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func suppressedConformanceInWhereCondition() {
        let input = "Foo<T> where T: ~Copyable"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .space(" "),
            .keyword("where"),
            .space(" "),
            .identifier("T"),
            .delimiter(":"),
            .space(" "),
            .operator("~", .prefix),
            .identifier("Copyable"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func suppressedConformancesOnGenericParameters() {
        let input = "Foo<T: ~Copyable, U: Sendable & ~Escapable>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .delimiter(":"),
            .space(" "),
            .operator("~", .prefix),
            .identifier("Copyable"),
            .delimiter(","),
            .space(" "),
            .identifier("U"),
            .delimiter(":"),
            .space(" "),
            .identifier("Sendable"),
            .space(" "),
            .operator("&", .infix),
            .space(" "),
            .operator("~", .prefix),
            .identifier("Escapable"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: borrowing and consuming modifiers

    @Test func borrowingParameterModifier() {
        let input = "func foo(_: borrowing Foo)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("_"),
            .delimiter(":"),
            .space(" "),
            .identifier("borrowing"),
            .space(" "),
            .identifier("Foo"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func consumingParameterModifier() {
        let input = "func foo(_: consuming Foo)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("_"),
            .delimiter(":"),
            .space(" "),
            .identifier("consuming"),
            .space(" "),
            .identifier("Foo"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func borrowingClosureParameter() {
        let input = "bar { (a: borrowing Foo) in a }"
        let output: [Token] = [
            .identifier("bar"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .startOfScope("("),
            .identifier("a"),
            .delimiter(":"),
            .space(" "),
            .identifier("borrowing"),
            .space(" "),
            .identifier("Foo"),
            .endOfScope(")"),
            .space(" "),
            .keyword("in"),
            .space(" "),
            .identifier("a"),
            .space(" "),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func borrowingFunctionSignature() {
        let input = "(borrowing Foo) -> Void"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("borrowing"),
            .space(" "),
            .identifier("Foo"),
            .endOfScope(")"),
            .space(" "),
            .operator("->", .infix),
            .space(" "),
            .identifier("Void"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: consume and discard operators

    @Test func consumeOperator() {
        let input = "_ = consume x"
        let output: [Token] = [
            .identifier("_"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .keyword("consume"),
            .space(" "),
            .identifier("x"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func discardOperator() {
        let input = "discard x"
        let output: [Token] = [
            .keyword("discard"),
            .space(" "),
            .identifier("x"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func consumeFunction() {
        let input = "_ = consume (x)"
        let output: [Token] = [
            .identifier("_"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("consume"),
            .space(" "),
            .startOfScope("("),
            .identifier("x"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func consumeLabel() {
        let input = "func foo(consume bar: Int)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("consume"),
            .space(" "),
            .identifier("bar"),
            .delimiter(":"),
            .space(" "),
            .identifier("Int"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func consumeVariable() {
        let input = "let consume = 5"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("consume"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .number("5", .integer),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: await

    @Test func awaitExpression() {
        let input = "let foo = await bar()"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .keyword("await"),
            .space(" "),
            .identifier("bar"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func awaitFunction() {
        let input = "func await()"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("await"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func awaitClass() {
        let input = "class await {}"
        let output: [Token] = [
            .keyword("class"),
            .space(" "),
            .identifier("await"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func awaitProperty() {
        let input = "let await = 5"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("await"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .number("5", .integer),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: actors

    @Test func actorType() {
        let input = "actor Foo {}"
        let output: [Token] = [
            .keyword("actor"),
            .space(" "),
            .identifier("Foo"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func actorProperty() {
        let input = "let actor = {}"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("actor"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func actorProperty2() {
        let input = "actor = 5"
        let output: [Token] = [
            .identifier("actor"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .number("5", .integer),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func actorProperty3() {
        let input = """
        self.actor = actor
        self.bar = bar
        """
        let output: [Token] = [
            .identifier("self"),
            .operator(".", .infix),
            .identifier("actor"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("actor"),
            .linebreak("\n", 1),
            .identifier("self"),
            .operator(".", .infix),
            .identifier("bar"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func actorLabel() {
        let input = "init(actor: Actor) {}"
        let output: [Token] = [
            .keyword("init"),
            .startOfScope("("),
            .identifier("actor"),
            .delimiter(":"),
            .space(" "),
            .identifier("Actor"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func actorVariable() {
        let input = "let foo = actor\nlet bar = foo"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("actor"),
            .linebreak("\n", 1),
            .keyword("let"),
            .space(" "),
            .identifier("bar"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("foo"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: macros

    @Test func macroType() {
        let input = "macro stringify()"
        let output: [Token] = [
            .keyword("macro"),
            .space(" "),
            .identifier("stringify"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func macroProperty() {
        let input = "let macro = {}"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("macro"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: some / any

    @Test func someView() {
        let input = "var body: some View {}"
        let output: [Token] = [
            .keyword("var"),
            .space(" "),
            .identifier("body"),
            .delimiter(":"),
            .space(" "),
            .identifier("some"),
            .space(" "),
            .identifier("View"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func anyView() {
        let input = "var body: any View {}"
        let output: [Token] = [
            .keyword("var"),
            .space(" "),
            .identifier("body"),
            .delimiter(":"),
            .space(" "),
            .identifier("any"),
            .space(" "),
            .identifier("View"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func someAnimal() {
        let input = "func feed(_ animal: some Animal) {}"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("feed"),
            .startOfScope("("),
            .identifier("_"),
            .space(" "),
            .identifier("animal"),
            .delimiter(":"),
            .space(" "),
            .identifier("some"),
            .space(" "),
            .identifier("Animal"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func anyAnimal() {
        let input = "func feed(_ animal: any Animal) {}"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("feed"),
            .startOfScope("("),
            .identifier("_"),
            .space(" "),
            .identifier("animal"),
            .delimiter(":"),
            .space(" "),
            .identifier("any"),
            .space(" "),
            .identifier("Animal"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func anyAnimalArray() {
        let input = "let animals: [any Animal]"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("animals"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("["),
            .identifier("any"),
            .space(" "),
            .identifier("Animal"),
            .endOfScope("]"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rawIdentifiers() {
        let input = """
        func `square returns x * x`() -> Int { 42 }
        enum ColorVariant { case `50`, `100`, `200` }
        let `1.circle` = "SF Symbol"
        struct `class` { let `for` = true }
        """
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("`square returns x * x`"),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .operator("->", .infix),
            .space(" "),
            .identifier("Int"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .number("42", .integer),
            .space(" "),
            .endOfScope("}"),
            .linebreak("\n", 1),
            .keyword("enum"),
            .space(" "),
            .identifier("ColorVariant"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .keyword("case"),
            .space(" "),
            .identifier("`50`"),
            .delimiter(","),
            .space(" "),
            .identifier("`100`"),
            .delimiter(","),
            .space(" "),
            .identifier("`200`"),
            .space(" "),
            .endOfScope("}"),
            .linebreak("\n", 2),
            .keyword("let"),
            .space(" "),
            .identifier("`1.circle`"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("\""),
            .stringBody("SF Symbol"),
            .endOfScope("\""),
            .linebreak("\n", 3),
            .keyword("struct"),
            .space(" "),
            .identifier("`class`"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .keyword("let"),
            .space(" "),
            .identifier("`for`"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("true"),
            .space(" "),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }
}
