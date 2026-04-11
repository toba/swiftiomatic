import Foundation
import Testing

@testable import Swiftiomatic

@Suite struct SwiftFormatConfigParserTests {
    @Test func parseDisabledRules() {
        let contents = """
            --disable redundantSelf,trailingCommas
            """
        let config = SwiftFormatConfigParser.parse(contents: contents)
        #expect(config.disabledRules == ["redundantSelf", "trailingCommas"])
    }

    @Test func parseEnabledRules() {
        let contents = """
            --enable sortImports,blankLinesBetweenScopes
            """
        let config = SwiftFormatConfigParser.parse(contents: contents)
        #expect(config.enabledRules == ["sortImports", "blankLinesBetweenScopes"])
    }

    @Test func parseRulesOption() {
        let contents = """
            --rules indent,braces,void
            """
        let config = SwiftFormatConfigParser.parse(contents: contents)
        #expect(config.enabledRules == ["indent", "braces", "void"])
    }

    @Test func parseIndent() {
        let config = SwiftFormatConfigParser.parse(contents: "--indent 2")
        #expect(config.indent == "2")

        let tabConfig = SwiftFormatConfigParser.parse(contents: "--indent tab")
        #expect(tabConfig.indent == "tab")
    }

    @Test func parseMaxWidth() {
        let config = SwiftFormatConfigParser.parse(contents: "--maxwidth 100")
        #expect(config.maxWidth == 100)
    }

    @Test func parseCommas() {
        let config = SwiftFormatConfigParser.parse(contents: "--commas always")
        #expect(config.commas == "always")

        let inlineConfig = SwiftFormatConfigParser.parse(contents: "--commas inline")
        #expect(inlineConfig.commas == "inline")
    }

    @Test func parseSwiftVersion() {
        let config = SwiftFormatConfigParser.parse(contents: "--swiftversion 5.9")
        #expect(config.swiftVersion == "5.9")
    }

    @Test func parseExcludedPaths() {
        let contents = """
            --exclude Pods,DerivedData,.build
            """
        let config = SwiftFormatConfigParser.parse(contents: contents)
        #expect(config.excludedPaths == ["Pods", "DerivedData", ".build"])
    }

    @Test func skipCommentsAndBlankLines() {
        let contents = """
            # This is a comment
            --indent 4

            # Another comment
            --maxwidth 120
            """
        let config = SwiftFormatConfigParser.parse(contents: contents)
        #expect(config.indent == "4")
        #expect(config.maxWidth == 120)
    }

    @Test func parseEmptyFile() {
        let config = SwiftFormatConfigParser.parse(contents: "")
        #expect(config.enabledRules.isEmpty)
        #expect(config.disabledRules.isEmpty)
        #expect(config.indent == nil)
    }

    @Test func parseRepresentativeConfig() {
        let contents = """
            # SwiftFormat config
            --indent 4
            --maxwidth 120
            --commas always
            --swiftversion 5.9
            --disable redundantSelf,trailingCommas
            --enable sortImports
            --exclude Pods,DerivedData
            --wraparguments before-first
            """
        let config = SwiftFormatConfigParser.parse(contents: contents)

        #expect(config.indent == "4")
        #expect(config.maxWidth == 120)
        #expect(config.commas == "always")
        #expect(config.swiftVersion == "5.9")
        #expect(config.disabledRules == ["redundantSelf", "trailingCommas"])
        #expect(config.enabledRules == ["sortImports"])
        #expect(config.excludedPaths == ["Pods", "DerivedData"])
        #expect(config.rawOptions["wraparguments"] == "before-first")
    }
}
