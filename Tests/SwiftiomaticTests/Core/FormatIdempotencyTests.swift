import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

/// Idempotency regression tests for the whole format pipeline
///
/// One `format` call must reach a fixed point. A rule that reads the source layout can disagree
/// with the layout the pretty printer then produces, so a rule can leave work that only a second
/// call finishes. Each test below pins one input shape that used to need two calls.
@Suite
struct FormatIdempotencyTests {
    private var baseConfiguration: Configuration {
        var config = Configuration.forTesting
        config[IndentationSetting.self] = .spaces(4)
        return config
    }

    private func format(_ source: String, configuration: Configuration) throws -> String {
        let coordinator = RewriteCoordinator(
            configuration: configuration,
            findingConsumer: { _ in }
        )
        var output = ""
        try coordinator.format(
            source: source,
            assumingFileURL: nil,
            selection: .infinite,
            to: &output
        )
        return output
    }

    /// Formats twice and requires the second result to match the first.
    ///
    /// - Parameters:
    ///   - input: the source to format
    ///   - configuration: the configuration both calls use
    private func expectFixedPoint(
        _ input: String,
        configuration: Configuration,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let once = try format(input, configuration: configuration)
        let twice = try format(once, configuration: configuration)
        assertStringsEqualWithDiff(
            twice,
            once,
            "the second format call changed the output",
            sourceLocation: sourceLocation
        )
    }

    /// A `guard` whose `else` brace sits on the last condition line
    ///
    /// The layout moves that `else` onto its own line, which shortens the folded form far enough to
    /// fit. The fold rule measures the form before the move, so it used to refuse on the first call
    /// and accept on the second.
    @Test func guardElseBodySettlesInOneCall() throws {
        var config = baseConfiguration
        config[AlignWrappedConditions.self] = true
        var bodies = LayoutSingleLineBodiesConfiguration()
        bodies.rewrite = true
        bodies.lint = .no
        bodies.mode = .inline
        config[LayoutSingleLineBodies.self] = bodies

        let input = """
            struct S {
                func f(_ node: Node) -> Kind {
                    guard ["==", "!="].contains(opText),
                          node.rightOperand.is(NilLiteralExprSyntax.self),
                          let leftCall = node.leftOperand.as(FunctionCallExprSyntax.self),
                          let leftMember = leftCall.calledExpression.as(MemberAccessExprSyntax.self) else {
                        return .visitChildren
                    }
                    return .skipChildren
                }
            }
            """
        try expectFixedPoint(input, configuration: config)
    }

    /// A wrapped `if` condition list whose first condition is a member-access chain
    ///
    /// The layout puts the continuations at the continuation column, not at the column of the first
    /// condition, so the decision to fold the body onto the last condition cannot read the column
    /// the source happened to use.
    @Test func wrappedIfConditionSettlesInOneCall() throws {
        var config = baseConfiguration
        config[AlignWrappedConditions.self] = true
        var bodies = LayoutSingleLineBodiesConfiguration()
        bodies.rewrite = true
        bodies.lint = .no
        bodies.mode = .inline
        config[LayoutSingleLineBodies.self] = bodies

        let input = """
            struct S {
                func f(_ call: Call) -> Bool {
                    if let member = call.calledExpression.as(MemberAccessExprSyntax.self),
                       member.declName.baseName.text == "init",
                       let identifier = member.base?.cowIdentifierExpr {
                        return identifier.isCopyOnWriteTypeName
                    }
                    return false
                }
            }
            """
        try expectFixedPoint(input, configuration: config)
    }

    /// An `if` and `else` pair written inline in the source
    ///
    /// No rule expands this pair. The layout does, because the joined form overflows. The
    /// blank-line rule reads the body before that expansion, so it used to miss the statement on
    /// the first call.
    @Test func expandedIfElseTakesItsBlankLineInOneCall() throws {
        var config = baseConfiguration
        config[InsertBlankLineBeforeControlFlowBlocks.self] = BasicRuleValue(
            rewrite: true,
            lint: .no
        )
        // the expansion has to come from the layout, so the rule that would expand the body stays
        // off
        var bodies = LayoutSingleLineBodiesConfiguration()
        bodies.rewrite = false
        bodies.lint = .no
        config[LayoutSingleLineBodies.self] = bodies

        let input = """
            struct S {
                func encode(to encoder: any Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let file { try container.encode(file, forKey: .file) }
                    else { try container.encodeNil(forKey: .file) }
                    try container.encode(severity, forKey: .severity)
                    if let rule { try container.encode(rule, forKey: .rule) }
                    else { try container.encodeNil(forKey: .rule) }
                }
            }
            """
        try expectFixedPoint(input, configuration: config)
    }

    /// A comment in a switch case that the indent rule moves one level deeper
    ///
    /// Reflow runs before that move, so it has to budget the wrap from the column the layout will
    /// use rather than from the column the trivia carries.
    @Test func commentInIndentedSwitchCaseReflowsInOneCall() throws {
        var config = baseConfiguration
        config[LineLength.self] = 60
        config[ReflowComments.self] = BasicRuleValue(rewrite: true, lint: .no)
        var cases = IndentSwitchCasesConfiguration()
        cases.rewrite = true
        cases.lint = .no
        cases.style = .indented
        config[IndentSwitchCases.self] = cases

        let input = """
            struct S {
                func f(_ k: Keyword) -> Int {
                    switch k {
                    case .a:
                        // aaaa bbbb cccc dddd eeee ffff gggg hhhh iiii
                        return 1
                    default:
                        return 0
                    }
                }
            }
            """
        try expectFixedPoint(input, configuration: config)
    }
}
