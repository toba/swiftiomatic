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

import XCTest
@_spi(Internal) import _GenerateSwiftiomatic

final class GeneratedFilesValidityTests: XCTestCase {
  var ruleCollector: RuleCollector!

  override func setUpWithError() throws {
    ruleCollector = RuleCollector()
    try ruleCollector.collect(from: GenerateSwiftiomaticPaths.rulesDirectory)
  }

  func testGeneratedPipelineIsUpToDate() throws {
    let pipelineGenerator = PipelineGenerator(ruleCollector: ruleCollector)
    let generated = pipelineGenerator.generateContent()
    let fileContents = try String(contentsOf: GenerateSwiftiomaticPaths.pipelineFile, encoding: .utf8)
    XCTAssertEqual(
      generated,
      fileContents,
      "Pipelines+Generated.swift is out of date. Please run 'swift run generate-swiftiomatic'."
    )
  }

  func testGeneratedRegistryIsUpToDate() throws {
    let registryGenerator = RuleRegistryGenerator(ruleCollector: ruleCollector)
    let generated = registryGenerator.generateContent()
    let fileContents = try String(contentsOf: GenerateSwiftiomaticPaths.ruleRegistryFile, encoding: .utf8)
    XCTAssertEqual(
      generated,
      fileContents,
      "RuleRegistry+Generated.swift is out of date. Please run 'swift run generate-swiftiomatic'."
    )
  }

  func testGeneratedNameCacheIsUpToDate() throws {
    let ruleNameCacheGenerator = RuleNameCacheGenerator(ruleCollector: ruleCollector)
    let generated = ruleNameCacheGenerator.generateContent()
    let fileContents = try String(contentsOf: GenerateSwiftiomaticPaths.ruleNameCacheFile, encoding: .utf8)
    XCTAssertEqual(
      generated,
      fileContents,
      "RuleNameCache+Generated.swift is out of date. Please run 'swift run generate-swiftiomatic'."
    )
  }

  func testGeneratedDocumentationIsUpToDate() throws {
    let ruleDocumentationGenerator = RuleDocumentationGenerator(ruleCollector: ruleCollector)
    let generated = ruleDocumentationGenerator.generateContent()
    let fileContents = try String(contentsOf: GenerateSwiftiomaticPaths.ruleDocumentationFile, encoding: .utf8)
    XCTAssertEqual(
      generated,
      fileContents,
      "RuleDocumentation.md is out of date. Please run 'swift run generate-swiftiomatic'."
    )
  }
}
