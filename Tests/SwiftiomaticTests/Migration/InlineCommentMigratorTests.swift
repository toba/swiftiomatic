import Foundation
import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct InlineCommentMigratorTests {
    // MARK: - SwiftLint Comments

    @Test func migrateSwiftlintDisable() {
        let input = "// swiftlint:disable force_cast\nlet x = foo as! Bar\n// swiftlint:enable force_cast\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output.contains("// sm:disable force_cast"))
        #expect(output.contains("// sm:enable force_cast"))
        #expect(!output.contains("swiftlint"))
        #expect(changes.count == 2)
    }

    @Test func migrateSwiftlintDisableNext() {
        let input = "// swiftlint:disable:next force_try\nlet x = try! foo()\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output.contains("// sm:disable:next force_try"))
        #expect(changes.count == 1)
    }

    @Test func migrateSwiftlintDisableThis() {
        let input = "let x = try! foo() // swiftlint:disable:this force_try\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output.contains("// sm:disable:this force_try"))
        #expect(changes.count == 1)
    }

    @Test func migrateSwiftlintDisablePrevious() {
        let input = "let x = try! foo()\n// swiftlint:disable:previous force_try\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output.contains("// sm:disable:previous force_try"))
        #expect(changes.count == 1)
    }

    @Test func migrateSwiftlintDisableAll() {
        let input = "// swiftlint:disable all\nlet x = 1\n// swiftlint:enable all\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output.contains("// sm:disable all"))
        #expect(output.contains("// sm:enable all"))
        #expect(changes.count == 2)
    }

    @Test func migrateMultipleRulesOnOneLine() {
        let input = "// swiftlint:disable force_cast force_try line_length\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output.contains("// sm:disable force_cast force_try line_length"))
        #expect(changes.count == 1)
    }

    @Test func preserveTrailingComment() {
        let input = "// swiftlint:disable:next force_try - Needed for legacy API\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output.contains("// sm:disable:next force_try - Needed for legacy API"))
        #expect(changes.count == 1)
    }

    // MARK: - SwiftFormat Comments

    @Test func migrateSwiftformatDisable() {
        let input = "// swiftformat:disable redundantSelf\nfoo()\n// swiftformat:enable redundantSelf\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output.contains("// sm:disable explicit_self"))
        #expect(output.contains("// sm:enable explicit_self"))
        #expect(changes.count == 2)
    }

    @Test func migrateSwiftformatDisableNext() {
        let input = "// swiftformat:disable:next trailingCommas\nlet a = [1, 2, 3]\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output.contains("// sm:disable:next trailing_comma"))
        #expect(changes.count == 1)
    }

    // MARK: - No-op Cases

    @Test func noChangeForNonMatchingLines() {
        let input = "let x = 1\n// This is a regular comment\nfunc foo() {}\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output == input)
        #expect(changes.isEmpty)
    }

    @Test func noChangeForAlreadyMigratedComments() {
        let input = "// sm:disable force_cast\nlet x = foo as! Bar\n// sm:enable force_cast\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output == input)
        #expect(changes.isEmpty)
    }

    // MARK: - Warnings

    @Test func warnsOnUnmappedSwiftformatRule() {
        let input = "// swiftformat:disable completelyFakeRule\n"
        let (_, _, warnings) = InlineCommentMigrator.migrateContents(input)

        #expect(warnings.contains { $0.identifier == "completelyFakeRule" })
    }

    // MARK: - Inline with Code

    @Test func preservesCodeBeforeInlineComment() {
        let input = "let x = try! foo() // swiftlint:disable:this force_try\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output.hasPrefix("let x = try! foo() "))
        #expect(output.contains("// sm:disable:this force_try"))
        #expect(changes.count == 1)
    }

    // MARK: - File-level Disable

    @Test func migrateFileLevelDisable() {
        let input = "// swiftlint:disable:this file_length\nimport Foundation\n"
        let (output, changes, _) = InlineCommentMigrator.migrateContents(input)

        #expect(output.contains("// sm:disable:this file_length"))
        #expect(changes.count == 1)
    }
}
