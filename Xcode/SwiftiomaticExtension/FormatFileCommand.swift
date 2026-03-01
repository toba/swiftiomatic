import XcodeKit
import Swiftiomatic

final class FormatFileCommand: NSObject, XCSourceEditorCommand {
    func perform(
        with invocation: XCSourceEditorCommandInvocation,
        completionHandler: @escaping (Error?) -> Void
    ) {
        let buffer = invocation.buffer
        let source = buffer.completeBuffer

        do {
            let formatted = try SwiftiomaticLib.format(source)
            guard formatted != source else {
                completionHandler(nil)
                return
            }

            let lines = formatted.components(separatedBy: "\n")
            buffer.lines.removeAllObjects()
            buffer.lines.addObjects(from: lines)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
}
