import Foundation

extension String {
    var unescaped: String {
        struct UnescapingSequence: Sequence, IteratorProtocol {
            var iterator: String.Iterator
            mutating func next() -> Character? {
                guard let char = iterator.next() else { return nil }
                guard char == "\\" else { return char }
                return iterator.next()
            }
        }
        return String(UnescapingSequence(iterator: makeIterator()))
    }

    func countOfLeadingCharacters(in characterSet: CharacterSet) -> Int {
        var count = 0
        for char in utf16 {
            guard let scalar = UnicodeScalar(char), characterSet.contains(scalar) else { break }
            count += 1
        }
        return count
    }

    func trimmingTrailingCharacters(in characterSet: CharacterSet) -> String {
        guard !isEmpty else { return "" }
        var unicodeScalars = self.unicodeScalars
        while let scalar = unicodeScalars.last {
            if !characterSet.contains(scalar) {
                return String(unicodeScalars)
            }
            unicodeScalars.removeLast()
        }
        return ""
    }
}

extension String {
    func absolutePathRepresentation(rootDirectory: String = FileManager.default
        .currentDirectoryPath)
        -> String
    {
        if hasPrefix("/") { return self }
        if hasPrefix("~") { return (self as NSString).expandingTildeInPath }
        return URL(fileURLWithPath: rootDirectory)
            .appendingPathComponent(self)
            .standardizedFileURL.path
    }
}
