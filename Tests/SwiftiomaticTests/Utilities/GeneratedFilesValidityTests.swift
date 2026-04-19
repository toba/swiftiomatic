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
  let collector: ConfigurableCollector

  init() throws {
    collector = ConfigurableCollector()
    try collector.collectRules(from: GeneratePaths.rulesDirectory)
    try collector.collectSettings(from: GeneratePaths.settingsDirectory)
  }

  @Test func generatedPipelineIsUpToDate() throws {
    let pipelineGenerator = PipelineGenerator(collector: collector)
    let generated = pipelineGenerator.generateContent()
    let fileContents = try String(contentsOf: GeneratePaths.pipelineFile, encoding: .utf8)
    #expect(
      generated == fileContents,
      "Pipelines+Generated.swift is out of date. Please run 'swift run generate-swiftiomatic'."
    )
  }

  @Test func generatedRegistryIsUpToDate() throws {
    let registryGenerator = ConfigurationGenerator(collector: collector)
    let generated = registryGenerator.generateContent()
    let fileContents = try String(contentsOf: GeneratePaths.ruleRegistryFile, encoding: .utf8)
    #expect(
      generated == fileContents,
      "ConfigurationRegistry+Generated.swift is out of date. Please run 'swift run generate-swiftiomatic'."
    )
  }
}
