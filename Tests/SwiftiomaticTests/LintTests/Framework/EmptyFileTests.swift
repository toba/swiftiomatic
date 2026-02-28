import Testing
@testable import Swiftiomatic

@Suite struct EmptyFileTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    var collectedLinter: CollectedLinter!
    var ruleStorage: RuleStorage!

    @Test func shouldLintEmptyFileRespectedDuringLint() {
        let styleViolations = collectedLinter.styleViolations(using: ruleStorage)
        #expect(styleViolations.count == 1)
        #expect(styleViolations.first?.ruleIdentifier == "rule_mock<LintEmptyFiles>")
    }

    @Test func shouldLintEmptyFileRespectedDuringCorrect() {
        let corrections = collectedLinter.correct(using: ruleStorage)
        #expect(corrections == ["rule_mock<LintEmptyFiles>": 1])
    }
}

private protocol ShouldLintEmptyFilesProtocol {
    static var shouldLintEmptyFiles: Bool { get }
}

private struct LintEmptyFiles: ShouldLintEmptyFilesProtocol {
    static var shouldLintEmptyFiles: Bool { true }
}

private struct DontLintEmptyFiles: ShouldLintEmptyFilesProtocol {
    static var shouldLintEmptyFiles: Bool { false }
}

private struct RuleMock<ShouldLintEmptyFiles: ShouldLintEmptyFilesProtocol>: CorrectableRule, SourceKitFreeRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static var description: RuleDescription {
        RuleDescription(identifier: "rule_mock<\(ShouldLintEmptyFiles.self)>",
                        name: "",
                        description: "",
                        kind: .style,
                        deprecatedAliases: ["mock"])
    }

    var shouldLintEmptyFiles: Bool {
        ShouldLintEmptyFiles.shouldLintEmptyFiles
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        [StyleViolation(ruleDescription: Self.description, location: Location(file: file.path))]
    }

    func correct(file _: SwiftLintFile) -> Int {
        1
    }
}
