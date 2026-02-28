import Testing
@testable import Swiftiomatic

@Suite struct WrapSingleLineCommentsTests {
    @Test func wrapSingleLineComment() {
        let input = """
        // a b cde fgh
        """
        let output = """
        // a b
        // cde
        // fgh
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 6))
    }

    @Test func wrapSingleLineCommentThatOverflowsByOneCharacter() {
        let input = """
        // a b cde fg h
        """
        let output = """
        // a b cde fg
        // h
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 14))
    }

    @Test func noWrapSingleLineCommentThatExactlyFits() {
        let input = """
        // a b cde fg h
        """

        testFormatting(for: input, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 15))
    }

    @Test func wrapSingleLineCommentWithNoLeadingSpace() {
        let input = """
        //a b cde fgh
        """
        let output = """
        //a b
        //cde
        //fgh
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 6),
                       exclude: [.spaceInsideComments])
    }

    @Test func wrapDocComment() {
        let input = """
        /// a b cde fgh
        """
        let output = """
        /// a b
        /// cde
        /// fgh
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 7), exclude: [.docComments])
    }

    @Test func wrapDocLineCommentWithNoLeadingSpace() {
        let input = """
        ///a b cde fgh
        """
        let output = """
        ///a b
        ///cde
        ///fgh
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 6),
                       exclude: [.spaceInsideComments, .docComments])
    }

    @Test func wrapSingleLineCommentWithIndent() {
        let input = """
        func f() {
            // a b cde fgh
            let x = 1
        }
        """
        let output = """
        func f() {
            // a b cde
            // fgh
            let x = 1
        }
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 14), exclude: [.docComments])
    }

    @Test func wrapSingleLineCommentAfterCode() {
        let input = """
        func f() {
            foo.bar() // this comment is much much much too long
        }
        """
        let output = """
        func f() {
            foo.bar() // this comment
            // is much much much too
            // long
        }
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 29), exclude: [.wrap])
    }

    @Test func wrapDocCommentWithLongURL() {
        let input = """
        /// See [Link](https://www.domain.com/pathextension/pathextension/pathextension/pathextension/pathextension/pathextension).
        """

        testFormatting(for: input, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 100), exclude: [.docComments])
    }

    @Test func wrapDocCommentWithLongURL2() {
        let input = """
        /// Link to SDK documentation - https://docs.adyen.com/checkout/3d-secure/native-3ds2/api-integration#collect-the-3d-secure-2-device-fingerprint-from-an-ios-app
        """

        testFormatting(for: input, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 80))
    }

    @Test func wrapDocCommentWithMultipleLongURLs() {
        let input = """
        /// Link to http://a-very-long-url-that-wont-fit-on-one-line, http://another-very-long-url-that-wont-fit-on-one-line
        """
        let output = """
        /// Link to http://a-very-long-url-that-wont-fit-on-one-line,
        /// http://another-very-long-url-that-wont-fit-on-one-line
        """

        testFormatting(for: input, output, rule: .wrapSingleLineComments,
                       options: FormatOptions(maxWidth: 40), exclude: [.docComments])
    }
}
