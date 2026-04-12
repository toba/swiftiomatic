import Foundation

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

let formatProjectDirectory = URL(filePath: #filePath)
  .deletingLastPathComponent()  // Support/
  .deletingLastPathComponent()  // SwiftiomaticTests/
  .deletingLastPathComponent()  // Tests/
  .deletingLastPathComponent()  // swiftiomatic/
