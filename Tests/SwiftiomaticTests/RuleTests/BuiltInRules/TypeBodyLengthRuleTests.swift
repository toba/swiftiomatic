import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct TypeBodyLengthRuleTests {
    @Test func warning() async {
        let example = Example(
            """
            actor A {
                let x = 0
                let y = 1
                let z = 2
            }
            """,
        )

        #expect(
            await violations(example, configuration: ["warning": 2, "error": 4]) == [
                RuleViolation(
                    ruleDescription: TypeBodyLengthRule.description,
                    severity: .warning,
                    location: Location(file: nil, line: 1, character: 1),
                    reason: """
                    Actor body should span 2 lines or less excluding comments and \
                    whitespace: currently spans 3 lines
                    """,
                ),
            ],
        )
    }

    @Test func error() async {
        let example = Example(
            """
            class C {
                let x = 0
                let y = 1
                let z = 2
            }
            """,
        )

        #expect(
            await violations(example, configuration: ["warning": 1, "error": 2]) == [
                RuleViolation(
                    ruleDescription: TypeBodyLengthRule.description,
                    severity: .error,
                    location: Location(file: nil, line: 1, character: 1),
                    reason: """
                    Class body should span 2 lines or less excluding comments and \
                    whitespace: currently spans 3 lines
                    """,
                ),
            ],
        )
    }

    @Test func violationMessages() async {
        var allViolations: [RuleViolation] = []
        for example in TypeBodyLengthRule.description.triggeringExamples {
            allViolations.append(contentsOf: await violations(example, configuration: ["warning": 2]))
        }
        let types = allViolations.compactMap {
            $0.reason.split(separator: " ", maxSplits: 1).first
        }

        #expect(
            types == ["Actor", "Class", "Enum", "Extension", "Protocol", "Struct"],
        )
    }

    private func violations(_ example: Example, configuration: Any? = nil) async -> [RuleViolation] {
        let config = makeConfig(configuration, TypeBodyLengthRule.identifier)!
        return await SwiftiomaticTests.violations(example, config: config)
    }
}
