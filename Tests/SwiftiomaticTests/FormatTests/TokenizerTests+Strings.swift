import Testing
@testable import Swiftiomatic

extension TokenizerTests {
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

}
