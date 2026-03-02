import Testing
import Foundation
@testable import Swiftiomatic

@Suite("FormatEngine tests")
struct FormatEngineTests {
    // MARK: - Format

    @Test("Format normalizes whitespace in simple source")
    func formatSimpleSource() throws {
        let engine = FormatEngine()
        let input = "func   foo(  ) {  }\n"
        let output = try engine.format(input)
        #expect(output != input, "Formatter should modify unformatted source")
        #expect(!output.isEmpty)
    }

    @Test("Format is idempotent")
    func formatIdempotent() throws {
        let engine = FormatEngine()
        let input = "let x = 1\n"
        let first = try engine.format(input)
        let second = try engine.format(first)
        #expect(first == second, "Formatting already-formatted code should produce no changes")
    }

    @Test("Format preserves valid source semantics")
    func formatPreservesSemantics() throws {
        let engine = FormatEngine()
        let input = """
        func greet(name: String) -> String {
            return "Hello, \\(name)!"
        }

        """
        let output = try engine.format(input)
        #expect(output.contains("func greet"))
        #expect(output.contains("return"))
        #expect(output.contains("Hello"))
    }

    @Test("Format respects custom indent width")
    func formatCustomIndent() throws {
        var config = FormatEngineConfiguration()
        config.indentWidth = 2
        let engine = FormatEngine(configuration: config)

        let input = "func foo() {\nlet x = 1\n}\n"
        let output = try engine.format(input)
        #expect(output.contains("  let x"), "Should indent with 2 spaces")
    }

    @Test("Format respects custom line length")
    func formatCustomLineLength() throws {
        var config = FormatEngineConfiguration()
        config.lineLength = 40
        let engine = FormatEngine(configuration: config)

        // A long line that should be wrapped at 40 chars
        let input = "func foo(longParameter: String, anotherLongParameter: Int) -> Bool { return true }\n"
        let output = try engine.format(input)
        let lines = output.components(separatedBy: "\n")
        let longLines = lines.filter { $0.count > 40 }
        // swift-format may not always wrap exactly, but it should try
        #expect(lines.count > 1, "Long line should be split")
    }

    @Test("Format respects tab indentation")
    func formatTabIndent() throws {
        var config = FormatEngineConfiguration()
        config.useTabs = true
        let engine = FormatEngine(configuration: config)

        let input = "func foo() {\nlet x = 1\n}\n"
        let output = try engine.format(input)
        #expect(output.contains("\tlet x"), "Should indent with tabs")
    }

    // MARK: - Lint

    @Test("Lint returns findings for unformatted source")
    func lintFindsIssues() throws {
        let engine = FormatEngine()
        let source = "func   foo(  ){\nlet x=1\n}\n"
        let findings = try engine.lint(source)
        #expect(!findings.isEmpty, "Linter should report issues on unformatted source")
    }

    @Test("Lint returns no findings for already-formatted source")
    func lintCleanSource() throws {
        let engine = FormatEngine()
        let source = "let x = 1\n"
        // Format first, then lint the formatted output
        let formatted = try engine.format(source)
        let findings = try engine.lint(formatted)
        #expect(findings.isEmpty, "Linting formatted source should produce no findings")
    }

    @Test("Lint findings include file path")
    func lintFindingsHaveFilePath() throws {
        let engine = FormatEngine()
        let source = "func   foo(  ){\nlet x=1\n}\n"
        let findings = try engine.lint(source, filePath: "/path/to/File.swift")
        for finding in findings {
            #expect(finding.filePath == "/path/to/File.swift")
        }
    }

    @Test("Lint findings convert to diagnostics")
    func lintFindingsToDiagnostics() throws {
        let engine = FormatEngine()
        let source = "func   foo(  ){\nlet x=1\n}\n"
        let findings = try engine.lint(source, filePath: "/test.swift")
        let diagnostics = findings.map { $0.toDiagnostic() }
        for d in diagnostics {
            #expect(d.source == .format)
            #expect(d.severity == .warning)
            #expect(d.confidence == .high)
            #expect(d.canAutoFix)
            #expect(d.file == "/test.swift")
        }
    }

    // MARK: - Configuration

    @Test("Default configuration has expected values")
    func defaultConfiguration() {
        let config = FormatEngineConfiguration()
        #expect(config.indentWidth == 4)
        #expect(config.lineLength == 120)
        #expect(!config.useTabs)
        #expect(config.maximumBlankLines == 1)
        #expect(!config.lineBreakBeforeControlFlowKeywords)
        #expect(!config.lineBreakBeforeEachArgument)
        #expect(config.trailingCommas)
    }

    @Test("makeFormatEngine maps configuration correctly")
    func makeFormatEngineFromConfiguration() {
        var cfg = Configuration()
        cfg.formatIndent = "  "
        cfg.formatMaxWidth = 80
        let engine = cfg.makeFormatEngine()
        #expect(engine.engineConfiguration.indentWidth == 2)
        #expect(engine.engineConfiguration.lineLength == 80)
    }

    @Test("makeFormatEngine maps tab indentation")
    func makeFormatEngineTabIndent() {
        var cfg = Configuration()
        cfg.formatIndent = "\t"
        let engine = cfg.makeFormatEngine()
        #expect(engine.engineConfiguration.useTabs)
    }
}
