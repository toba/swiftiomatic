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

let collector = ConfigurableCollector()
try collector.collectRules(from: paths.rulesDirectory)
try collector.collectSettings(from: paths.settingsDirectory)

// Generate a file with extensions for the lint and format pipelines.
let pipelineGenerator = PipelineGenerator(collector: collector)
try pipelineGenerator.generateFile(at: paths.pipelineFile)

// Generate the unified rule registry (type arrays, defaults, name cache).
let registryGenerator = ConfigurationGenerator(collector: collector)
try registryGenerator.generateFile(at: paths.ruleRegistryFile)

// Generate the JSON Schema for configuration files.
if !skipSchema {
    let schemaGenerator = ConfigurationSchemaGenerator(collector: collector)
    try schemaGenerator.generateFile(at: paths.configurationSchemaFile)
}

// Generate TokenStream forwarding stubs from TokenStream+*.swift extensions
// and any extension TokenStream blocks co-located with layout rules.
let stubCollector = TokenStreamStubCollector()
try stubCollector.collect(from: paths.tokenStreamDirectory)
try stubCollector.collectExtensions(from: paths.settingsDirectory)
let stubGenerator = TokenStreamStubGenerator(collector: stubCollector)
try stubGenerator.generateFile(at: paths.tokenStreamStubsFile)
