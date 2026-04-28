@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

/// Idempotency regression tests for comment-wrapping rules.
///
/// `sm format` is expected to reach a fixed point in a single pass: running it twice on the same
/// input must produce the same output as running it once. These tests pin down a class of inputs
/// where pass 1 left overlong comments in place that pass 2 then wrapped — see jig issue 5zd-wm4.
@Suite
struct CommentWrapIdempotencyTests {

    private func config(maxWidth: Int) -> Configuration {
        var c = Configuration.forTesting
        c.disableAllRules()
        c.enableRule(named: WrapSingleLineComments.self.key)
        c.enableRule(named: ReflowComments.self.key)
        c[LineLength.self] = maxWidth
        return c
    }

    private func formatOnce(_ source: String, configuration: Configuration) throws -> String {
        let coordinator = RewriteCoordinator(
            configuration: configuration,
            findingConsumer: { _ in }
        )
        var out = ""
        try coordinator.format(
            source: source,
            assumingFileURL: nil,
            selection: .infinite,
            to: &out
        )
        return out
    }

    private func assertIdempotent(
        _ input: String,
        configuration: Configuration,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let pass1 = try formatOnce(input, configuration: configuration)
        let pass2 = try formatOnce(pass1, configuration: configuration)
        assertStringsEqualWithDiff(pass2, pass1, "second pass changed output", sourceLocation: sourceLocation)
    }

    /// A long line comment whose source-text column is 0 but which lands inside a function body
    /// after formatting. Pass 1 reads column 0 from trivia and decides the comment fits; layout
    /// then re-indents the comment, pushing it past `lineLength`. Pass 2 reads the new column from
    /// trivia and finally wraps.
    @Test func longCommentReindentedByLayout() throws {
        let input = """
            func f() { let x = 1
            // abcdefg hijklmn opqrstuv wxyz ABCDEFG HIJ
            let y = 2 }
            """
        try assertIdempotent(input, configuration: config(maxWidth: 40))
    }

    /// A trailing-style comment that the rewrite pipeline hoists to its own line. The comment is
    /// short enough at its original (post-code) column to skip wrapping on pass 1, but at its new
    /// column on pass 2 the rule sees it differently.
    @Test func longLeadingCommentInsideNestedScope() throws {
        let input = """
            struct S {
                func f() {
                    if true {
            // abcdefg hijklmn opqrstuv wxyz 1234 5678 90
                        let z = 3
                    }
                }
            }
            """
        try assertIdempotent(input, configuration: config(maxWidth: 40))
    }

    /// A long doc comment (`///`) at file scope where the input has no leading whitespace before
    /// the comment, but the next token is reformatted such that its leading trivia changes shape.
    @Test func longDocCommentAtFileScope() throws {
        let input = """
            ///abcdef ghijkl mnopqr stuvwx yzABCD EFGHIJ KLMNOP QRSTUV WXYZ
            func f() {}
            """
        try assertIdempotent(input, configuration: config(maxWidth: 30))
    }

    /// Sanity: an already-wrapped, well-formed file is a fixed point.
    @Test func alreadyWrappedIsFixedPoint() throws {
        let input = """
            // abcdefg
            // hijklmn
            let x = 1

            """
        try assertIdempotent(input, configuration: config(maxWidth: 20))
    }
}
