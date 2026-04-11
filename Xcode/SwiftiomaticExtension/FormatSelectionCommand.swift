import SwiftiomaticKit
import XcodeKit

final class FormatSelectionCommand: NSObject, XCSourceEditorCommand {
  func perform(
    with invocation: XCSourceEditorCommandInvocation,
    completionHandler: @escaping (Error?) -> Void
  ) {
    let buffer = invocation.buffer

    guard buffer.isSwiftSource else {
      completionHandler(FormatCommandError.unsupportedContentType(buffer.contentUTI))
      return
    }

    guard let selection = buffer.selections.firstObject as? XCSourceTextRange else {
      completionHandler(FormatCommandError.noSelection)
      return
    }

    let startLine = selection.start.line
    let endLine = min(selection.end.line, buffer.lines.count - 1)

    // Collect selected lines
    var selectedLines: [String] = []
    for i in startLine...endLine {
      if let line = buffer.lines[i] as? String {
        selectedLines.append(line)
      }
    }

    let source = selectedLines.joined()

    do {
      let config = loadConfiguration()
      let formatted = try Swiftiomatic.format(source, configuration: config)

      guard formatted != source else {
        completionHandler(nil)
        return
      }

      let newLines = formatted.components(separatedBy: "\n")

      // Replace the selected range with formatted lines
      let indexSet = IndexSet(integersIn: startLine...endLine)
      buffer.lines.removeObjects(at: indexSet)

      for (offset, line) in newLines.enumerated() {
        buffer.lines.insert(line, at: startLine + offset)
      }

      // Restore selection covering the new range
      let newEnd = XCSourceTextPosition(
        line: min(startLine + newLines.count - 1, buffer.lines.count - 1),
        column: 0
      )
      let newSelection = XCSourceTextRange(
        start: XCSourceTextPosition(line: startLine, column: 0),
        end: newEnd
      )
      buffer.selections.removeAllObjects()
      buffer.selections.add(newSelection)

      completionHandler(nil)
    } catch {
      completionHandler(FormatCommandError.formatFailed(underlying: error))
    }
  }
}
