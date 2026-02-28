// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt
// Pruned to parts used by the project.

import Foundation

private let commentLinePrefixCharacterSet: CharacterSet = {
    var characterSet = CharacterSet.whitespacesAndNewlines
    characterSet.insert(charactersIn: "*")
    return characterSet
}()

private let newlinesCharacterSetForString = CharacterSet(charactersIn: "\u{000A}\u{000D}")

extension String {
    func isObjectiveCHeaderFile() -> Bool {
        ["h", "hpp", "hh"].contains(bridge().pathExtension)
    }

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

    func isSwiftFile() -> Bool {
        bridge().pathExtension == "swift"
    }

    func commentBody(range: NSRange? = nil) -> String? {
        let nsString = bridge()
        let patterns: [(pattern: String, options: NSRegularExpression.Options)] = [
            ("^\\s*\\/\\*\\*\\s*(.*?)\\*\\/", [.anchorsMatchLines, .dotMatchesLineSeparators]),
            ("^\\s*\\/\\/\\/(.+)?",           .anchorsMatchLines),
        ]
        let range = range ?? NSRange(location: 0, length: nsString.length)
        for pattern in patterns {
            let regex = try! NSRegularExpression(pattern: pattern.pattern, options: pattern.options) // sm:disable:this force_try
            let matches = regex.matches(in: self, options: [], range: range)
            let bodyParts = matches.flatMap { match -> [String] in
                let numberOfRanges = match.numberOfRanges
                if numberOfRanges < 1 { return [] }
                return (1..<numberOfRanges).map { rangeIndex in
                    let range = match.range(at: rangeIndex)
                    if range.location == NSNotFound { return "" }
                    var lineStart = 0
                    var lineEnd = nsString.length
                    let indexRange = NSRange(location: range.location, length: 0)
                    nsString.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, for: indexRange)
                    let leadingWhitespaceCountToAdd = nsString.substring(with: NSRange(location: lineStart, length: lineEnd - lineStart))
                        .countOfLeadingCharacters(in: .whitespacesAndNewlines)
                    let leadingWhitespaceToAdd = String(repeating: " ", count: leadingWhitespaceCountToAdd)
                    let bodySubstring = nsString.substring(with: range)
                    if bodySubstring.contains("@name") { return "" }
                    return leadingWhitespaceToAdd + bodySubstring
                }
            }
            if !bodyParts.isEmpty {
                return bodyParts.joined(separator: "\n").bridge()
                    .trimmingTrailingCharacters(in: .whitespacesAndNewlines)
                    .removingCommonLeadingWhitespaceFromLines()
            }
        }
        return nil
    }

    func countOfLeadingCharacters(in characterSet: CharacterSet) -> Int {
        let characterSet = characterSet.bridge()
        var count = 0
        for char in utf16 {
            if !characterSet.characterIsMember(char) { break }
            count += 1
        }
        return count
    }

    func trimmingTrailingCharacters(in characterSet: CharacterSet) -> String {
        guard !isEmpty else { return "" }
        var unicodeScalars = self.bridge().unicodeScalars
        while let scalar = unicodeScalars.last {
            if !characterSet.contains(scalar) {
                return String(unicodeScalars)
            }
            unicodeScalars.removeLast()
        }
        return ""
    }

    func removingCommonLeadingWhitespaceFromLines() -> String {
        var minLeadingCharacters = Int.max
        let lineComponents = components(separatedBy: newlinesCharacterSetForString)
        for line in lineComponents {
            let lineLeadingWhitespace = line.countOfLeadingCharacters(in: .whitespacesAndNewlines)
            let lineLeadingCharacters = line.countOfLeadingCharacters(in: commentLinePrefixCharacterSet)
            if lineLeadingCharacters < minLeadingCharacters && lineLeadingWhitespace != line.count {
                minLeadingCharacters = lineLeadingCharacters
            }
        }
        return lineComponents.map { line in
            if line.count >= minLeadingCharacters {
                return String(line[line.index(line.startIndex, offsetBy: minLeadingCharacters)...])
            }
            return line
        }.joined(separator: "\n")
    }

    internal func capitalizingFirstLetter() -> String {
        String(prefix(1)).capitalized + String(dropFirst())
    }
}

extension NSString {
    func absolutePathRepresentation(rootDirectory: String = FileManager.default.currentDirectoryPath) -> String {
        if isAbsolutePath { return expandingTildeInPath }
        return NSString.path(withComponents: [rootDirectory, bridge()]).bridge().standardizingPath
    }
}

extension String {
    internal func trimmingWhitespaceAndOpeningCurlyBrace() -> String? {
        var unwantedSet = CharacterSet.whitespacesAndNewlines
        unwantedSet.insert(charactersIn: "{")
        return trimmingCharacters(in: unwantedSet)
    }

    internal func byteOffsetOfInnerTypeName() -> ByteCount {
        range(of: ".", options: .backwards).map { range in
            ByteCount(self[...range.lowerBound].lengthOfBytes(using: .utf8))
        } ?? 0
    }
}
