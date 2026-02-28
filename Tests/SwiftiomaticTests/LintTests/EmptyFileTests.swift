import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct EmptyFileTests {
    var collectedLinter: CollectedLinter!
    var ruleStorage: RuleStorage!

    @Test(
        .disabled("setUp() not converted from XCTest — collectedLinter/ruleStorage uninitialized"),
    )
    func shouldLintEmptyFileRespectedDuringLint() {
        let ruleViolations = collectedLinter.ruleViolations(using: ruleStorage)
        #expect(ruleViolations.count == 1)
        #expect(ruleViolations.first?.ruleIdentifier == "rule_mock<LintEmptyFiles>")
    }

    @Test(
        .disabled("setUp() not converted from XCTest — collectedLinter/ruleStorage uninitialized"),
    )
    func shouldLintEmptyFileRespectedDuringCorrect() {
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

private struct RuleMock<ShouldLintEmptyFiles: ShouldLintEmptyFilesProtocol>: CorrectableRule,
    SourceKitFreeRule
{
    var configuration = SeverityConfiguration<Self>(.warning)

    static var description: RuleDescription {
        RuleDescription(
            identifier: "rule_mock<\(ShouldLintEmptyFiles.self)>",
            name: "",
            description: "",
            kind: .style,
            deprecatedAliases: ["mock"],
        )
    }

    var shouldLintEmptyFiles: Bool {
        ShouldLintEmptyFiles.shouldLintEmptyFiles
    }

    func validate(file: SwiftSource) -> [RuleViolation] {
        [RuleViolation(ruleDescription: Self.description, location: Location(file: file.path))]
    }

    func correct(file _: SwiftSource) -> Int {
        1
    }
}
