import Foundation

extension SwiftSource {
    /// Appends a string to the file's contents and writes it to disk
    ///
    /// For virtual files the disk write is skipped. Invalidates cached state after writing.
    ///
    /// - Parameters:
    ///   - string: The string to append.
    func append(_ string: String) {
        guard string.isNotEmpty else {
            return
        }
        file.contents += string
        if isVirtual {
            return
        }
        guard let stringData = string.data(using: .utf8) else {
            Console.fatalError("can't encode '\(string)' with UTF8")
        }
        guard let path, let fileHandle = FileHandle(forWritingAtPath: path) else {
            Console.fatalError("can't write to path '\(String(describing: path))'")
        }
        _ = fileHandle.seekToEndOfFile()
        fileHandle.write(stringData)
        fileHandle.closeFile()
        invalidateCache()
    }

    /// Replaces the file's entire contents and writes them to disk atomically
    ///
    /// No-ops when the new string equals the current contents. For virtual files the disk
    /// write is skipped. Invalidates cached state after writing.
    ///
    /// - Parameters:
    ///   - string: The replacement contents.
    func write(_ string: some StringProtocol) {
        guard string != contents else {
            return
        }
        file.contents = String(string)
        if isVirtual {
            return
        }
        guard let path else {
            Console.fatalError("file needs a path to call write(_:)")
        }
        guard let stringData = String(string).data(using: .utf8) else {
            Console.fatalError("can't encode '\(string)' with UTF8")
        }
        do {
            try stringData.write(
                to: URL(fileURLWithPath: path, isDirectory: false),
                options: .atomic,
            )
        } catch {
            Console.fatalError("can't write file to \(path)")
        }
        invalidateCache()
    }
}
