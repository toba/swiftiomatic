import Testing
@testable import Swiftiomatic

private let fixturesDirectory = "\(TestResources.path())/FileNameRuleFixtures"

@Suite(.rulesRegistered) struct FileNameRuleTests {
    private func validate(
        fileName: String,
        excluded: [String]? = nil,
        excludedPaths: [String]? = nil,
        prefixPattern: String? = nil,
        suffixPattern: String? = nil,
        nestedTypeSeparator: String? = nil,
        requireFullyQualifiedNames: Bool = false,
    ) throws -> [RuleViolation] {
        let file = try #require(SwiftSource(path: fixturesDirectory.stringByAppendingPathComponent(fileName)))

        var configuration = [String: Any]()

        if let excluded {
            configuration["excluded"] = excluded
        }
        if let excludedPaths {
            configuration["excluded_paths"] = excludedPaths
        }
        if let prefixPattern {
            configuration["prefix_pattern"] = prefixPattern
        }
        if let suffixPattern {
            configuration["suffix_pattern"] = suffixPattern
        }
        if let nestedTypeSeparator {
            configuration["nested_type_separator"] = nestedTypeSeparator
        }
        if requireFullyQualifiedNames {
            configuration["require_fully_qualified_names"] = requireFullyQualifiedNames
        }

        let rule = try FileNameRule(configuration: configuration)

        return rule.validate(file: file)
    }

    @Test func mainDoesNotTrigger() throws {
        #expect(try validate(fileName: "main.swift").isEmpty)
    }

    @Test func linuxMainDoesNotTrigger() throws {
        #expect(try validate(fileName: "LinuxMain.swift").isEmpty)
    }

    @Test func classNameDoesNotTrigger() throws {
        #expect(try validate(fileName: "MyClass.swift").isEmpty)
    }

    @Test func structNameDoesNotTrigger() throws {
        #expect(try validate(fileName: "MyStruct.swift").isEmpty)
    }

    @Test func macroNameDoesNotTrigger() throws {
        #expect(try validate(fileName: "MyMacro.swift").isEmpty)
    }

    @Test func extensionNameDoesNotTrigger() throws {
        #expect(try validate(fileName: "NSString+Extension.swift").isEmpty)
    }

    @Test func nestedExtensionDoesNotTrigger() throws {
        #expect(try validate(fileName: "Notification.Name+Extension.swift").isEmpty)
    }

    @Test func nestedTypeDoesNotTrigger() throws {
        #expect(try validate(fileName: "Nested.MyType.swift").isEmpty)
    }

    @Test func multipleLevelsDeeplyNestedTypeDoesNotTrigger() throws {
        #expect(try validate(fileName: "Multiple.Levels.Deeply.Nested.MyType.swift").isEmpty)
    }

    @Test func nestedTypeNotFullyQualifiedDoesNotTrigger() throws {
        #expect(try validate(fileName: "MyType.swift").isEmpty)
    }

    @Test func nestedTypeNotFullyQualifiedDoesTriggerWithOverride() throws {
        #expect(try validate(fileName: "MyType.swift", requireFullyQualifiedNames: true).isNotEmpty)
    }

    @Test func nestedTypeSeparatorDoesNotTrigger() throws {
        #expect(
            try validate(fileName: "NotificationName+Extension.swift", nestedTypeSeparator: "")
                .isEmpty,
        )
        #expect(
            try validate(fileName: "Notification__Name+Extension.swift", nestedTypeSeparator: "__")
                .isEmpty,
        )
    }

    @Test func wrongNestedTypeSeparatorDoesTrigger() throws {
        #expect(
            try validate(fileName: "Notification__Name+Extension.swift", nestedTypeSeparator: ".")
                .isNotEmpty,
        )
        #expect(
            try validate(fileName: "NotificationName+Extension.swift", nestedTypeSeparator: "__")
                .isNotEmpty,
        )
    }

    @Test func misspelledNameDoesTrigger() throws {
        #expect(try validate(fileName: "MyStructf.swift").count == 1)
    }

    @Test func misspelledNameDoesNotTriggerWithOverride() throws {
        #expect(try validate(fileName: "MyStructf.swift", excluded: ["MyStructf.swift"]).isEmpty)
    }

    @Test func mainDoesTriggerWithoutOverride() throws {
        #expect(try validate(fileName: "main.swift", excluded: []).count == 1)
    }

    @Test func customSuffixPattern() throws {
        #expect(try validate(fileName: "BoolExtension.swift", suffixPattern: "Extensions?").isEmpty)
        #expect(try validate(fileName: "BoolExtensions.swift", suffixPattern: "Extensions?")
            .isEmpty)
        #expect(
            try validate(fileName: "BoolExtensionTests.swift", suffixPattern: "Extensions?|\\+.*")
                .isEmpty,
        )
    }

    @Test func customPrefixPattern() throws {
        #expect(try validate(fileName: "ExtensionBool.swift", prefixPattern: "Extensions?").isEmpty)
        #expect(try validate(fileName: "ExtensionsBool.swift", prefixPattern: "Extensions?")
            .isEmpty)
    }

    @Test func customPrefixAndSuffixPatterns() throws {
        #expect(
            try validate(
                fileName: "SLBoolExtension.swift",
                prefixPattern: "SL",
                suffixPattern: "Extensions?|\\+.*",
            ).isEmpty,
        )

        #expect(
            try validate(
                fileName: "ExtensionBool+SwiftLint.swift",
                prefixPattern: "Extensions?",
                suffixPattern: "Extensions?|\\+.*",
            ).isEmpty,
        )
    }

    @Test func excludedDoesNotSupportRegex() throws {
        #expect(
            try validate(
                fileName: "main.swift",
                excluded: [".*"],
            ).isNotEmpty,
        )
    }

    @Test func excludedPathPatternsSupportRegex() throws {
        #expect(
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [".*"],
            ).isEmpty,
        )

        #expect(
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [".*.swift"],
            ).isEmpty,
        )

        #expect(
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [".*/FileNameRuleFixtures/.*"],
            ).isEmpty,
        )
    }

    @Test func excludedPathPatternsWithRegexDoesNotMatch() throws {
        #expect(
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [".*/OtherFolder/.*", "MAIN\\.swift"],
            ).isNotEmpty,
        )
    }

    @Test func invalidRegex() {
        #expect(throws: (any Error).self) {
            try validate(
                fileName: "NSString+Extension.swift",
                excluded: [],
                excludedPaths: ["("],
                prefixPattern: "",
                suffixPattern: "",
            )
        }
    }

    @Test func excludedPathPatternsWithMultipleRegexs() {
        #expect(throws: (any Error).self) {
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: ["/FileNameRuleFixtures/.*", "("],
            )
        }

        #expect(throws: (any Error).self) {
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: ["/FileNameRuleFixtures/.*", "(", ".*.swift"],
            )
        }
    }
}
