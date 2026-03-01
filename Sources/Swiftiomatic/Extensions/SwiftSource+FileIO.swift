import Foundation

extension SwiftSource {
    func append(_ string: String) {
        guard string.isNotEmpty else {
            return
        }
        file.contents += string
        if isVirtual {
            return
        }
        guard let stringData = string.data(using: .utf8) else {
            queuedFatalError("can't encode '\(string)' with UTF8")
        }
        guard let path, let fileHandle = FileHandle(forWritingAtPath: path) else {
            queuedFatalError("can't write to path '\(String(describing: path))'")
        }
        _ = fileHandle.seekToEndOfFile()
        fileHandle.write(stringData)
        fileHandle.closeFile()
        invalidateCache()
    }

    func write(_ string: some StringProtocol) {
        guard string != contents else {
            return
        }
        file.contents = String(string)
        if isVirtual {
            return
        }
        guard let path else {
            queuedFatalError("file needs a path to call write(_:)")
        }
        guard let stringData = String(string).data(using: .utf8) else {
            queuedFatalError("can't encode '\(string)' with UTF8")
        }
        do {
            try stringData.write(
                to: URL(fileURLWithPath: path, isDirectory: false),
                options: .atomic,
            )
        } catch {
            queuedFatalError("can't write file to \(path)")
        }
        invalidateCache()
    }
}
