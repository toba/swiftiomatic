import Foundation

@testable import SwiftiomaticKit

let formatProjectDirectory = URL(filePath: #filePath)
  .deletingLastPathComponent()  // Support/
  .deletingLastPathComponent()  // SwiftiomaticTests/
  .deletingLastPathComponent()  // Tests/
  .deletingLastPathComponent()  // swiftiomatic/
