import Testing
@testable import Swiftiomatic

@Suite struct RegionTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    // MARK: Regions From Files

    @Test func noRegionsInEmptyFile() {
        let file = SwiftLintFile(contents: "")
        #expect(file.regions() == [])
    }

    @Test func noRegionsInFileWithNoCommands() {
        let file = SwiftLintFile(contents: String(repeating: "\n", count: 100))
        #expect(file.regions() == [])
    }

    @Test func regionsFromSingleCommand() {
        // disable
        do {
            let file = SwiftLintFile(contents: "// sm:disable rule_id\n")
            let start = Location(file: nil, line: 1, character: 29)
            let end = Location(file: nil, line: .max, character: .max)
            #expect(
                file.regions() == [Region(
                    start: start,
                    end: end,
                    disabledRuleIdentifiers: ["rule_id"],
                )],
            )
        }
        // enable
        do {
            let file = SwiftLintFile(contents: "// sm:enable rule_id\n")
            let start = Location(file: nil, line: 1, character: 28)
            let end = Location(file: nil, line: .max, character: .max)
            #expect(file.regions() == [Region(start: start, end: end, disabledRuleIdentifiers: [])])
        }
    }

    @Test func regionsFromMatchingPairCommands() {
        // disable/enable
        do {
            let file = SwiftLintFile(
                contents: "// sm:disable rule_id\n// sm:enable rule_id\n",
            )
            #expect(
                file.regions() == [
                    Region(
                        start: Location(file: nil, line: 1, character: 29),
                        end: Location(file: nil, line: 2, character: 27),
                        disabledRuleIdentifiers: ["rule_id"],
                    ),
                    Region(
                        start: Location(file: nil, line: 2, character: 28),
                        end: Location(file: nil, line: .max, character: .max),
                        disabledRuleIdentifiers: [],
                    ),
                ],
            )
        }
        // enable/disable
        do {
            let file = SwiftLintFile(
                contents: "// sm:enable rule_id\n// sm:disable rule_id\n",
            )
            #expect(
                file.regions() == [
                    Region(
                        start: Location(file: nil, line: 1, character: 28),
                        end: Location(file: nil, line: 2, character: 28),
                        disabledRuleIdentifiers: [],
                    ),
                    Region(
                        start: Location(file: nil, line: 2, character: 29),
                        end: Location(file: nil, line: .max, character: .max),
                        disabledRuleIdentifiers: ["rule_id"],
                    ),
                ],
            )
        }
    }

    @Test func regionsFromThreeCommandForSingleLine() {
        let file = SwiftLintFile(
            contents: "// sm:disable:next 1\n" + "// sm:disable:this 2\n"
                + "// sm:disable:previous 3\n",
        )
        #expect(
            file.regions() == [
                Region(
                    start: Location(file: nil, line: 2, character: nil),
                    end: Location(file: nil, line: 2, character: .max - 1),
                    disabledRuleIdentifiers: ["1", "2", "3"],
                ),
                Region(
                    start: Location(file: nil, line: 2, character: .max),
                    end: Location(file: nil, line: .max, character: .max),
                    disabledRuleIdentifiers: [],
                ),
            ],
        )
    }

    @Test func severalRegionsFromSeveralCommands() {
        let file = SwiftLintFile(
            contents: """
            // sm:disable 1
            // sm:disable 2
            // sm:disable 3
            // sm:enable 1
            // sm:enable 2
            // sm:enable 3
            """,
        )
        #expect(
            file.regions() == [
                Region(
                    start: Location(file: nil, line: 1, character: 23),
                    end: Location(file: nil, line: 2, character: 22),
                    disabledRuleIdentifiers: ["1"],
                ),
                Region(
                    start: Location(file: nil, line: 2, character: 23),
                    end: Location(file: nil, line: 3, character: 22),
                    disabledRuleIdentifiers: ["1", "2"],
                ),
                Region(
                    start: Location(file: nil, line: 3, character: 23),
                    end: Location(file: nil, line: 4, character: 21),
                    disabledRuleIdentifiers: ["1", "2", "3"],
                ),
                Region(
                    start: Location(file: nil, line: 4, character: 22),
                    end: Location(file: nil, line: 5, character: 21),
                    disabledRuleIdentifiers: ["2", "3"],
                ),
                Region(
                    start: Location(file: nil, line: 5, character: 22),
                    end: Location(file: nil, line: 6, character: 21),
                    disabledRuleIdentifiers: ["3"],
                ),
                Region(
                    start: Location(file: nil, line: 6, character: 22),
                    end: Location(file: nil, line: .max, character: .max),
                    disabledRuleIdentifiers: [],
                ),
            ],
        )
    }
}
