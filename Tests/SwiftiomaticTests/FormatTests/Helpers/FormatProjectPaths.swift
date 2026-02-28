// Adapted from SwiftFormat 0.59.1 ProjectFilePaths.swift (MIT license)

import Foundation

@testable import Swiftiomatic

let formatProjectDirectory = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()  // Helpers/
  .deletingLastPathComponent()  // FormatTests/
  .deletingLastPathComponent()  // SwiftiomaticTests/
  .deletingLastPathComponent()  // Tests/
