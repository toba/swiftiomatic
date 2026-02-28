import Testing
@testable import Swiftiomatic

@Suite struct ConsecutiveSpacesTests {
    @Test func consecutiveSpaces() {
        let input = """
        let foo  = bar
        """
        let output = """
        let foo = bar
        """
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    @Test func consecutiveSpacesAfterComment() {
        let input = """
        // comment
        foo  bar
        """
        let output = """
        // comment
        foo bar
        """
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    @Test func consecutiveSpacesDoesntStripIndent() {
        let input = """
        {
            let foo  = bar
        }
        """
        let output = """
        {
            let foo = bar
        }
        """
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    @Test func consecutiveSpacesDoesntAffectMultilineComments() {
        let input = """
        /*    comment  */
        """
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    @Test func consecutiveSpacesRemovedBetweenComments() {
        let input = """
        /* foo */  /* bar */
        """
        let output = """
        /* foo */ /* bar */
        """
        testFormatting(for: input, output, rule: .consecutiveSpaces)
    }

    @Test func consecutiveSpacesDoesntAffectNestedMultilineComments() {
        let input = """
        /*  foo  /*  bar  */  baz  */
        """
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    @Test func consecutiveSpacesDoesntAffectNestedMultilineComments2() {
        let input = """
        /*  /*  foo  */  /*  bar  */  */
        """
        testFormatting(for: input, rule: .consecutiveSpaces)
    }

    @Test func consecutiveSpacesDoesntAffectSingleLineComments() {
        let input = """
        //    foo  bar
        """
        testFormatting(for: input, rule: .consecutiveSpaces)
    }
}
