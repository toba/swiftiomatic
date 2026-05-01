//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import CryptoKit
import Foundation
import GeneratorKit

// Parse arguments: Generator [package-root output-dir] [--skip-schema]
let arguments = Array(CommandLine.arguments.dropFirst())
let skipSchema = arguments.contains("--skip-schema")
let positional = arguments.filter { !$0.hasPrefix("--") }

let paths: GeneratePaths
paths = positional.count >= 2
    ? GeneratePaths(
        packageRoot: URL(fileURLWithPath: positional[0]),
        outputDirectory: URL(fileURLWithPath: positional[1])
    )
    : GeneratePaths.filePath

// Content-based skip: hash all input files. If the hash matches the stamp from the previous run,
// the generator output would be byte-identical (FileGenerator already does this at the per-file
// level), so skip the entire swift-syntax parse + collection pass. Saves several seconds on
// incremental builds when rule file mtimes change but content doesn't (git checkouts, formatter
// runs).
let stampFile = paths.pipelineFile
    .deletingLastPathComponent()
    .appending(path: ".generator-fingerprint")
let inputFingerprint = fingerprint(
    of: [paths.syntaxRulesFolder, paths.layoutRulesFolder, paths.tokenFolder],
    skipSchema: skipSchema
)
if let saved = try? String(contentsOf: stampFile, encoding: .utf8), saved == inputFingerprint {
    exit(0)
}

let collector = RuleCollector()
try collector.collectSyntaxRules(from: paths.syntaxRulesFolder)
try collector.collectLayoutRules(from: paths.layoutRulesFolder)

// Generate a file with extensions for the lint and format pipelines.
let pipelineGenerator = PipelineGenerator(collector: collector)
try pipelineGenerator.generateFile(at: paths.pipelineFile)

// Generate the unified rule registry (type arrays, defaults, name cache).
let registryGenerator = ConfigurationGenerator(collector: collector)
try registryGenerator.generateFile(at: paths.ruleRegistryFile)

// Generate the JSON Schema for configuration files.
let schemaGenerator = ConfigurationSchemaGenerator(collector: collector)
if !skipSchema { try schemaGenerator.generateFile(at: paths.configurationSchemaFile) }

// Generate the embedded schema Swift file for runtime validation.
let schemaSwiftGenerator = ConfigurationSchemaSwiftGenerator(schemaGenerator: schemaGenerator)
try schemaSwiftGenerator.generateFile(at: paths.configurationSchemaSwiftFile)

// Generate TokenStream forwarding stubs from TokenStream+*.swift extensions and any extension
// TokenStream blocks co-located with layout rules.
let stubCollector = SyntaxVisitorOverrideCollector()
try stubCollector.collect(from: paths.tokenFolder)
try stubCollector.collectExtensions(from: paths.layoutRulesFolder)
let stubGenerator = TokenStreamStubGenerator(collector: stubCollector)
try stubGenerator.generateFile(at: paths.tokenStreamStubsFile)

// Persist the fingerprint so the next run can early-exit if inputs are unchanged.
try? inputFingerprint.write(to: stampFile, atomically: true, encoding: .utf8)

/// Computes a SHA-256 over every `.swift` file under the given roots, plus flags that affect
/// output. Sort by path so the result is deterministic.
private func fingerprint(of roots: [URL], skipSchema: Bool) -> String {
    var hasher = SHA256()
    hasher.update(data: Data("schema=\(skipSchema)\n".utf8))
    var files: [URL] = []

    for root in roots {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]) else { continue }
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            files.append(url)
        }
    }
    files.sort { $0.path < $1.path }

    for url in files {
        guard let data = try? Data(contentsOf: url) else { continue }
        hasher.update(data: Data(url.path.utf8))
        hasher.update(data: Data([0]))
        hasher.update(data: data)
    }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
}
