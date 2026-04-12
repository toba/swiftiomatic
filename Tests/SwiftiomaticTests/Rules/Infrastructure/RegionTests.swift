import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct RegionTests {
  // MARK: Regions From Files

  @Test func noRegionsInEmptyFile() {
    let file = SwiftSource(contents: "")
    #expect(file.regions() == [])
  }

  @Test func noRegionsInFileWithNoCommands() {
    let file = SwiftSource(contents: String(repeating: "\n", count: 100))
    #expect(file.regions() == [])
  }

  @Test func regionsFromSingleCommand() {
    // disable
    do {
      let file = SwiftSource(contents: "// sm:disable rule_id\n")
      let start = Location(file: nil, line: 1, column: 22)
      let end = Location(file: nil, line: .max, column: .max)
      #expect(
        file.regions() == [
          Region(
            start: start,
            end: end,
            disabledRuleIdentifiers: ["rule_id"],
          )
        ],
      )
    }
    // enable
    do {
      let file = SwiftSource(contents: "// sm:enable rule_id\n")
      let start = Location(file: nil, line: 1, column: 21)
      let end = Location(file: nil, line: .max, column: .max)
      #expect(file.regions() == [Region(start: start, end: end, disabledRuleIdentifiers: [])])
    }
  }

  @Test func regionsFromMatchingPairCommands() {
    // disable/enable
    do {
      let file = SwiftSource(
        contents: "// sm:disable rule_id\n// sm:enable rule_id\n",
      )
      #expect(
        file.regions() == [
          Region(
            start: Location(file: nil, line: 1, column: 22),
            end: Location(file: nil, line: 2, column: 20),
            disabledRuleIdentifiers: ["rule_id"],
          ),
          Region(
            start: Location(file: nil, line: 2, column: 21),
            end: Location(file: nil, line: .max, column: .max),
            disabledRuleIdentifiers: [],
          ),
        ],
      )
    }
    // enable/disable
    do {
      let file = SwiftSource(
        contents: "// sm:enable rule_id\n// sm:disable rule_id\n",
      )
      #expect(
        file.regions() == [
          Region(
            start: Location(file: nil, line: 1, column: 21),
            end: Location(file: nil, line: 2, column: 21),
            disabledRuleIdentifiers: [],
          ),
          Region(
            start: Location(file: nil, line: 2, column: 22),
            end: Location(file: nil, line: .max, column: .max),
            disabledRuleIdentifiers: ["rule_id"],
          ),
        ],
      )
    }
  }

  @Test func regionsFromThreeCommandForSingleLine() {
    let file = SwiftSource(
      contents: "// sm:disable:next 1\n" + "// sm:disable:this 2\n"
        + "// sm:disable:previous 3\n",
    )
    #expect(
      file.regions() == [
        Region(
          start: Location(file: nil, line: 2, column: nil),
          end: Location(file: nil, line: 2, column: .max - 1),
          disabledRuleIdentifiers: ["1", "2", "3"],
        ),
        Region(
          start: Location(file: nil, line: 2, column: .max),
          end: Location(file: nil, line: .max, column: .max),
          disabledRuleIdentifiers: [],
        ),
      ],
    )
  }

  @Test func regionsFromFileCommand() {
    let file = SwiftSource(contents: "// sm:disable:file rule_id\nlet x = 1\n")
    #expect(
      file.regions() == [
        Region(
          start: Location(file: nil, line: 0, column: nil),
          end: Location(file: nil, line: .max, column: .max),
          disabledRuleIdentifiers: ["rule_id"],
        )
      ],
    )
  }

  @Test func regionsFromFileCommandMidFile() {
    let file = SwiftSource(
      contents: "let x = 1\n// sm:disable:file rule_id\nlet y = 2\n",
    )
    #expect(
      file.regions() == [
        Region(
          start: Location(file: nil, line: 0, column: nil),
          end: Location(file: nil, line: .max, column: .max),
          disabledRuleIdentifiers: ["rule_id"],
        )
      ],
    )
  }

  @Test func severalRegionsFromSeveralCommands() {
    let file = SwiftSource(
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
          start: Location(file: nil, line: 1, column: 16),
          end: Location(file: nil, line: 2, column: 15),
          disabledRuleIdentifiers: ["1"],
        ),
        Region(
          start: Location(file: nil, line: 2, column: 16),
          end: Location(file: nil, line: 3, column: 15),
          disabledRuleIdentifiers: ["1", "2"],
        ),
        Region(
          start: Location(file: nil, line: 3, column: 16),
          end: Location(file: nil, line: 4, column: 14),
          disabledRuleIdentifiers: ["1", "2", "3"],
        ),
        Region(
          start: Location(file: nil, line: 4, column: 15),
          end: Location(file: nil, line: 5, column: 14),
          disabledRuleIdentifiers: ["2", "3"],
        ),
        Region(
          start: Location(file: nil, line: 5, column: 15),
          end: Location(file: nil, line: 6, column: 14),
          disabledRuleIdentifiers: ["3"],
        ),
        Region(
          start: Location(file: nil, line: 6, column: 15),
          end: Location(file: nil, line: .max, column: .max),
          disabledRuleIdentifiers: [],
        ),
      ],
    )
  }
}
