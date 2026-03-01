/// String helpers for SourceKit-related parsing and path resolution.

import Foundation

extension String {
    /// The string with backslash-escape sequences removed (e.g. `\"` becomes `"`)
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

    /// Count the number of leading characters that belong to the given character set
    ///
    /// - Parameters:
    ///   - characterSet: The set of characters to match.
    func countOfLeadingCharacters(in characterSet: CharacterSet) -> Int {
        var count = 0
        for char in utf16 {
            guard let scalar = UnicodeScalar(char), characterSet.contains(scalar) else { break }
            count += 1
        }
        return count
    }

    /// Return the string with trailing characters in the given set removed
    ///
    /// - Parameters:
    ///   - characterSet: The set of characters to trim from the end.
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
    /// Resolve this path to an absolute path
    ///
    /// Handles tilde expansion and relative paths. Already-absolute paths are
    /// returned unchanged.
    ///
    /// - Parameters:
    ///   - rootDirectory: The directory to resolve relative paths against.
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
