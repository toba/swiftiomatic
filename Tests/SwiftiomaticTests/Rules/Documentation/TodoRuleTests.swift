import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct TodoRuleTests {
    @Test func todo() async {
        await verifyRule(TodoRule.description, commentDoesNotViolate: false)
    }

    @Test func todoMessage() async throws {
        let example = Example("fatalError() // TODO: Implement")
        let allViolations = try await violations(example)
        #expect(allViolations.count == 1)
        #expect(allViolations.first?.reason == "TODOs should be resolved (Implement)")
    }

    @Test func fixMeMessage() async throws {
        let example = Example("fatalError() // FIXME: Implement")
        let allViolations = try await violations(example)
        #expect(allViolations.count == 1)
        #expect(allViolations.first?.reason == "FIXMEs should be resolved (Implement)")
    }

    @Test func onlyFixMe() async throws {
        let example = Example(
            """
                fatalError() // TODO: Implement todo
                fatalError() // FIXME: Implement fixme
            """,
        )
        let allViolations = try await violations(example, config: ["only": ["FIXME"]])
        #expect(allViolations.count == 1)
        #expect(allViolations.first?.reason == "FIXMEs should be resolved (Implement fixme)")
    }

    @Test func onlyTodo() async throws {
        let example = Example(
            """
                fatalError() // TODO: Implement todo
                fatalError() // FIXME: Implement fixme
            """,
        )
        let allViolations = try await violations(example, config: ["only": ["TODO"]])
        #expect(allViolations.count == 1)
        #expect(allViolations.first?.reason == "TODOs should be resolved (Implement todo)")
    }

    private func violations(_ example: Example, config: Any? = nil) async throws -> [RuleViolation] {
        let config = try #require(makeConfig(config, TodoRule.identifier))
        return await SwiftiomaticTests.violations(example, config: config)
    }
}
