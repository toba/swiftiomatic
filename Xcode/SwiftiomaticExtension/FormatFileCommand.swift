import Swiftiomatic
import XcodeKit

final class FormatFileCommand: NSObject, XCSourceEditorCommand {
  func perform(
    with invocation: XCSourceEditorCommandInvocation,
    completionHandler: @escaping (Error?) -> Void
  ) {
    let buffer = invocation.buffer

    guard buffer.isSwiftSource else {
      completionHandler(FormatCommandError.unsupportedContentType(buffer.contentUTI))
      return
    }

    // Snapshot selections before mutation
    let snapshots = (buffer.selections as? [XCSourceTextRange] ?? []).map(SelectionSnapshot.init)

    let source = buffer.completeBuffer

    do {
      let config = loadConfiguration()
      let formatted = try SwiftiomaticLib.format(source, configuration: config)

      guard formatted != source else {
        completionHandler(nil)
        return
      }

      let lines = formatted.components(separatedBy: "\n")
      buffer.lines.removeAllObjects()
      buffer.lines.addObjects(from: lines)

      // Restore selections clamped to new line count
      restoreSelections(snapshots, in: buffer)

      completionHandler(nil)
    } catch {
      completionHandler(FormatCommandError.formatFailed(underlying: error))
    }
  }
}
