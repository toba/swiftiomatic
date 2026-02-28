import Testing
@testable import Swiftiomatic

extension TokenizerTests {
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

}
