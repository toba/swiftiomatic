import Testing
@testable import Swiftiomatic

@Suite struct IdentifierNameRuleTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    @Test func identifierNameWithExcluded() {
        let baseDescription = IdentifierNameRule.description
        let nonTriggeringExamples =
            baseDescription.nonTriggeringExamples + [
                Example("let Apple = 0"),
                Example("let some_apple = 0"),
                Example("let Test123 = 0"),
            ]
        let triggeringExamples =
            baseDescription.triggeringExamples + [
                Example("let ap_ple = 0"),
                Example("let AppleJuice = 0"),
            ]
        let description = baseDescription.with(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: triggeringExamples,
        )
        verifyRule(description, ruleConfiguration: ["excluded": ["Apple", "some.*", ".*\\d+.*"]])
    }

    @Test func identifierNameWithAllowedSymbols() {
        let baseDescription = IdentifierNameRule.description
        let nonTriggeringExamples =
            baseDescription.nonTriggeringExamples + [
                Example("let myLet$ = 0"),
                Example("let myLet% = 0"),
                Example("let myLet$% = 0"),
                Example("let _myLet = 0"),
            ]
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !$0.code.contains("_") }
        let description = baseDescription.with(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: triggeringExamples,
        )
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%", "_"]])
    }

    @Test func identifierNameWithAllowedSymbolsAndViolation() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamples = [
            Example("let ↓my_Let$ = 0"),
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    @Test func identifierNameWithIgnoreStartWithLowercase() {
        let baseDescription = IdentifierNameRule.description
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
            baseDescription.nonTriggeringExamples + triggeringExamplesToRemove
                .removingViolationMarkers()
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": "off"])
    }

    @Test func startsWithLowercaseCheck() {
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

        verifyRule(
            IdentifierNameRule.description
                .with(triggeringExamples: triggeringExamples)
                .with(nonTriggeringExamples: nonTriggeringExamples),
            ruleConfiguration: ["validates_start_with_lowercase": "error"],
        )

        verifyRule(
            IdentifierNameRule.description
                .with(triggeringExamples: [])
                .with(
                    nonTriggeringExamples: nonTriggeringExamples
                        + triggeringExamples.removingViolationMarkers(),
                ),
            ruleConfiguration: ["validates_start_with_lowercase": "off"],
        )
    }

    @Test func startsWithLowercaseCheckInCombinationWithAllowedSymbols() {
        verifyRule(
            IdentifierNameRule.description
                .with(triggeringExamples: [
                    Example("let ↓OneLet = 0"),
                ])
                .with(nonTriggeringExamples: [
                    Example("let MyLet = 0"),
                    Example("enum Foo { case myCase }"),
                ]),
            ruleConfiguration: [
                "validates_start_with_lowercase": "error",
                "allowed_symbols": ["M"],
            ] as [String: any Sendable],
        )
    }

    @Test func linuxCrashOnEmojiNames() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamples = [
            Example("let 👦🏼 = \"👦🏼\""),
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    @Test func functionNameInViolationMessage() {
        let example = SwiftLintFile(contents: "func _abc(arg: String) {}")
        let violations = IdentifierNameRule().validate(file: example)
        #expect(
            violations.map(\.reason) == [
                "Function name \'_abc(arg:)\' should start with a lowercase character",
            ],
        )
    }
}
