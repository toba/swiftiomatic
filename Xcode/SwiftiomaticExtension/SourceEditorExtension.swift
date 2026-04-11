import SwiftiomaticKit
import XcodeKit

final class SourceEditorExtension: NSObject, XCSourceEditorExtension {
  func extensionDidFinishLaunching() {
    // Warm the rule registry on extension launch rather than first command.
    _ = SwiftiomaticKit.ruleCatalog()
  }
}
