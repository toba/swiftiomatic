import ArgumentParser
import SwiftiomaticSyntax
import Foundation
import SwiftiomaticKit

struct FormatCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "format",
    abstract: "Format Swift source files",
  )

  @Argument(help: "Paths to format (files or directories)")
  var paths: [String] = ["."]

  @Flag(name: .long, help: "Check formatting without modifying files (exit 1 if changes needed)")
  var check = false

  @Option(name: .long, help: "Path to .swiftiomatic.yaml config file")
  var config: String?

  @Option(name: .long, parsing: .upToNextOption, help: "Exclusion patterns")
  var exclude: [String] = []

  @Flag(name: .long, help: "Preview changes without modifying files (show unified diff)")
  var dryRun = false

  @Flag(name: .long, help: "Lint mode: report issues as diagnostics without modifying files")
  var lint = false

  @Option(name: .long, help: "Output format for lint and dry-run modes: text or json")
  var format: OutputFormat = .text

  func validate() throws {
    if dryRun, check {
      throw ValidationError("--dry-run and --check are mutually exclusive")
    }
    if dryRun, lint {
      throw ValidationError("--dry-run cannot be used with --lint")
    }
  }

  func run() throws {
    let configResolver = ConfigurationResolver(configPath: config)
    let baseCfg = loadConfig()
    let files = FileDiscovery.findSwiftFiles(in: paths, additionalExclusions: exclude)

    if files.isEmpty {
      print("No Swift files found")
      return
    }

    if lint {
      try runLintMode(configResolver: configResolver, files: files)
      return
    }

    if dryRun {
      try runDryRun(configResolver: configResolver, baseCfg: baseCfg, files: files)
      return
    }

    var hasChanges = false
    var errorCount = 0

    // 1. swift-format pretty-printer (per-directory config)
    for file in files {
      do {
        let fileCfg = configResolver.configuration(for: file)
        let engine = fileCfg.makeFormatEngine()
        let source = try String(contentsOfFile: file, encoding: .utf8)
        let formatted = try engine.format(source)

        if source != formatted {
          hasChanges = true
          if check {
            print("\(file): needs formatting")
          } else {
            try formatted.write(toFile: file, atomically: true, encoding: .utf8)
            print("\(file): formatted")
          }
        }
      } catch {
        errorCount += 1
        printError("Error formatting \(file): \(error)")
      }
    }

    // 2. Correctable lint rules
    let lintCorrections = applyCorrectableLintRules(
      cfg: baseCfg, files: files, checkOnly: check,
    )
    if lintCorrections > 0 {
      hasChanges = true
    }

    if errorCount > 0 {
      throw ExitCode(2)
    }

    if check, hasChanges {
      throw ExitCode(1)
    }
  }

  private func runLintMode(configResolver: ConfigurationResolver, files: [String]) throws {
    var allDiagnostics: [Diagnostic] = []

    for file in files {
      do {
        let fileCfg = configResolver.configuration(for: file)
        let engine = fileCfg.makeFormatEngine()
        let source = try String(contentsOfFile: file, encoding: .utf8)
        let findings = try engine.lint(source, filePath: file)
        allDiagnostics.append(contentsOf: findings.map { $0.toDiagnostic() })
      } catch {
        printError("Error linting \(file): \(error)")
      }
    }

    let sorted = allDiagnostics.sorted()
    switch format {
    case .text:
      if sorted.isEmpty {
        print("No formatting issues found.")
      } else {
        print(DiagnosticFormatter.formatXcode(sorted))
        print("\nTotal: \(sorted.count) issues")
      }
    case .json:
      try print(DiagnosticFormatter.formatJSON(sorted))
    case .xcode:
      if !sorted.isEmpty {
        print(DiagnosticFormatter.formatXcode(sorted))
      }
    }

    if !sorted.isEmpty {
      throw ExitCode(1)
    }
  }

  // MARK: - Dry Run

  private func runDryRun(
    configResolver: ConfigurationResolver, baseCfg: Configuration, files: [String]
  ) throws {
    // Save originals
    var originals: [String: String] = [:]
    for file in files {
      originals[file] = try? String(contentsOfFile: file, encoding: .utf8)
    }

    // 1. Format engine (writes to disk so lint corrections see formatted content)
    for file in files {
      do {
        let fileCfg = configResolver.configuration(for: file)
        let engine = fileCfg.makeFormatEngine()
        let source = try originals[file] ?? String(contentsOfFile: file, encoding: .utf8)
        let formatted = try engine.format(source)
        if source != formatted {
          try formatted.write(toFile: file, atomically: true, encoding: .utf8)
        }
      } catch {}
    }

    // 2. Lint corrections (writes to disk)
    _ = applyCorrectableLintRules(cfg: baseCfg, files: files, checkOnly: false, silent: true)

    // Generate diffs and restore originals
    var diffs: [UnifiedDiff.FileDiff] = []
    for file in files {
      guard let original = originals[file] else { continue }
      let final = (try? String(contentsOfFile: file, encoding: .utf8)) ?? original
      if let diff = UnifiedDiff.generate(
        original: original, modified: final, filePath: file
      ) {
        diffs.append(UnifiedDiff.FileDiff(file: file, diff: diff))
      }
      try? original.write(toFile: file, atomically: true, encoding: .utf8)
    }

    if diffs.isEmpty {
      print("No changes.")
    } else {
      switch format {
      case .text, .xcode:
        print(diffs.map(\.diff).joined(separator: "\n"))
      case .json:
        try print(UnifiedDiff.formatJSON(diffs))
      }
      throw ExitCode(1)
    }
  }

  // MARK: - Correctable Lint Rules

  /// Load correctable lint rules and apply (or check) corrections on the given files.
  /// Returns the total number of corrections applied (or detected in check mode).
  private func applyCorrectableLintRules(
    cfg: Configuration, files: [String],
    checkOnly: Bool, silent: Bool = false
  ) -> Int {
    let allRules = RuleResolver.loadRules(
      enabled: cfg.enabledLintRules.isEmpty ? nil : Set(cfg.enabledLintRules),
      disabled: Set(cfg.disabledLintRules),
      ruleConfigs: cfg.lintRuleConfigs,
      formatDefaults: ["max_width": cfg.formatMaxWidth],
    )
    let correctableRules = allRules.filter { type(of: $0).isCorrectable }
    guard !correctableRules.isEmpty else { return 0 }

    let collectingRules = allRules.filter { type(of: $0).isCrossFile }
    let lintFiles = files.compactMap { SwiftSource(path: $0) }

    let storage = RuleStorage()

    // Collect phase for collecting rules
    for file in lintFiles {
      for rule in collectingRules {
        rule.collectInfo(for: file, into: storage, compilerArguments: [])
      }
    }

    // Correct phase
    var totalCorrections = 0
    for (path, file) in zip(files, lintFiles) {
      let original = checkOnly ? (try? String(contentsOfFile: path, encoding: .utf8)) : nil
      var fileCorrections = 0

      for rule in correctableRules {
        fileCorrections += rule.correct(file: file, using: storage, compilerArguments: [])
      }

      if fileCorrections > 0 {
        totalCorrections += fileCorrections
        if checkOnly {
          // Restore original contents — check mode should not modify files
          try? original?.write(toFile: path, atomically: true, encoding: .utf8)
          if !silent { print("\(path): needs lint corrections") }
        } else {
          if !silent { print("\(path): lint corrections applied") }
        }
      }
    }

    return totalCorrections
  }

  // MARK: - Helpers

  private func loadConfig() -> Configuration {
    Configuration.loadUnified(configPath: config)
  }

  private func printError(_ message: String) {
    var stderr = FileHandle.standardError
    print(message, to: &stderr)
  }
}
