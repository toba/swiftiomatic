import SwiftiomaticKit
import XcodeKit

final class SourceEditorExtension: NSObject, XCSourceEditorExtension {
  func extensionDidFinishLaunching() {
    // The extension sandbox can't load sourcekitdInProc.framework.
    disableSourceKitForTesting()
  }
}
