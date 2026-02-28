import Testing
@testable import Swiftiomatic

@Suite struct SpaceInsideCommentsTests {
    @Test func spaceInsideMultilineComment() {
        let input = """
        /*foo
         bar*/
        """
        let output = """
        /* foo
         bar */
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    @Test func spaceInsideSingleLineMultilineComment() {
        let input = """
        /*foo*/
        """
        let output = """
        /* foo */
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    @Test func noSpaceInsideEmptyMultilineComment() {
        let input = """
        /**/
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    @Test func spaceInsideSingleLineComment() {
        let input = """
        //foo
        """
        let output = """
        // foo
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    @Test func spaceInsideMultilineHeaderdocComment() {
        let input = """
        /**foo
         bar*/
        """
        let output = """
        /** foo
         bar */
        """
        testFormatting(for: input, output, rule: .spaceInsideComments, exclude: [.docComments])
    }

    @Test func spaceInsideMultilineHeaderdocCommentType2() {
        let input = """
        /*!foo
         bar*/
        """
        let output = """
        /*! foo
         bar */
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    @Test func spaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = """
        /*:foo
         bar*/
        """
        let output = """
        /*: foo
         bar */
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    @Test func noExtraSpaceInsideMultilineHeaderdocComment() {
        let input = """
        /** foo
         bar */
        """
        testFormatting(for: input, rule: .spaceInsideComments, exclude: [.docComments])
    }

    @Test func noExtraSpaceInsideMultilineHeaderdocCommentType2() {
        let input = """
        /*! foo
         bar */
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    @Test func noExtraSpaceInsideMultilineSwiftPlaygroundDocComment() {
        let input = """
        /*: foo
         bar */
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    @Test func spaceInsideSingleLineHeaderdocComment() {
        let input = """
        ///foo
        """
        let output = """
        /// foo
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    @Test func spaceInsideSingleLineHeaderdocCommentType2() {
        let input = """
        //!foo
        """
        let output = """
        //! foo
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    @Test func spaceInsideSingleLineSwiftPlaygroundDocComment() {
        let input = """
        //:foo
        """
        let output = """
        //: foo
        """
        testFormatting(for: input, output, rule: .spaceInsideComments)
    }

    @Test func preformattedMultilineComment() {
        let input = """
        /*********************
         *****Hello World*****
         *********************/
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    @Test func preformattedSingleLineComment() {
        let input = """
        /////////ATTENTION////////
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    @Test func noSpaceAddedToFirstLineOfDocComment() {
        let input = """
        /**
         Comment
         */
        """
        testFormatting(for: input, rule: .spaceInsideComments, exclude: [.docComments])
    }

    @Test func noSpaceAddedToEmptyDocComment() {
        let input = """
        ///
        """
        testFormatting(for: input, rule: .spaceInsideComments)
    }

    @Test func noExtraTrailingSpaceAddedToDocComment() {
        let input = """
        class Foo {
            /**
            Call to configure forced disabling of Bills fallback mode.
            Intended for use only in debug builds and automated tests.
             */
            func bar() {}
        }
        """
        testFormatting(for: input, rule: .spaceInsideComments, exclude: [.indent])
    }
}
