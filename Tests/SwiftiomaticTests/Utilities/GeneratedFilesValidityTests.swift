//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Testing
import GeneratorKit

@Suite
struct GeneratedFilesValidityTests {
  let ruleCollector: RuleCollector

  init() throws {
    ruleCollector = RuleCollector()
    try ruleCollector.collect(from: GeneratePaths.rulesDirectory)
  }

  @Test func generatedPipelineIsUpToDate() throws {
    let pipelineGenerator = PipelineGenerator(ruleCollector: ruleCollector)
    let generated = pipelineGenerator.generateContent()
    let fileContents = try String(contentsOf: GeneratePaths.pipelineFile, encoding: .utf8)
    #expect(
      generated == fileContents,
      "Pipelines+Generated.swift is out of date. Please run 'swift run generate-swiftiomatic'."
    )
  }

  @Test func generatedRegistryIsUpToDate() throws {
    let registryGenerator = RuleRegistryGenerator(ruleCollector: ruleCollector)
    let generated = registryGenerator.generateContent()
    let fileContents = try String(contentsOf: GeneratePaths.ruleRegistryFile, encoding: .utf8)
    #expect(
      generated == fileContents,
      "RuleRegistry+Generated.swift is out of date. Please run 'swift run generate-swiftiomatic'."
    )
  }

  @Test func generatedNameCacheIsUpToDate() throws {
    let ruleNameCacheGenerator = RuleNameCacheGenerator(ruleCollector: ruleCollector)
    let generated = ruleNameCacheGenerator.generateContent()
    let fileContents = try String(contentsOf: GeneratePaths.ruleNameCacheFile, encoding: .utf8)
    #expect(
      generated == fileContents,
      "RuleNameCache+Generated.swift is out of date. Please run 'swift run generate-swiftiomatic'."
    )
  }

}
