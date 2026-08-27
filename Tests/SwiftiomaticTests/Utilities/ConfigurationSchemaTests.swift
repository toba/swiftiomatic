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

import Testing
import Foundation
import GeneratorKit

@Suite
struct ConfigurationSchemaTests {
    /// Collecting the rules parses every rule and layout source file. Swift Testing builds one
    /// suite instance per test, so the generated JSON is held here and produced once per run.
    private static let json: String = {
        do {
            let collector = RuleCollector()
            try collector.collectSyntaxRules(from: GeneratePaths.filePath.syntaxRulesFolder)
            try collector.collectLayoutRules(from: GeneratePaths.filePath.layoutRulesFolder)
            return ConfigurationSchemaGenerator(collector: collector).generateContent()
        } catch {
            Issue.record("rule collection failed: \(error)")
            return "{}"
        }
    }()

    private let schema: [String: Any]

    init() throws {
        let parsed = try JSONSerialization.jsonObject(with: Data(Self.json.utf8))
        schema = (parsed as? [String: Any]) ?? [:]
    }

    /// A lint-only rule's wrapper node sets `unevaluatedProperties: false` so the schema rejects a
    /// `rewrite` key — lint-only rules don't support rewriting.
    @Test func lintOnlyRuleRejectsRewriteProperty() throws {
        let properties = try #require(schema["properties"] as? [String: Any])
        // `noMultiTrailingClosures` is a known lint-only rule.
        let rule = try #require(properties["noMultiTrailingClosures"] as? [String: Any])
        let unevaluated = try #require(rule["unevaluatedProperties"] as? Bool)
        #expect(unevaluated == false)
    }

    /// A rewrite rule's wrapper node does NOT set `unevaluatedProperties: false`, since rewrite
    /// rules accept both `rewrite` and `lint` keys via `ruleBase`.
    @Test func rewriteRuleAllowsRewriteProperty() throws {
        let properties = try #require(schema["properties"] as? [String: Any])
        // `dropRedundantBreak` is a known rewrite rule.
        let rule = try #require(properties["dropRedundantBreak"] as? [String: Any])
        #expect(rule["unevaluatedProperties"] == nil)
    }

    /// `Lint`-typed config properties (e.g. per-finding severities) are emitted as string enums
    /// matching the base `lint` property's values.
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

    /// String-typed config properties declared without a `: String` type annotation (just
    /// `var foo = "bar"`) must still appear in the schema. The collector infers the type from the
    /// string-literal initializer.
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

    /// Enum-typed config properties whose cases declare explicit raw values must emit those raw
    /// values (not the Swift case identifiers) in the schema's `enum` and `default`.
    @Test func enumPropertiesUseRawValuesNotCaseNames() throws {
        let properties = try #require(schema["properties"] as? [String: Any])
        let rule = try #require(properties["sortGetSetAccessors"] as? [String: Any])
        let custom = try #require(rule["properties"] as? [String: Any])
        let order = try #require(custom["order"] as? [String: Any])
        let values = try #require(order["enum"] as? [String])
        #expect(Set(values) == ["get_set", "set_get"])
        #expect(order["default"] as? String == "get_set")
    }

    /// A config property typed as an array of a struct declared in the same file emits an
    /// array-of-objects node. Without it the schema rejects the key as unknown.
    @Test func objectArrayPropertiesAppearInSchema() throws {
        let properties = try #require(schema["properties"] as? [String: Any])
        let rule = try #require(properties["pairAcquireWithDefer"] as? [String: Any])
        let custom = try #require(rule["properties"] as? [String: Any])
        let pairs = try #require(custom["pairs"] as? [String: Any])
        #expect(pairs["type"] as? String == "array")
        let items = try #require(pairs["items"] as? [String: Any])
        #expect(items["type"] as? String == "object")
        #expect(items["additionalProperties"] as? Bool == false)
        let fields = try #require(items["properties"] as? [String: Any])
        #expect(Set(fields.keys) == ["acquire", "release"])
        let required = try #require(items["required"] as? [String])
        #expect(Set(required) == ["acquire", "release"])
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
