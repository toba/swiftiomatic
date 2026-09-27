import Foundation
import SwiftOperators
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
import Testing
@testable import SwiftiomaticKit

/// Pins the behavior of the fast paths in the lint and format pipelines.
///
/// Each fast path skips work when the input cannot need it. These tests prove that the skipped work
/// did not change a result.
@Suite
struct PipelineFastPathTests {
    private static let fileURL = URL(fileURLWithPath: "/tmp/test.swift")

    private func foldedTree(_ source: String) -> SourceFileSyntax {
        OperatorTable.standardOperators.foldAll(Parser.parse(source: source)) { _ in }
            .as(SourceFileSyntax.self)!
    }

    private func makeContext(
        _ tree: SourceFileSyntax,
        source: String?,
        configuration: Configuration = .forTesting,
        isLintMode: Bool = false
    ) -> Context {
        Context(
            configuration: configuration,
            operatorTable: .standardOperators,
            findingConsumer: { _ in },
            fileURL: Self.fileURL,
            sourceFileSyntax: tree,
            source: source,
            isLintMode: isLintMode
        )
    }

    // MARK: - Context.init keeps the caller's tree

    @Test func contextKeepsTheTreeTheCallerPasses() {
        let source = "let a = 1 + 2 * 3\n"
        let tree = foldedTree(source)
        let context = makeContext(tree, source: source)

        #expect(context.sourceFileSyntax.id == tree.id)
    }

    @Test func fileDeclarationIndexAnswersForTheWalkedTree() throws {
        let source = "struct Widget {}\nlet w = Widget()\n"
        let tree = foldedTree(source)
        let context = makeContext(tree, source: source)
        let declaration = try #require(tree.statements.first?.item.as(StructDeclSyntax.self))

        #expect(declaration.root.id == context.sourceFileSyntax.root.id)
        #expect(context.fileDeclarationIndex.concreteTypes.contains("Widget"))    }

    @Test func invalidSourceStillReportsParseErrors() {
        var diagnostics = 0
        let linter = LintCoordinator(configuration: .forTesting, findingConsumer: { _ in })

        #expect(throws: SwiftiomaticError.self) {
            try linter.lint(
                source: "let = \n", assumingFileURL: Self.fileURL,
                parsingDiagnosticHandler: { _, _ in diagnostics += 1 })
        }
        #expect(diagnostics > 0)
    }

    // MARK: - RuleMask skips the scan without the marker

    @Test func ignoreMarkerSearchFindsOnlyTheMarker() {
        #expect(hasIgnoreMarker("x // sm:ignore"))
        #expect(hasIgnoreMarker("sm:ignore"))
        #expect(!hasIgnoreMarker("sm:ignor"))
        #expect(!hasIgnoreMarker("// sm: ignore"))
    }

    @Test func maskWithoutMarkerTextHasNoDirectives() {
        let source = "let a = 1 // swiftlint:disable foo\n"
        let tree = foldedTree(source)
        let converter = SourceLocationConverter(fileName: "t.swift", tree: tree)
        let mask = RuleMask(
            syntaxNode: Syntax(tree), sourceLocationConverter: converter, sourceText: source)

        #expect(mask.directives.isEmpty)
    }

    @Test func maskWithMarkerTextKeepsItsDirectives() {
        let source = "struct S {\n  let a = 1 // sm:ignore noLeadingUnderscores\n}\n"
        let tree = foldedTree(source)
        let converter = SourceLocationConverter(fileName: "t.swift", tree: tree)
        let mask = RuleMask(
            syntaxNode: Syntax(tree), sourceLocationConverter: converter, sourceText: source)
        let member = tree.statements.first!.item.as(StructDeclSyntax.self)!.memberBlock.members
            .first!

        #expect(mask.directives.count == 1)
        // The trailing directive covers the member only, not the enclosing struct.
        #expect(mask.directives.first?.offsets.lowerBound
            == member.positionAfterSkippingLeadingTrivia.utf8Offset)
    }

    // MARK: - Offset gates and the empty-mask return

    @Test func emptyMaskRecordsTheQueryAndAnswersDefault() throws {
        let tree = foldedTree("let a = 1\n")
        let converter = SourceLocationConverter(fileName: "t.swift", tree: tree)
        let mask = RuleMask(syntaxNode: Syntax(tree), sourceLocationConverter: converter)
        let index = try #require(ConfigurationRegistry.ruleIndex(of: NoLeadingUnderscores.self))

        #expect(mask.ruleState(index, atOffset: 0) == .default)
        #expect(mask.queriedRules == [NoLeadingUnderscores.key])
    }

    @Test func gateOfSourceFileReadsTheEndOfTheFile() throws {
        let source = "let a = 1\n"
        let tree = foldedTree(source)
        let context = makeContext(tree, source: source)
        let gate = try #require(context.gate(for: tree))

        #expect(gate.offset == tree.endPositionBeforeTrailingTrivia.utf8Offset)
    }

    @Test func ignoreDirectiveStillSuppressesALintFinding() {
        #expect(lintFindings("func _f() {}\n", rule: NoLeadingUnderscores.self).count == 1)
        #expect(
            lintFindings(
                "func _f() {} // sm:ignore noLeadingUnderscores\n", rule: NoLeadingUnderscores.self
            ).isEmpty)
        #expect(
            lintFindings(
                "// sm:ignore:next noLeadingUnderscores\nfunc _f() {}\nfunc _g() {}\n",
                rule: NoLeadingUnderscores.self
            ).count == 1)
    }

    @Test func nodeKindWithNoEnabledRuleCreatesNoRule() {
        var configuration = Configuration.forTesting
        configuration.disableAllRules()
        let source = "func _f() {}\nstruct S { var x = 1 }\n"
        let tree = foldedTree(source)
        let pipeline = LintPipeline(
            context: makeContext(tree, source: source, configuration: configuration,
                                 isLintMode: true))
        pipeline.walk(Syntax(tree))

        #expect(pipeline.ruleCache.isEmpty)
    }

    // MARK: - Dense rule index

    @Test func severityFollowsTheConfiguredValuePerRule() {
        var configuration = Configuration.forTesting(enabledRule: "noLeadingUnderscores")
        var value = configuration[NoLeadingUnderscores.self]
        value.lint = .error
        configuration[NoLeadingUnderscores.self] = value

        let findings = lintFindings(
            "func _f() {}\n", rule: NoLeadingUnderscores.self, configuration: configuration)

        #expect(findings.map(\.severity) == [.error])
    }

    // MARK: - Lint mode dispatches only rules that lint

    @Test func lintModeDoesNotDispatchARuleWithLintOff() throws {
        var configuration = Configuration.forTesting
        configuration.disableAllRules()
        var value = configuration[DropRedundantEscaping.self]
        value.rewrite = true
        value.lint = .no
        configuration[DropRedundantEscaping.self] = value
        let index = try #require(ConfigurationRegistry.ruleIndex(of: DropRedundantEscaping.self))
        let tree = foldedTree("let a = 1\n")

        let lint = makeContext(tree, source: nil, configuration: configuration, isLintMode: true)
        let format = makeContext(tree, source: nil, configuration: configuration)

        #expect(!lint.rewriteEnabledRules[index])
        #expect(!lint.enabledRules[index])
        #expect(format.rewriteEnabledRules[index])
        #expect(format.enabledRules[index])
    }

    @Test func lintModeDispatchesARuleThatLintsWithoutRewriting() throws {
        var configuration = Configuration.forTesting
        configuration.disableAllRules()
        var value = configuration[DropRedundantEscaping.self]
        value.rewrite = false
        value.lint = .warn
        configuration[DropRedundantEscaping.self] = value
        let index = try #require(ConfigurationRegistry.ruleIndex(of: DropRedundantEscaping.self))
        let tree = foldedTree("let a = 1\n")

        let lint = makeContext(tree, source: nil, configuration: configuration, isLintMode: true)
        let format = makeContext(tree, source: nil, configuration: configuration)

        #expect(lint.rewriteEnabledRules[index])
        #expect(!format.rewriteEnabledRules[index])
        #expect(
            lintFindings(
                "func run(_ body: @escaping () -> Void) {\n  body()\n}\n",
                rule: DropRedundantEscaping.self, configuration: configuration
            ).count == 1)
    }

    // MARK: - Dense configuration storage

    @Test func ruleActivationFollowsEveryWrite() throws {
        var configuration = Configuration()
        let index = try #require(ConfigurationRegistry.ruleIndex(of: NoLeadingUnderscores.self))
        var value = configuration[NoLeadingUnderscores.self]
        value.lint = .error
        configuration[NoLeadingUnderscores.self] = value

        #expect(configuration.ruleActivation.severities[index] == .error)
        #expect(configuration.ruleActivation.lint[index])

        value.lint = .no
        configuration[NoLeadingUnderscores.self] = value

        #expect(!configuration.ruleActivation.lint[index])
        #expect(!configuration.isActive(rule: NoLeadingUnderscores.self))
    }

    @Test func decodedConfigurationActivatesItsRules() throws {
        let configuration = try Configuration(data: Data(#"{ "lineLength": 77 }"#.utf8))
        var disabled = configuration
        disabled.disableAllRules()

        #expect(configuration[LineLength.self] == 77)
        #expect(configuration.ruleActivation == Configuration().ruleActivation)
        #expect(disabled.ruleActivation.active.isEmpty)
        #expect(disabled[LineLength.self] == 77)
    }

    @Test func everyStorageSlotIsDistinct() {
        let slots = ConfigurationRegistry.storageIndexByID.values
        #expect(Set(slots).count == slots.count)
        #expect(slots.allSatisfy { $0 < ConfigurationRegistry.storageCount })
    }

    // MARK: - Deferred finding construction

    @Test func maskedFindingBuildsNoMessage() throws {
        let source = "// sm:ignore noLeadingUnderscores\nfunc _f() {}\n"
        let tree = foldedTree(source)
        let context = makeContext(
            tree, source: source,
            configuration: .forTesting(enabledRule: "noLeadingUnderscores"), isLintMode: true)
        let function = try #require(tree.statements.first?.item.as(FunctionDeclSyntax.self))
        let rule = NoLeadingUnderscores(context: context)
        var built = 0

        func message() -> Finding.Message {
            built += 1
            return "message"
        }
        rule.diagnose(message(), on: function.name)
        #expect(built == 0)

        let unmaskedSource = "func _f() {}\n"
        let unmaskedTree = foldedTree(unmaskedSource)
        let unmaskedContext = makeContext(
            unmaskedTree, source: unmaskedSource,
            configuration: .forTesting(enabledRule: "noLeadingUnderscores"), isLintMode: true)
        let unmaskedFunction = try #require(
            unmaskedTree.statements.first?.item.as(FunctionDeclSyntax.self))
        NoLeadingUnderscores(context: unmaskedContext).diagnose(message(), on: unmaskedFunction.name)
        #expect(built == 1)
    }

    @Test func warningControlMarkerIsConservative() {
        #expect(hasWarningControl("@warn(Foo, as: ignored)"))
        #expect(hasWarningControl("@diagnose(Foo, as: error)"))
        #expect(hasWarningControl("@ warn(Foo, as: error)"))
        #expect(!hasWarningControl("let level = Lint.warn // @MainActor"))
    }

    @Test func contextSkipsWarningControlWithoutTheAttribute() {
        let plain = "func f() {}\n"
        let marked = "@warn(Foo, as: ignored)\nfunc f() {}\n"

        #expect(!makeContext(foldedTree(plain), source: plain).mayContainWarningControl)
        #expect(makeContext(foldedTree(marked), source: marked).mayContainWarningControl)
        #expect(makeContext(foldedTree(plain), source: nil).mayContainWarningControl)
    }

    // MARK: - Helpers

    private func hasIgnoreMarker(_ text: String) -> Bool { IgnoreMarker.occurs(in: text.utf8.span) }

    private func hasWarningControl(_ text: String) -> Bool {
        WarningControlMarker.occurs(in: text.utf8.span)
    }

    private func lintFindings(
        _ source: String,
        rule: (some SyntaxRule).Type,
        configuration: Configuration? = nil
    ) -> [Finding] {
        let configuration = configuration
            ?? .forTesting(enabledRule: ConfigurationRegistry.ruleNameCache[ObjectIdentifier(rule)]!)
        var findings: [Finding] = []
        let linter = LintCoordinator(
            configuration: configuration, findingConsumer: { findings.append($0) })
        try? linter.lint(
            syntax: foldedTree(source), source: source, operatorTable: .standardOperators,
            assumingFileURL: Self.fileURL)
        return findings.filter { $0.category.description == rule.key }
    }
}
