@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct ReflowCommentsTests: RuleTesting {

    private func config(maxWidth: Int) -> Configuration {
        var c = Configuration.forTesting(enabledRule: ReflowComments.self.key)
        c[LineLength.self] = maxWidth
        return c
    }

    // MARK: - Basic reflow

    @Test func reflowsRaggedDocCommentParagraph() {
        assertFormatting(
            ReflowComments.self,
            input: """
                1️⃣/// Wraps any `CloudDatabase` in a concrete class so it can be stored in
                /// non-generic contexts (e.g. dictionaries keyed by database scope).
                /// Identity-based equality: two wrappers are equal iff they wrap the same object.
                let x = 1
                """,
            expected: """
                /// Wraps any `CloudDatabase` in a concrete class so it can be stored in non-generic contexts (e.g.
                /// dictionaries keyed by database scope). Identity-based equality: two wrappers are equal iff they
                /// wrap the same object.
                let x = 1
                """,
            findings: [FindingSpec("1️⃣", message: "reflow comment to fit line length")],
            configuration: config(maxWidth: 100)
        )
    }

    @Test func leavesAlreadyTightCommentsUnchanged() {
        assertFormatting(
            ReflowComments.self,
            input: """
                /// Already short.
                let x = 1
                """,
            expected: """
                /// Already short.
                let x = 1
                """,
            configuration: config(maxWidth: 100)
        )
    }

    @Test func keepsURLOnSingleLineEvenIfItOverflows() {
        // The URL is wider than what would fit after wrapping, so it occupies its own line.
        assertFormatting(
            ReflowComments.self,
            input: """
                1️⃣/// See
                /// https://example.com/very/long/path/that/exceeds/line/length/easily/foo/bar
                /// for details.
                let x = 1
                """,
            expected: """
                /// See https://example.com/very/long/path/that/exceeds/line/length/easily/foo/bar for details.
                let x = 1
                """,
            findings: [FindingSpec("1️⃣", message: "reflow comment to fit line length")],
            configuration: config(maxWidth: 100)
        )
    }

    @Test func keepsInlineCodeAtomic() {
        assertFormatting(
            ReflowComments.self,
            input: """
                1️⃣/// One two three `foo bar baz` four five six seven eight
                /// nine ten.
                let x = 1
                """,
            expected: """
                /// One two three `foo bar baz` four five six seven eight nine ten.
                let x = 1
                """,
            findings: [FindingSpec("1️⃣", message: "reflow comment to fit line length")],
            configuration: config(maxWidth: 100)
        )
    }

    // MARK: - Code fences

    @Test func preservesCodeFenceContents() {
        assertFormatting(
            ReflowComments.self,
            input: """
                /// Heading paragraph that fits.
                ///
                /// ```
                /// let veryLongIdentifier = somethingThatWouldNormallyBeReflowedButIsCode()
                /// ```
                let x = 1
                """,
            expected: """
                /// Heading paragraph that fits.
                ///
                /// ```
                /// let veryLongIdentifier = somethingThatWouldNormallyBeReflowedButIsCode()
                /// ```
                let x = 1
                """,
            configuration: config(maxWidth: 100)
        )
    }

    @Test func leavesMARKAndTODOAlone() {
        assertFormatting(
            ReflowComments.self,
            input: """
                // MARK: - Some heading that might otherwise look like it wants reflow but should not be touched here
                let x = 1
                """,
            expected: """
                // MARK: - Some heading that might otherwise look like it wants reflow but should not be touched here
                let x = 1
                """,
            configuration: config(maxWidth: 100)
        )
    }

    @Test func reflowsCommentIndentedInsideType() {
        assertFormatting(
            ReflowComments.self,
            input: """
                struct S {
                    1️⃣/// First sentence that is short.
                    /// Second sentence that is also short but the combination of these sentences exceeds the available width when reflowed.
                    let x = 1
                }
                """,
            expected: """
                struct S {
                    /// First sentence that is short. Second sentence that is also short but the combination of
                    /// these sentences exceeds the available width when reflowed.
                    let x = 1
                }
                """,
            findings: [FindingSpec("1️⃣", message: "reflow comment to fit line length")],
            configuration: config(maxWidth: 100)
        )
    }

    @Test func preservesFileHeaderComment() {
        // A `//` comment block at the very top of the file is the file header
        // (license, copyright, etc.) and must be preserved verbatim, even when
        // its lines could otherwise be redistributed to fit the width.
        let header = """
            // Copyright (c) 2026 Example Corp.
            // Some short line.
            // Another short line that, combined with the lines above, could be reflowed.
            """
        assertFormatting(
            ReflowComments.self,
            input: """
                \(header)

                1️⃣/// Wraps any `CloudDatabase` in a concrete class so it can be stored in
                /// non-generic contexts (e.g. dictionaries keyed by database scope).
                /// Identity-based equality: two wrappers are equal iff they wrap the same object.
                let x = 1
                """,
            expected: """
                \(header)

                /// Wraps any `CloudDatabase` in a concrete class so it can be stored in non-generic contexts (e.g.
                /// dictionaries keyed by database scope). Identity-based equality: two wrappers are equal iff they
                /// wrap the same object.
                let x = 1
                """,
            findings: [FindingSpec("1️⃣", message: "reflow comment to fit line length")],
            configuration: config(maxWidth: 100)
        )
    }

    @Test func preservesAdjacentLinkReferenceDefinitions() {
        // Regression: two `[label]: url` lines were merged into one paragraph and reflowed,
        // producing `[uiv]: ...uitextview [nsv]:` on one line, which breaks the references.
        assertFormatting(
            ReflowComments.self,
            input: """
                /// Text view for [iOS][uiv] or [MacOS][nsv]
                ///
                /// [uiv]: https://developer.apple.com/documentation/uikit/uitextview
                /// [nsv]: https://developer.apple.com/documentation/appkit/nstextview
                let x = 1
                """,
            expected: """
                /// Text view for [iOS][uiv] or [MacOS][nsv]
                ///
                /// [uiv]: https://developer.apple.com/documentation/uikit/uitextview
                /// [nsv]: https://developer.apple.com/documentation/appkit/nstextview
                let x = 1
                """,
            configuration: config(maxWidth: 100)
        )
    }

    @Test func preservesParametersBlockIndentation() {
        assertFormatting(
            ReflowComments.self,
            input: """
                /// Handles an account change event.
                ///
                /// - Parameters:
                ///   - syncEngine: The sync engine that generates the event.
                ///   - changeType: The iCloud account's change type.
                func handle() {}
                """,
            expected: """
                /// Handles an account change event.
                ///
                /// - Parameters:
                ///   - syncEngine: The sync engine that generates the event.
                ///   - changeType: The iCloud account's change type.
                func handle() {}
                """,
            configuration: config(maxWidth: 100)
        )
    }
}

@Suite
struct CommentReflowEngineTests {

    @Test func tokenizerKeepsURLAtomic() {
        let atoms = CommentReflowEngine.tokenize("see https://example.com/x?y=z and more")
        #expect(atoms == ["see", "https://example.com/x?y=z", "and", "more"])
    }

    @Test func tokenizerKeepsInlineCodeAtomic() {
        let atoms = CommentReflowEngine.tokenize("one `two three` four")
        #expect(atoms == ["one", "`two three`", "four"])
    }

    @Test func tokenizerKeepsDocCSymbolReferenceAtomic() {
        // DocC double-backtick symbol references must remain a single atom; otherwise
        // the wrapper can split between the opening `` and the symbol name, inserting
        // spaces that break Quick Help.
        let atoms = CommentReflowEngine.tokenize("call ``SyncEngine/deleteLocalData()`` if needed")
        #expect(atoms == ["call", "``SyncEngine/deleteLocalData()``", "if", "needed"])
    }

    @Test func reflowKeepsDocCSymbolReferenceWhole() {
        // A long line containing a `` `` symbol reference must wrap around the
        // reference, never inside it.
        let r = CommentReflowEngine.reflow(
            lines: [
                "if they want to clear their local data or not, implement this method, and explicitly call ``SyncEngine/deleteLocalData()`` if/when the data should be cleared."
            ],
            availableWidth: 100
        )
        let joined = (r ?? []).joined(separator: "\n")
        // The reference must appear whole on some single line — splitting inside the
        // backticks would break Quick Help. A wrap that places the reference at the
        // start of a new line is fine; only an interior split is wrong.
        #expect(joined.contains("``SyncEngine/deleteLocalData()``"))
        #expect(!joined.contains("``\n"))
    }

    @Test func tokenizerKeepsMarkdownLinkAtomic() {
        let atoms = CommentReflowEngine.tokenize("see [the docs](https://x.com/a b) really")
        #expect(atoms == ["see", "[the docs](https://x.com/a b)", "really"])
    }

    @Test func reflowReturnsNilWhenAlreadyOptimal() {
        let r = CommentReflowEngine.reflow(lines: ["short line"], availableWidth: 80)
        #expect(r == nil)
    }

    @Test func reflowJoinsShortFragmentsIntoOneLine() {
        let r = CommentReflowEngine.reflow(
            lines: ["one two three", "four five six"],
            availableWidth: 80
        )
        #expect(r == ["one two three four five six"])
    }

    @Test func reflowSplitsLongParagraphRespectingWidth() {
        let r = CommentReflowEngine.reflow(
            lines: ["aaa bbb ccc ddd eee fff"],
            availableWidth: 11
        )
        #expect(r == ["aaa bbb ccc", "ddd eee fff"])
    }

    @Test func reflowKeepsBlankLineSeparatorBetweenParagraphs() {
        let r = CommentReflowEngine.reflow(
            lines: ["aaa bbb ccc ddd", "", "eee fff ggg hhh"],
            availableWidth: 7
        )
        #expect(r == ["aaa bbb", "ccc ddd", "", "eee fff", "ggg hhh"])
    }

    @Test func reflowBlockQuoteSingleParagraphLazyContinuation() {
        let r = CommentReflowEngine.reflow(
            lines: ["> Note: some very long line that has to wrap"],
            availableWidth: 20
        )
        #expect(r == ["> Note: some very", "  long line that has", "  to wrap"])
    }

    @Test func reflowBlockQuoteMultiParagraphKeepsBlankSeparator() {
        let r = CommentReflowEngine.reflow(
            lines: ["> aaa bbb ccc ddd eee", ">", "> fff ggg hhh iii jjj"],
            availableWidth: 11
        )
        #expect(r == ["> aaa bbb", "  ccc ddd", "  eee", ">", "> fff ggg", "  hhh iii", "  jjj"])
    }

    @Test func reflowCodeFenceVerbatim() {
        // Surround the fence with ragged prose so the engine reports a change. The fence body
        // must be emitted verbatim regardless of width.
        let r = CommentReflowEngine.reflow(
            lines: [
                "aaa bbb",
                "ccc",
                "",
                "```",
                "absurdly long literal line of code that exceeds width",
                "```",
            ],
            availableWidth: 12
        )
        #expect(r != nil)
        #expect(r?.contains("absurdly long literal line of code that exceeds width") == true)
        #expect(r?.contains("```") == true)
    }

    @Test func reflowListContinuationAlignsUnderContent() {
        let r = CommentReflowEngine.reflow(
            lines: ["- aaa bbb ccc ddd eee fff"],
            availableWidth: 12
        )
        #expect(r == ["- aaa bbb", "  ccc ddd", "  eee fff"])
    }

    @Test func preservesNestedBulletListIndentation() {
        // Nested bullet list: child items should be indented by exactly the
        // parent marker width (2 spaces for "- "), not doubled.
        let r = CommentReflowEngine.reflow(
            lines: [
                "- parent item",
                "  - child one",
                "  - child two",
            ],
            availableWidth: 80
        )
        #expect(r == nil || r == ["- parent item", "  - child one", "  - child two"])
    }
}
