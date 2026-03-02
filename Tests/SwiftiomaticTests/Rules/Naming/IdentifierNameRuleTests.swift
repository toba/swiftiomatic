import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct IdentifierNameRuleTests {
  @Test func identifierNameWithExcluded() async {
    let baseExamples = TestExamples(from: IdentifierNameRule.self)
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples + [
        Example("let Apple = 0"),
        Example("let some_apple = 0"),
        Example("let Test123 = 0"),
      ]
    let triggeringExamples =
      baseExamples.triggeringExamples + [
        Example("let ap_ple = 0"),
        Example("let AppleJuice = 0"),
      ]
    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )
    await verifyRule(description, ruleConfiguration: ["excluded": ["Apple", "some.*", ".*\\d+.*"]])
  }

  @Test func identifierNameWithAllowedSymbols() async {
    let baseExamples = TestExamples(from: IdentifierNameRule.self)
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples + [
        Example("let myLet$ = 0"),
        Example("let myLet% = 0"),
        Example("let myLet$% = 0"),
        Example("let _myLet = 0"),
      ]
    let triggeringExamples = baseExamples.triggeringExamples
      .filter { !$0.code.contains("_") }
    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )
    await verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%", "_"]])
  }

  @Test func identifierNameWithAllowedSymbolsAndViolation() async {
    let triggeringExamples = [
      Example("let ↓my_Let$ = 0")
    ]

    let description = TestExamples(from: IdentifierNameRule.self)
      .with(triggeringExamples: triggeringExamples)
    await verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
  }

  @Test func identifierNameWithIgnoreStartWithLowercase() async {
    let baseExamples = TestExamples(from: IdentifierNameRule.self)
    let triggeringExamplesToRemove = [
      Example("let ↓MyLet = 0"),
      Example("enum Foo { case ↓MyEnum }"),
      Example("func ↓IsOperator(name: String) -> Bool"),
      Example("class C { class let ↓MyLet = 0 }"),
      Example("class C { static func ↓MyFunc() {} }"),
      Example("class C { class func ↓MyFunc() {} }"),
      Example("func ↓√ (arg: Double) -> Double { arg }"),
    ]
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples
      + triggeringExamplesToRemove
      .removingViolationMarkers()
    let triggeringExamples = baseExamples.triggeringExamples
      .filter { !triggeringExamplesToRemove.contains($0) }

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": "off"])
  }

  @Test func startsWithLowercaseCheck() async {
    let triggeringExamples = [
      Example("let ↓MyLet = 0"),
      Example("enum Foo { case ↓MyCase }"),
      Example("func ↓IsOperator(name: String) -> Bool { true }"),
    ]
    let nonTriggeringExamples = [
      Example("let myLet = 0"),
      Example("enum Foo { case myCase }"),
      Example("func isOperator(name: String) -> Bool { true }"),
    ]

    await verifyRule(
      TestExamples(from: IdentifierNameRule.self).with(
        nonTriggeringExamples: nonTriggeringExamples,
        triggeringExamples: triggeringExamples,
      ),
      ruleConfiguration: ["validates_start_with_lowercase": "error"],
    )

    await verifyRule(
      TestExamples(from: IdentifierNameRule.self).with(
        nonTriggeringExamples: nonTriggeringExamples
          + triggeringExamples.removingViolationMarkers(),
        triggeringExamples: [],
      ),
      ruleConfiguration: ["validates_start_with_lowercase": "off"],
    )
  }

  @Test func startsWithLowercaseCheckInCombinationWithAllowedSymbols() async {
    await verifyRule(
      TestExamples(from: IdentifierNameRule.self).with(
        nonTriggeringExamples: [
          Example("let MyLet = 0"),
          Example("enum Foo { case myCase }"),
        ],
        triggeringExamples: [
          Example("let ↓OneLet = 0")
        ],
      ),
      ruleConfiguration: [
        "validates_start_with_lowercase": "error",
        "allowed_symbols": ["M"],
      ] as [String: any Sendable],
    )
  }

  @Test func linuxCrashOnEmojiNames() async {
    let triggeringExamples = [
      Example("let 👦🏼 = \"👦🏼\"")
    ]

    let description = TestExamples(from: IdentifierNameRule.self)
      .with(triggeringExamples: triggeringExamples)
    await verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
  }

  @Test func functionNameInViolationMessage() {
    let example = SwiftSource(contents: "func _abc(arg: String) {}")
    let violations = IdentifierNameRule().validate(file: example)
    #expect(
      violations.map(\.reason) == [
        "Function name \'_abc(arg:)\' should start with a lowercase character"
      ],
    )
  }
}
