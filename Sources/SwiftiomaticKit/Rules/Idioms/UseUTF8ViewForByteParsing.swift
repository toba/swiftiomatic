import SwiftSyntax

/// Lint a `String.Index` walk whose slices feed a byte-level parse
///
/// `index(_:offsetBy:)` is grapheme-aware, so each step decodes the boundaries it passes, and each
/// slice it feeds carries a reference back to the parent string. A reader of hex digits, or of any
/// other fixed-width ASCII form, needs neither. `withUTF8` makes the storage contiguous and hands
/// the reader a `Span<UInt8>`, so the same digits are read in one pass with no slice.
///
/// ```swift
/// var hex = hex
/// guard let raw = hex.withUTF8({ UUID.rawBytes(parsingHex: $0.span) }) else { return nil }
/// ```
///
/// Prose parsing over a `String` is a legitimate grapheme walk, so the rule fires only when one
/// string is both walked by `index(_:offsetBy:)` and sliced into a fixed-width integer initializer
/// inside the same loop. A slice that goes anywhere else stays silent, and so does a single walk
/// outside a loop.
///
/// A helper function the loop calls counts as part of the loop, because a cost behind a call is
/// still paid once per iteration.
///
/// Lint: A loop that walks a string with `index(_:offsetBy:)` and parses slices of that same string
/// into an integer raises a warning.
final class UseUTF8ViewForByteParsing: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    // a helper reachable from two loops is walked twice, so the position keeps the report to one
    private var reported: Set<AbsolutePosition> = []

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        check(loopBody: node.body.statements)
        return .visitChildren
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        check(loopBody: node.body.statements)
        return .visitChildren
    }

    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        check(loopBody: node.body.statements)
        return .visitChildren
    }

    private func check(loopBody: CodeBlockItemListSyntax) {
        let collector = IndexWalkCollector(viewMode: .sourceAccurate)
        LoopReach(body: loopBody, functions: context.freeFunctions(in: loopBody.root)).walk(
            collector)

        let parsed = collector.parsedSliceBases
        var seen: Set<String> = []

        for walk in collector.indexWalks where parsed.contains(walk.base) {
            guard seen.insert(walk.base).inserted else { continue }
            let position = walk.call.positionAfterSkippingLeadingTrivia
            guard reported.insert(position).inserted else { continue }

            diagnose(.graphemeWalkForByteParse(walk.base), on: walk.call)
        }
    }
}

/// Records the index walks and the parsed slices of one loop, so the rule can match the two by
/// receiver name.
private final class IndexWalkCollector: LoopBodyVisitor {
    struct IndexWalk {
        let call: FunctionCallExprSyntax
        let base: String
    }

    private(set) var indexWalks: [IndexWalk] = []

    // a slice the parse reads directly, as in UInt8(hex[a..<b], radix: 16)
    private var directBases: Set<String> = []

    // a slice the parse reads through a local binding, as in let pair = hex[a..<b]
    private var sliceBaseOfBinding: [String: String] = [:]
    private var parsedBindings: Set<String> = []

    /// The strings whose slices reach an integer initializer
    var parsedSliceBases: Set<String> {
        var bases = directBases
        for binding in parsedBindings {
            if let base = sliceBaseOfBinding[binding] { bases.insert(base) }
        }
        return bases
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        recordIndexWalk(node)
        recordParsedSlice(node)
        return .visitChildren
    }

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        if let name = node.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
           let value = node.initializer?.value,
           let base = BytewiseParsing.sliceBase(of: value) { sliceBaseOfBinding[name] = base }
        return .visitChildren
    }

    private func recordIndexWalk(_ node: FunctionCallExprSyntax) {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "index",
            node.arguments.contains(where: { $0.label?.text == "offsetBy" }),
            let base = member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text else { return }

        indexWalks.append(IndexWalk(call: node, base: base))
    }

    private func recordParsedSlice(_ node: FunctionCallExprSyntax) {
        guard BytewiseParsing.integerTypeName(of: node) != nil else { return }

        for argument in node.arguments {
            if let base = BytewiseParsing.sliceBase(of: argument.expression) {
                directBases.insert(base)
            } else if let name = argument.expression.as(DeclReferenceExprSyntax.self) {
                parsedBindings.insert(name.baseName.text)
            }
        }
    }
}

fileprivate extension Finding.Message {
    static func graphemeWalkForByteParse(_ name: String) -> Finding.Message {
        """
        '\(name)' is walked by 'index(_:offsetBy:)' and its slices feed a byte parse \
        — read it once through 'withUTF8' and index the UTF-8 span
        """
    }
}
