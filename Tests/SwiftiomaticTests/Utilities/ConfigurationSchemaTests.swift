//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import GeneratorKit
import Testing

@Suite
struct ConfigurationSchemaTests {
  let schema: [String: Any]

  init() throws {
    let collector = RuleCollector()
    try collector.collectSyntaxRules(from: GeneratePaths.filePath.syntaxRulesFolder)
    try collector.collectLayoutRules(from: GeneratePaths.filePath.layoutRulesFolder)
    let generator = ConfigurationSchemaGenerator(collector: collector)
    let json = generator.generateContent()
    let parsed = try JSONSerialization.jsonObject(with: Data(json.utf8))
    self.schema = (parsed as? [String: Any]) ?? [:]
  }

  /// A lint-only rule's wrapper node sets `unevaluatedProperties: false` so the
  /// schema rejects a `rewrite` key — lint-only rules don't support rewriting.
  @Test func lintOnlyRuleRejectsRewriteProperty() throws {
    let properties = try #require(schema["properties"] as? [String: Any])
    // `noMultiTrailingClosures` is a known lint-only rule.
    let rule = try #require(properties["noMultiTrailingClosures"] as? [String: Any])
    let unevaluated = try #require(rule["unevaluatedProperties"] as? Bool)
    #expect(unevaluated == false)
  }

  /// A rewrite rule's wrapper node does NOT set `unevaluatedProperties: false`,
  /// since rewrite rules accept both `rewrite` and `lint` keys via `ruleBase`.
  @Test func rewriteRuleAllowsRewriteProperty() throws {
    let properties = try #require(schema["properties"] as? [String: Any])
    // `dropRedundantBreak` is a known rewrite rule.
    let rule = try #require(properties["dropRedundantBreak"] as? [String: Any])
    #expect(rule["unevaluatedProperties"] == nil)
  }

  /// `Lint`-typed config properties (e.g. per-finding severities) are emitted
  /// as string enums matching the base `lint` property's values.
  @Test func lintTypedSeverityPropertiesAppearInSchema() throws {
    let properties = try #require(schema["properties"] as? [String: Any])
    let rule = try #require(properties["flagExpiringTodo"] as? [String: Any])
    let custom = try #require(rule["properties"] as? [String: Any])
    for key in ["approachingExpirySeverity", "expiredSeverity", "badFormattingSeverity"] {
      let prop = try #require(custom[key] as? [String: Any], "missing \(key)")
      #expect(prop["type"] as? String == "string")
      let values = try #require(prop["enum"] as? [String])
      #expect(Set(values) == ["warn", "error", "no"])
    }
  }

  /// String-typed config properties declared without a `: String` type annotation
  /// (just `var foo = "bar"`) must still appear in the schema. The collector infers
  /// the type from the string-literal initializer.
  @Test func stringPropertiesWithoutTypeAnnotationAppearInSchema() throws {
    let properties = try #require(schema["properties"] as? [String: Any])
    let rule = try #require(properties["flagExpiringTodo"] as? [String: Any])
    let custom = try #require(rule["properties"] as? [String: Any])
    for (key, expectedDefault) in [
      ("dateFormat", "MM/dd/yyyy"),
      ("dateDelimitersOpening", "["),
      ("dateDelimitersClosing", "]"),
      ("dateSeparator", "/"),
    ] {
      let prop = try #require(custom[key] as? [String: Any], "missing \(key)")
      #expect(prop["type"] as? String == "string")
      #expect(prop["default"] as? String == expectedDefault)
    }
  }

  /// The `lintOnlyBase` definition omits the `rewrite` property entirely.
  @Test func lintOnlyBaseHasNoRewriteProperty() throws {
    let defs = try #require(schema["$defs"] as? [String: Any])
    let lintOnlyBase = try #require(defs["lintOnlyBase"] as? [String: Any])
    let baseProperties = try #require(lintOnlyBase["properties"] as? [String: Any])
    #expect(baseProperties["rewrite"] == nil)
    #expect(baseProperties["lint"] != nil)
  }
}
