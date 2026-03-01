import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct RuleConfigurationDescriptionTests {
    private struct MockConfiguration: RuleConfiguration {
        typealias Parent = MockRule

        @ConfigurationElement(key: "flag")
        var flag = true
        @ConfigurationElement(key: "string")
        var string = "value"
        @ConfigurationElement(key: "symbol")
        var symbol = try! Symbol(fromAny: "value", context: "rule")
        @ConfigurationElement(key: "integer")
        var integer = 2
        @ConfigurationElement(key: "null")
        var null: Int?
        @ConfigurationElement(key: "my_double")
        var myDouble = 2.1
        @ConfigurationElement(key: "severity")
        var severity = ViolationSeverity.warning
        @ConfigurationElement(
            key: "list",
            postprocessor: { list in list = list.map { $0.uppercased() } },
        )
        var list = ["string1", "string2"]
        @ConfigurationElement(
            key: "set", deprecationNotice: .suggestAlternative(
                ruleID: "my_rule",
                name: "other_opt",
            ),
        )
        var set: Set<Int> = [1, 2, 3]
        @ConfigurationElement(key: "set_of_doubles")
        var setOfDoubles: Set<Double> = [1, 2, 3, 4.7]
        @ConfigurationElement(isInline: true)
        var severityConfig = SeverityConfiguration<Parent>(.error)
        @ConfigurationElement(key: "SEVERITY")
        var renamedSeverityConfig = SeverityConfiguration<Parent>(.warning)
        @ConfigurationElement(isInline: true)
        var inlinedSeverityLevels = SeverityLevelsConfiguration<Parent>(warning: 1, error: nil)
        @ConfigurationElement(key: "levels")
        var nestedSeverityLevels = SeverityLevelsConfiguration<Parent>(warning: 3, error: 2)

        mutating func apply(configuration: [String: Any]) throws(Swiftiomatic.Issue) {
            // Set keys for elements that need them
            if $flag.key.isEmpty { $flag.key = "flag" }
            if $string.key.isEmpty { $string.key = "string" }
            if $symbol.key.isEmpty { $symbol.key = "symbol" }
            if $integer.key.isEmpty { $integer.key = "integer" }
            if $null.key.isEmpty { $null.key = "null" }
            if $myDouble.key.isEmpty { $myDouble.key = "my_double" }
            if $severity.key.isEmpty { $severity.key = "severity" }
            if $list.key.isEmpty { $list.key = "list" }
            if $set.key.isEmpty { $set.key = "set" }
            if $setOfDoubles.key.isEmpty { $setOfDoubles.key = "set_of_doubles" }
            if $renamedSeverityConfig.key.isEmpty { $renamedSeverityConfig.key = "SEVERITY" }
            if $nestedSeverityLevels.key.isEmpty { $nestedSeverityLevels.key = "levels" }
            if let value = configuration[$flag.key] { try flag.apply(
                value,
                ruleID: Parent.identifier,
            ) }
            if let value = configuration[$string.key] {
                try string.apply(value, ruleID: Parent.identifier)
            }
            if let value = configuration[$symbol.key] {
                try symbol.apply(value, ruleID: Parent.identifier)
            }
            if let value = configuration[$integer.key] {
                try integer.apply(value, ruleID: Parent.identifier)
            }
            if let value = configuration[$null.key] { try null.apply(
                value,
                ruleID: Parent.identifier,
            ) }
            if let value = configuration[$myDouble.key] {
                try myDouble.apply(value, ruleID: Parent.identifier)
            }
            if let value = configuration[$severity.key] {
                try severity.apply(value, ruleID: Parent.identifier)
            }
            if let value = configuration[$list.key] { try list.apply(
                value,
                ruleID: Parent.identifier,
            ) }
            if let value = configuration[$set.key] {
                try set.apply(value, ruleID: Parent.identifier)
            }
            if let value = configuration[$setOfDoubles.key] {
                try setOfDoubles.apply(value, ruleID: Parent.identifier)
            }
            do {
                try severityConfig.apply(configuration, ruleID: Parent.identifier)
            } catch let issue
                where issue == Swiftiomatic.Issue.nothingApplied(ruleID: Parent.identifier)
            {
                // Acceptable
            }
            if let value = configuration[$renamedSeverityConfig.key] {
                try renamedSeverityConfig.apply(value, ruleID: Parent.identifier)
            }
            do {
                try inlinedSeverityLevels.apply(configuration, ruleID: Parent.identifier)
            } catch let issue
                where issue == Swiftiomatic.Issue.nothingApplied(ruleID: Parent.identifier)
            {
                // Acceptable
            }
            if let value = configuration[$nestedSeverityLevels.key] {
                try nestedSeverityLevels.apply(value, ruleID: Parent.identifier)
            }
            if !supportedKeys.isSuperset(of: configuration.keys) {
                let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                Swiftiomatic.Issue.invalidConfigurationKeys(
                    ruleID: Parent.identifier,
                    keys: unknownKeys,
                )
                .print()
            }
        }

        func isEqualTo(_: some RuleConfiguration) -> Bool { false }
    }

    @Test func descriptionFromConfiguration() throws {
        var configuration = MockConfiguration()
        try configuration.apply(configuration: [:]) // Configure to set keys.
        let description = RuleConfigurationDescription.from(configuration: configuration)

        #expect(
            description.oneLiner() == """
            flag: true; \
            string: "value"; \
            symbol: value; \
            integer: 2; \
            my_double: 2.1; \
            severity: warning; \
            list: ["STRING1", "STRING2"]; \
            set: [1, 2, 3]; \
            set_of_doubles: [1.0, 2.0, 3.0, 4.7]; \
            severity: error; \
            SEVERITY: warning; \
            warning: 1; \
            levels: warning: 3, error: 2
            """,
        )

        #expect(
            description.markdown() == """
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            flag
            </td>
            <td>
            true
            </td>
            </tr>
            <tr>
            <td>
            string
            </td>
            <td>
            &quot;value&quot;
            </td>
            </tr>
            <tr>
            <td>
            symbol
            </td>
            <td>
            value
            </td>
            </tr>
            <tr>
            <td>
            integer
            </td>
            <td>
            2
            </td>
            </tr>
            <tr>
            <td>
            my_double
            </td>
            <td>
            2.1
            </td>
            </tr>
            <tr>
            <td>
            severity
            </td>
            <td>
            warning
            </td>
            </tr>
            <tr>
            <td>
            list
            </td>
            <td>
            [&quot;STRING1&quot;, &quot;STRING2&quot;]
            </td>
            </tr>
            <tr>
            <td>
            set
            </td>
            <td>
            [1, 2, 3]
            </td>
            </tr>
            <tr>
            <td>
            set_of_doubles
            </td>
            <td>
            [1.0, 2.0, 3.0, 4.7]
            </td>
            </tr>
            <tr>
            <td>
            severity
            </td>
            <td>
            error
            </td>
            </tr>
            <tr>
            <td>
            SEVERITY
            </td>
            <td>
            warning
            </td>
            </tr>
            <tr>
            <td>
            warning
            </td>
            <td>
            1
            </td>
            </tr>
            <tr>
            <td>
            levels
            </td>
            <td>
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            warning
            </td>
            <td>
            3
            </td>
            </tr>
            <tr>
            <td>
            error
            </td>
            <td>
            2
            </td>
            </tr>
            </tbody>
            </table>
            </td>
            </tr>
            </tbody>
            </table>
            """,
        )

        #expect(
            description.yaml() == """
            flag: true
            string: "value"
            symbol: value
            integer: 2
            my_double: 2.1
            severity: warning
            list: ["STRING1", "STRING2"]
            set: [1, 2, 3]
            set_of_doubles: [1.0, 2.0, 3.0, 4.7]
            severity: error
            SEVERITY: warning
            warning: 1
            levels:
              warning: 3
              error: 2
            """,
        )
    }

    @Test func prefersParameterDescription() {
        struct InnerMockConfiguration: RuleConfiguration {
            typealias Parent = MockRule

            var parameterDescription: RuleConfigurationDescription? {
                "visible" => .flag(true)
            }

            @ConfigurationElement(key: "invisible")
            var invisible = true

            mutating func apply(configuration _: [String: Any]) { /* conformance for test */ }

            func isEqualTo(_: some RuleConfiguration) -> Bool { false }
        }

        let description = RuleConfigurationDescription.from(configuration: InnerMockConfiguration())
        #expect(description.oneLiner() == "visible: true")
        #expect(
            description.markdown() == """
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            visible
            </td>
            <td>
            true
            </td>
            </tr>
            </tbody>
            </table>
            """,
        )
        #expect(description.yaml() == "visible: true")
    }

    @Test func emptyDescription() {
        let desc = description { RuleConfigurationOption.noOptions }

        #expect(desc.oneLiner().isEmpty)
        #expect(desc.markdown().isEmpty)
        #expect(desc.yaml().isEmpty)
    }

    @Test func basicTypes() {
        let desc = description {
            "flag" => .flag(true)
            "string" => .string("value")
            "symbol" => .symbol("value")
            "integer" => .integer(-12)
            "float" => .float(42.0)
            "severity" => .severity(.error)
            "list" => .list([.symbol("value"), .string("value"), .float(12.8)])
        }

        #expect(
            desc.markdown() == """
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            flag
            </td>
            <td>
            true
            </td>
            </tr>
            <tr>
            <td>
            string
            </td>
            <td>
            &quot;value&quot;
            </td>
            </tr>
            <tr>
            <td>
            symbol
            </td>
            <td>
            value
            </td>
            </tr>
            <tr>
            <td>
            integer
            </td>
            <td>
            -12
            </td>
            </tr>
            <tr>
            <td>
            float
            </td>
            <td>
            42.0
            </td>
            </tr>
            <tr>
            <td>
            severity
            </td>
            <td>
            error
            </td>
            </tr>
            <tr>
            <td>
            list
            </td>
            <td>
            [value, &quot;value&quot;, 12.8]
            </td>
            </tr>
            </tbody>
            </table>
            """,
        )

        #expect(
            desc.oneLiner() == """
            flag: true; string: "value"; symbol: value; integer: -12; float: 42.0; \
            severity: error; list: [value, "value", 12.8]
            """,
        )

        #expect(
            desc.yaml() == """
            flag: true
            string: "value"
            symbol: value
            integer: -12
            float: 42.0
            severity: error
            list: [value, "value", 12.8]
            """,
        )
    }

    @Test func nestedDescription() {
        let desc = description {
            "flag" => .flag(true)
            "nested 1"
                => .nest {
                    "integer" => .integer(2)
                    "nested 2"
                        => .nest {
                            "float" => .float(42.1)
                        }
                    "symbol" => .symbol("value")
                }
            "string" => .string("value")
        }

        #expect(
            desc.markdown() == """
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            flag
            </td>
            <td>
            true
            </td>
            </tr>
            <tr>
            <td>
            nested 1
            </td>
            <td>
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            integer
            </td>
            <td>
            2
            </td>
            </tr>
            <tr>
            <td>
            nested 2
            </td>
            <td>
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            float
            </td>
            <td>
            42.1
            </td>
            </tr>
            </tbody>
            </table>
            </td>
            </tr>
            <tr>
            <td>
            symbol
            </td>
            <td>
            value
            </td>
            </tr>
            </tbody>
            </table>
            </td>
            </tr>
            <tr>
            <td>
            string
            </td>
            <td>
            &quot;value&quot;
            </td>
            </tr>
            </tbody>
            </table>
            """,
        )

        #expect(
            desc.oneLiner() == """
            flag: true; nested 1: integer: 2, nested 2: float: 42.1, symbol: value; string: "value"
            """,
        )

        #expect(
            desc.yaml() == """
            flag: true
            nested 1:
              integer: 2
              nested 2:
                float: 42.1
              symbol: value
            string: "value"
            """,
        )
    }

    @Test func update() throws {
        var configuration = MockConfiguration()

        try configuration.apply(configuration: [
            "flag": false,
            "string": "new value",
            "symbol": "new symbol",
            "integer": 5,
            "null": 0,
            "my_double": 5.1,
            "severity": "error",
            "list": ["string3", "string4"],
            "set": [4, 5, 6],
            "SEVERITY": "error",
            "warning": 12,
            "levels": ["warning": 6, "error": 7],
        ])

        #expect(!(configuration.flag))
        #expect(configuration.string == "new value")
        let expectedSymbol = try Symbol(fromAny: "new symbol", context: "rule")
        #expect(configuration.symbol == expectedSymbol)
        #expect(configuration.integer == 5)
        #expect(configuration.null == 0)
        #expect(configuration.myDouble == 5.1)
        #expect(configuration.severity == .error)
        #expect(configuration.list == ["STRING3", "STRING4"])
        #expect(configuration.set == [4, 5, 6])
        #expect(configuration.severityConfig == .error)
        #expect(configuration.renamedSeverityConfig == .error)
        #expect(configuration.inlinedSeverityLevels == SeverityLevelsConfiguration(warning: 12))
        #expect(configuration.nestedSeverityLevels == SeverityLevelsConfiguration(
            warning: 6,
            error: 7,
        ))
    }

    @Test func deprecationWarning() async throws {
        let console = try await Swiftiomatic.Issue.captureConsole {
            var configuration = MockConfiguration()
            try configuration.apply(configuration: ["set": [6, 7]])
        }
        #expect(
            console
                ==
                "warning: Configuration option 'set' in 'my_rule' rule is deprecated. Use the option 'other_opt' instead.",
        )
    }

    @Test func noDeprecationWarningIfNoDeprecatedPropertySet() async throws {
        let console = try await Swiftiomatic.Issue.captureConsole {
            var configuration = MockConfiguration()
            try configuration.apply(configuration: ["flag": false])
        }
        #expect(console.isEmpty)
    }

    @Test func invalidKeys() async throws {
        let console = try await Swiftiomatic.Issue.captureConsole {
            var configuration = MockConfiguration()
            try configuration.apply(configuration: [
                "severity": "error",
                "warning": 3,
                "unknown": 1,
                "unsupported": true,
            ])
        }
        #expect(
            console
                ==
                "warning: Configuration for 'MockRule' rule contains the invalid key(s) 'unknown', 'unsupported'.",
        )
    }

    private func description(
        @RuleConfigurationDescriptionBuilder _ content: () -> RuleConfigurationDescription,
    )
        -> RuleConfigurationDescription
    { content() }
}
