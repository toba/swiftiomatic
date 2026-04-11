import Foundation
import Testing

@testable import SwiftiomaticKit

@Suite("Format configuration YAML tests")
struct FormatConfigurationTests {
    @Test("YAML format section maps to FormatEngineConfiguration")
    func yamlFormatSection() throws {
        let yaml = """
            format:
              indent: "  "
              max_width: 80
              maximum_blank_lines: 2
              line_break_before_control_flow_keywords: true
              line_break_before_each_argument: true
              trailing_commas: false
            """
        let tmpFile = NSTemporaryDirectory() + "test-config-\(UUID()).yaml"
        try yaml.write(toFile: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let config = try Configuration.loadUnified(from: tmpFile)
        #expect(config.formatIndent == "  ")
        #expect(config.formatMaxWidth == 80)
        #expect(config.formatMaximumBlankLines == 2)
        #expect(config.formatLineBreakBeforeControlFlowKeywords == true)
        #expect(config.formatLineBreakBeforeEachArgument == true)
        #expect(config.formatTrailingCommas == false)
    }

    @Test("YAML integer indent maps to spaces")
    func yamlIntegerIndent() throws {
        let yaml = """
            format:
              indent: 2
            """
        let tmpFile = NSTemporaryDirectory() + "test-config-\(UUID()).yaml"
        try yaml.write(toFile: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        let config = try Configuration.loadUnified(from: tmpFile)
        #expect(config.formatIndent == "  ")
    }

    @Test("makeFormatEngine passes all options through")
    func makeFormatEnginePassesOptions() {
        var config = Configuration()
        config.formatIndent = "  "
        config.formatMaxWidth = 80
        config.formatMaximumBlankLines = 2
        config.formatLineBreakBeforeControlFlowKeywords = true
        config.formatLineBreakBeforeEachArgument = true
        config.formatTrailingCommas = false

        let engine = config.makeFormatEngine()
        #expect(engine.engineConfiguration.indentWidth == 2)
        #expect(engine.engineConfiguration.lineLength == 80)
        #expect(engine.engineConfiguration.maximumBlankLines == 2)
        #expect(engine.engineConfiguration.lineBreakBeforeControlFlowKeywords == true)
        #expect(engine.engineConfiguration.lineBreakBeforeEachArgument == true)
        #expect(engine.engineConfiguration.trailingCommas == false)
    }

    @Test("YAML write-back round-trips format options")
    func yamlWriteBackRoundTrips() throws {
        var config = Configuration()
        config.formatIndent = "\t"
        config.formatMaxWidth = 80
        config.formatMaximumBlankLines = 2
        config.formatLineBreakBeforeControlFlowKeywords = true

        let tmpFile = NSTemporaryDirectory() + "test-config-\(UUID()).yaml"
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        try config.writeYAML(to: tmpFile)
        let reloaded = try Configuration.loadUnified(from: tmpFile)

        #expect(reloaded.formatIndent == "\t")
        #expect(reloaded.formatMaxWidth == 80)
        #expect(reloaded.formatMaximumBlankLines == 2)
        #expect(reloaded.formatLineBreakBeforeControlFlowKeywords == true)
    }

    @Test("Default config produces no format YAML section")
    func defaultConfigEmptyYAML() throws {
        let config = Configuration()
        let tmpFile = NSTemporaryDirectory() + "test-config-\(UUID()).yaml"
        defer { try? FileManager.default.removeItem(atPath: tmpFile) }

        try config.writeYAML(to: tmpFile)
        let contents = try String(contentsOfFile: tmpFile, encoding: .utf8)
        #expect(!contents.contains("format:"), "Default config should not write a format section")
    }
}

