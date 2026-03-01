import XcodeKit
import Swiftiomatic

final class FormatSelectionCommand: NSObject, XCSourceEditorCommand {
    func perform(
        with invocation: XCSourceEditorCommandInvocation,
        completionHandler: @escaping (Error?) -> Void
    ) {
        let buffer = invocation.buffer
        let selections = buffer.selections

        guard let selection = selections.firstObject as? XCSourceTextRange else {
            completionHandler(nil)
            return
        }

        let startLine = selection.start.line
        let endLine = selection.end.line

        // Collect selected lines
        var selectedLines: [String] = []
        for i in startLine ... endLine {
            if let line = buffer.lines[i] as? String {
                selectedLines.append(line)
            }
        }

        let source = selectedLines.joined()

        do {
            let formatted = try Swiftiomatic.format(source)
            guard formatted != source else {
                completionHandler(nil)
                return
            }

            let newLines = formatted.components(separatedBy: "\n")

            // Replace the selected range with formatted lines
            let range = NSRange(location: startLine, length: endLine - startLine + 1)
            let indexSet = IndexSet(integersIn: range.location ..< range.location + range.length)
            buffer.lines.removeObjects(at: indexSet)

            for (offset, line) in newLines.enumerated() {
                buffer.lines.insert(line, at: startLine + offset)
            }

            // Update selection to cover the new range
            let newEnd = XCSourceTextPosition(line: startLine + newLines.count - 1, column: 0)
            let newSelection = XCSourceTextRange(
                start: XCSourceTextPosition(line: startLine, column: 0),
                end: newEnd
            )
            selections.removeAllObjects()
            selections.add(newSelection)

            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
}
