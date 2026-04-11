import Foundation
import Testing

@testable import Swiftiomatic

@Suite struct ConfigurationResolverTests {
  // MARK: - YAML Merging

  @Test func mergeScalarsChildOverridesParent() {
    let base: [String: Any] = ["a": 1, "b": "hello"]
    let override: [String: Any] = ["a": 2, "c": true]
    let merged = ConfigurationResolver.mergeYAML(base: base, override: override)

    #expect(merged["a"] as? Int == 2)
    #expect(merged["b"] as? String == "hello")
    #expect(merged["c"] as? Bool == true)
  }

  @Test func mergeArraysReplaceFully() {
    let base: [String: Any] = ["rules": ["a", "b", "c"]]
    let override: [String: Any] = ["rules": ["x"]]
    let merged = ConfigurationResolver.mergeYAML(base: base, override: override)

    let rules = merged["rules"] as? [String]
    #expect(rules == ["x"])
  }

  @Test func mergeNestedDictsDeepMerge() {
    let base: [String: Any] = [
      "format": ["indent": 4, "max_width": 120] as [String: Any]
    ]
    let override: [String: Any] = [
      "format": ["max_width": 80] as [String: Any]
    ]
    let merged = ConfigurationResolver.mergeYAML(base: base, override: override)

    let format = merged["format"] as? [String: Any]
    #expect(format?["indent"] as? Int == 4)
    #expect(format?["max_width"] as? Int == 80)
  }

  @Test func mergeEmptyOverridePreservesBase() {
    let base: [String: Any] = ["a": 1, "b": 2]
    let merged = ConfigurationResolver.mergeYAML(base: base, override: [:])
    #expect(merged["a"] as? Int == 1)
    #expect(merged["b"] as? Int == 2)
  }

  @Test func mergeEmptyBaseUsesOverride() {
    let override: [String: Any] = ["a": 1]
    let merged = ConfigurationResolver.mergeYAML(base: [:], override: override)
    #expect(merged["a"] as? Int == 1)
  }

  // MARK: - Config Chain Collection (with temp directories)

  @Test func singleConfigAtRoot() throws {
    try withTempConfigTree(configs: [
      ".swiftiomatic.yaml": "format:\n  max_width: 100\n"
    ]) { root in
      let resolver = ConfigurationResolver(rootDirectory: root)
      let chain = resolver.collectConfigChain(from: root)
      #expect(chain.count == 1)
    }
  }

  @Test func nestedConfigChainLeafToRoot() throws {
    try withTempConfigTree(configs: [
      ".swiftiomatic.yaml": "format:\n  max_width: 100\n",
      "Sources/.swiftiomatic.yaml": "format:\n  max_width: 80\n",
    ]) { root in
      let resolver = ConfigurationResolver(rootDirectory: root)
      let chain = resolver.collectConfigChain(from: "\(root)/Sources")
      // Leaf first, root second
      #expect(chain.count == 2)
      #expect(chain[0].contains("Sources"))
      #expect(!chain[1].contains("Sources"))
    }
  }

  @Test func inheritFalseStopsChain() throws {
    try withTempConfigTree(configs: [
      ".swiftiomatic.yaml": "format:\n  max_width: 100\n",
      "Sources/.swiftiomatic.yaml": "inherit: false\nformat:\n  max_width: 80\n",
    ]) { root in
      let resolver = ConfigurationResolver(rootDirectory: root)
      let chain = resolver.collectConfigChain(from: "\(root)/Sources")
      // Only the leaf config (inherit: false stops the walk)
      #expect(chain.count == 1)
      #expect(chain[0].contains("Sources"))
    }
  }

  @Test func noConfigReturnsEmptyChain() throws {
    let tmp = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let resolver = ConfigurationResolver(rootDirectory: tmp.path(percentEncoded: false))
    let chain = resolver.collectConfigChain(from: tmp.path(percentEncoded: false))
    #expect(chain.isEmpty)
  }

  // MARK: - Full Resolution

  @Test func resolvedConfigMergesLeafOverRoot() throws {
    try withTempConfigTree(configs: [
      ".swiftiomatic.yaml": "format:\n  max_width: 120\n  trailing_commas: false\n",
      "Sources/.swiftiomatic.yaml": "format:\n  max_width: 80\n",
    ]) { root in
      let resolver = ConfigurationResolver(rootDirectory: root)
      let filePath = "\(root)/Sources/Foo.swift"
      let cfg = resolver.configuration(for: filePath)

      // Child overrides max_width
      #expect(cfg.formatMaxWidth == 80)
      // Parent's trailing_commas is inherited
      #expect(cfg.formatTrailingCommas == false)
    }
  }

  @Test func resolvedConfigWithInheritFalseIgnoresParent() throws {
    try withTempConfigTree(configs: [
      ".swiftiomatic.yaml": "format:\n  max_width: 100\n  trailing_commas: false\n",
      "Sources/.swiftiomatic.yaml": "inherit: false\nformat:\n  max_width: 80\n",
    ]) { root in
      let resolver = ConfigurationResolver(rootDirectory: root)
      let filePath = "\(root)/Sources/Foo.swift"
      let cfg = resolver.configuration(for: filePath)

      // Child sets max_width
      #expect(cfg.formatMaxWidth == 80)
      // Parent's trailing_commas is NOT inherited — defaults apply
      #expect(cfg.formatTrailingCommas == true)
    }
  }

  @Test func cachedConfigReturnsSameInstance() throws {
    try withTempConfigTree(configs: [
      ".swiftiomatic.yaml": "format:\n  max_width: 100\n"
    ]) { root in
      let resolver = ConfigurationResolver(rootDirectory: root)
      let cfg1 = resolver.configuration(for: "\(root)/A.swift")
      let cfg2 = resolver.configuration(for: "\(root)/B.swift")
      // Same directory → same resolved config
      #expect(cfg1.formatMaxWidth == cfg2.formatMaxWidth)
    }
  }

  @Test func differentDirectoriesGetDifferentConfigs() throws {
    try withTempConfigTree(configs: [
      ".swiftiomatic.yaml": "format:\n  max_width: 120\n",
      "AppA/.swiftiomatic.yaml": "format:\n  max_width: 80\n",
      "AppB/.swiftiomatic.yaml": "format:\n  max_width: 100\n",
    ]) { root in
      let resolver = ConfigurationResolver(rootDirectory: root)
      let cfgA = resolver.configuration(for: "\(root)/AppA/Foo.swift")
      let cfgB = resolver.configuration(for: "\(root)/AppB/Bar.swift")
      #expect(cfgA.formatMaxWidth == 80)
      #expect(cfgB.formatMaxWidth == 100)
    }
  }

  @Test func threeLayerChainMergesCorrectly() throws {
    try withTempConfigTree(configs: [
      ".swiftiomatic.yaml": "format:\n  max_width: 120\n  trailing_commas: false\n",
      "Sources/.swiftiomatic.yaml": "format:\n  maximum_blank_lines: 2\n",
      "Sources/Sub/.swiftiomatic.yaml": "format:\n  max_width: 80\n",
    ]) { root in
      let resolver = ConfigurationResolver(rootDirectory: root)
      let cfg = resolver.configuration(for: "\(root)/Sources/Sub/File.swift")
      // Leaf overrides max_width
      #expect(cfg.formatMaxWidth == 80)
      // Middle layer provides maximum_blank_lines
      #expect(cfg.formatMaximumBlankLines == 2)
      // Root provides trailing_commas
      #expect(cfg.formatTrailingCommas == false)
    }
  }

  @Test func rulesArrayReplacesNotAppends() throws {
    try withTempConfigTree(configs: [
      ".swiftiomatic.yaml": "rules:\n  disabled:\n    - rule_a\n    - rule_b\n",
      "Sources/.swiftiomatic.yaml": "rules:\n  disabled:\n    - rule_c\n",
    ]) { root in
      let resolver = ConfigurationResolver(rootDirectory: root)
      let cfg = resolver.configuration(for: "\(root)/Sources/Foo.swift")
      // Child replaces disabled array, not appends
      #expect(cfg.disabledLintRules == ["rule_c"])
    }
  }

  @Test func explicitConfigPathBypassesChain() throws {
    try withTempConfigTree(configs: [
      ".swiftiomatic.yaml": "format:\n  max_width: 120\n",
      "Sources/.swiftiomatic.yaml": "format:\n  max_width: 80\n",
    ]) { root in
      let explicitPath = "\(root)/.swiftiomatic.yaml"
      let resolver = ConfigurationResolver(configPath: explicitPath)
      let cfg = resolver.configuration(for: "\(root)/Sources/Foo.swift")
      // Uses explicit config, ignoring nested
      #expect(cfg.formatMaxWidth == 120)
    }
  }

  // MARK: - Helpers

  private func withTempConfigTree(
    configs: [String: String],
    body: (String) throws -> Void,
  ) throws {
    let tmp = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let root = tmp.path(percentEncoded: false)

    for (relativePath, content) in configs {
      let fullPath = "\(root)/\(relativePath)"
      let dir = URL(filePath: fullPath).deletingLastPathComponent()
      try FileManager.default.createDirectory(
        at: dir, withIntermediateDirectories: true,
      )
      try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
    }

    try body(root)
  }
}
