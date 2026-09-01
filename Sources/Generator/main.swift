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
    of: [paths.rulesFolder, paths.tokenFolder],
    // The dispatch audit reads the two hand-written dispatchers, so a call removed from one has to
    // re-run it.
    files: [paths.sourceFileRewriteFile, paths.tokenRewriteFile],
    skipSchema: skipSchema
)
// The stamp says the inputs are unchanged. It says nothing about the outputs, and the build fails
// on a missing one, so require every file to be on disk before skipping. That covers a deleted
// output and a run of an older generator that wrote one file fewer.
let generatedFiles = [
    paths.pipelineFile,
    paths.rewritePipelineFile,
    paths.ruleRegistryFile,
    paths.tokenStreamStubsFile,
    paths.configurationSchemaSwiftFile,
] + (skipSchema ? [] : [paths.configurationSchemaFile])
let outputsExist = generatedFiles.allSatisfy { FileManager.default.fileExists(atPath: $0.path) }

if outputsExist,
   let saved = try? String(contentsOf: stampFile, encoding: .utf8),
   saved == inputFingerprint { exit(0) }

let collector = RuleCollector()
try await collector.collect(from: paths.rulesFolder)

let rewriteHooks = RewriteHookCollector()
try await rewriteHooks.collect(from: paths.rulesFolder)

// A rule joins the rewrite pipeline by declaring an overload, so an overload nothing dispatches is
// a silent no-op. Stop the build instead.
let dispatchGaps = try RewriteDispatchAudit.gaps(
    in: rewriteHooks,
    dispatchers: RewriteDispatchAudit.handWrittenDispatchers(for: paths)
)
if !dispatchGaps.isEmpty {
    let report = dispatchGaps.map { "error: \($0)\n" }.joined()
    FileHandle.standardError.write(Data(report.utf8))
    exit(1)
}

// Generate the node-local rewrite stage from the hooks each rule declares.
let rewriteGenerator = RewritePipelineGenerator(collector: rewriteHooks)
try rewriteGenerator.generateFile(at: paths.rewritePipelineFile)

// Generate a file with extensions for the lint and format pipelines.
let pipelineGenerator = PipelineGenerator(collector: collector)
try pipelineGenerator.generateFile(at: paths.pipelineFile)

// Generate the unified rule registry (type arrays, defaults, name cache).
let registryGenerator = ConfigurationGenerator(collector: collector, rewriteHooks: rewriteHooks)
try registryGenerator.generateFile(at: paths.ruleRegistryFile)

// Generate the JSON Schema for configuration files.
let schemaGenerator = ConfigurationSchemaGenerator(collector: collector)
if !skipSchema { try schemaGenerator.generateFile(at: paths.configurationSchemaFile) }

// Generate the embedded schema Swift file for runtime validation.
let schemaSwiftGenerator = ConfigurationSchemaSwiftGenerator(schemaGenerator: schemaGenerator)
try schemaSwiftGenerator.generateFile(at: paths.configurationSchemaSwiftFile)

// Generate TokenStream forwarding stubs from TokenStream+*.swift extensions and any extension
// TokenStream blocks co-located with layout rules.
let stubCollector = TokenStreamExtensionCollector()
try await stubCollector.collect(from: paths.tokenFolder, filter: { $0.hasPrefix("TokenStream+") })
try await stubCollector.collect(from: paths.rulesFolder)
let stubGenerator = TokenStreamStubGenerator(collector: stubCollector)
try stubGenerator.generateFile(at: paths.tokenStreamStubsFile)

// Persist the fingerprint so the next run can early-exit if inputs are unchanged.
try? inputFingerprint.write(to: stampFile, atomically: true, encoding: .utf8)

/// The size and modification time of this executable, or `unknown` when neither can be read.
///
/// A rebuilt generator gets a new stamp, which retires the previous run's cached fingerprint.
private func executableStamp() -> String {
    guard let executable = Bundle.main.executableURL,
          let attributes = try? FileManager.default.attributesOfItem(atPath: executable.path)
    else { return "unknown" }

    let size = (attributes[.size] as? Int) ?? 0
    let modified = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
    return "\(size)/\(modified)"
}

/// Computes a SHA-256 over every `.swift` file under the given roots, the named files, this
/// executable, and the flags that affect output. Sort by path so the result is deterministic.
///
/// The executable counts because a change to the emitting code changes the output while every input
/// file stays byte-identical. Without it, an edit to a generator would not reach the build.
private func fingerprint(of roots: [URL], files extras: [URL], skipSchema: Bool) -> String {
    var hasher = SHA256()
    hasher.update(data: Data("schema=\(skipSchema)\n".utf8))
    hasher.update(data: Data("tool=\(executableStamp())\n".utf8))
    var files: [URL] = extras

    for root in roots {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles])
        else { continue }

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
