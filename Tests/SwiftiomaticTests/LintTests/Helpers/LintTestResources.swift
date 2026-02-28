// Adapted from SwiftLint 0.63.2 TestResources.swift (MIT license)

import Foundation

@testable import Swiftiomatic

enum TestResources {
  /// Maps parent directory names to their resource subdirectory names.
  private static let resourceDirNames: [String: String] = [
    "BuiltInRules": "BuiltInRulesResources",
    "Core": "CoreResources",
    "Framework": "FrameworkResources",
  ]

  static func path(_ calleePath: String = #filePath) -> String {
    let parentDir = URL(fileURLWithPath: calleePath, isDirectory: false)
      .deletingLastPathComponent()
    let dirName = parentDir.lastPathComponent
    let resourceDir = resourceDirNames[dirName] ?? "Resources"
    return
      parentDir
      .appendingPathComponent(resourceDir)
      .path
      .absolutePathStandardized()
  }
}
