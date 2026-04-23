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

import Foundation
import GeneratorKit

// Parse arguments: Generator [package-root output-dir] [--skip-schema]
let arguments = Array(CommandLine.arguments.dropFirst())
let skipSchema = arguments.contains("--skip-schema")
let positional = arguments.filter { !$0.hasPrefix("--") }

let paths: GeneratePaths
if positional.count >= 2 {
    paths = GeneratePaths(
        packageRoot: URL(fileURLWithPath: positional[0]),
        outputDirectory: URL(fileURLWithPath: positional[1])
    )
} else {
    paths = GeneratePaths.filePath
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
if !skipSchema {
    try schemaGenerator.generateFile(at: paths.configurationSchemaFile)
}

// Generate the embedded schema Swift file for runtime validation.
let schemaSwiftGenerator = ConfigurationSchemaSwiftGenerator(schemaGenerator: schemaGenerator)
try schemaSwiftGenerator.generateFile(at: paths.configurationSchemaSwiftFile)

// Generate TokenStream forwarding stubs from TokenStream+*.swift extensions
// and any extension TokenStream blocks co-located with layout rules.
let stubCollector = SyntaxVisitorOverrideCollector()
try stubCollector.collect(from: paths.tokenFolder)
try stubCollector.collectExtensions(from: paths.layoutRulesFolder)
let stubGenerator = TokenStreamStubGenerator(collector: stubCollector)
try stubGenerator.generateFile(at: paths.tokenStreamStubsFile)
