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

let collector = ConfigurableCollector()
try collector.collectRules(from: GeneratePaths.rulesDirectory)
try collector.collectSettings(from: GeneratePaths.settingsDirectory)

// Generate a file with extensions for the lint and format pipelines.
let pipelineGenerator = PipelineGenerator(collector: collector)
try pipelineGenerator.generateFile(at: GeneratePaths.pipelineFile)

// Generate the unified rule registry (type arrays, defaults, name cache).
let registryGenerator = ConfigurationGenerator(collector: collector)
try registryGenerator.generateFile(at: GeneratePaths.ruleRegistryFile)

// DISABLED: Documentation generation kept in RuleDocumentationGenerator.swift for future use.
// let ruleDocumentationGenerator = RuleDocumentationGenerator(collector: collector)
// try ruleDocumentationGenerator.generateFile(at: GeneratePaths.ruleDocumentationFile)

// Generate the JSON Schema for configuration files.
let schemaGenerator = ConfigurationSchemaGenerator(collector: collector)
try schemaGenerator.generateFile(at: GeneratePaths.configurationSchemaFile)
