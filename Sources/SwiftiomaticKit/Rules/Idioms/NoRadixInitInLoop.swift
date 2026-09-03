import SwiftSyntax

/// Lint `FixedWidthInteger(_:radix:)` on a slice inside a loop
///
/// The initializer parses a sign, validates every digit against the radix and returns an optional,
/// and it does all of that on each call. A 256-entry lookup table reads the same digit with one
/// load, so a loop that calls the initializer per byte pays the parser once per byte for nothing.
///
/// The sign is a correctness argument as well as a cost one. The initializer accepts a leading `+`
/// or `-`, so a reader built on it read `"+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1"` as a valid `UUID` for
/// as long as it stood.
///
/// A helper function the loop calls counts as part of the loop, because a cost behind a call is
/// still paid once per iteration. A parse of a whole string is not covered, because the slice is
/// what marks the per-byte read.
///
/// Lint: A radix initializer whose text argument is a slice, inside a loop, raises a warning.
final class NoRadixInitInLoop: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
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
        let collector = RadixParseCollector(viewMode: .sourceAccurate)
        LoopReach(body: loopBody, functions: context.freeFunctions(in: loopBody.root)).walk(
            collector)

        for parse in collector.sliceParses {
            let position = parse.call.positionAfterSkippingLeadingTrivia
            guard reported.insert(position).inserted else { continue }

            diagnose(.radixInitOnSliceInLoop(parse.type), on: parse.call)
        }
    }
}

/// Records the radix initializers of one loop, and the local bindings that hold a slice, so the
/// rule can tell a slice argument from a whole-string one.
private final class RadixParseCollector: LoopBodyVisitor {
    private struct RadixCall {
        let call: FunctionCallExprSyntax
        let type: String
        let argument: ExprSyntax
    }

    private var radixCalls: [RadixCall] = []
    private var sliceBindings: Set<String> = []

    /// The radix initializers whose text argument is a slice, in source order
    var sliceParses: [(call: FunctionCallExprSyntax, type: String)] {
        radixCalls.compactMap { entry -> (call: FunctionCallExprSyntax, type: String)? in
            if BytewiseParsing.isSlice(entry.argument) {
                return (call: entry.call, type: entry.type)
            }
            guard let name = entry.argument.as(DeclReferenceExprSyntax.self)?.baseName.text,
                  sliceBindings.contains(name) else { return nil }

            return (call: entry.call, type: entry.type)
        }
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let type = BytewiseParsing.radixTypeName(of: node),
           let text = node.arguments.first,
           text.label == nil {
            radixCalls.append(RadixCall(call: node, type: type, argument: text.expression))
        }
        return .visitChildren
    }

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        if let name = node.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
           let value = node.initializer?.value,
           BytewiseParsing.isSlice(value) { sliceBindings.insert(name) }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func radixInitOnSliceInLoop(_ type: String) -> Finding.Message {
        """
        '\(type)(_:radix:)' on a slice inside a loop parses a sign and validates every digit on \
        each call, and it accepts a leading '+' or '-' — read the digit through a 256-entry \
        lookup table
        """
    }
}
