import Foundation

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

enum TestResources {
  static func path(_ calleePath: String = #filePath) -> String {
    let calleeURL = URL(filePath: calleePath, directoryHint: .notDirectory)
    let parentDir = calleeURL.deletingLastPathComponent()
    let dirName = parentDir.lastPathComponent

    if dirName == "Configuration" {
      return parentDir.appendingPathComponent("ConfigFixtures")
        .path.absolutePathStandardized()
    }

    // For Rules sub-folders (Naming, Ordering, etc.), go up to Rules/Resources/
    let grandparent = parentDir.deletingLastPathComponent()
    if grandparent.lastPathComponent == "Rules" {
      return grandparent.appendingPathComponent("Resources")
        .path.absolutePathStandardized()
    }

    return parentDir.appendingPathComponent("Resources")
      .path.absolutePathStandardized()
  }
}
