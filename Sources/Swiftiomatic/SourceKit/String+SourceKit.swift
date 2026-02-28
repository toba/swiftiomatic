import Foundation

private let commentLinePrefixCharacterSet: CharacterSet = {
    var characterSet = CharacterSet.whitespacesAndNewlines
    characterSet.insert(charactersIn: "*")
    return characterSet
}()

private let newlinesCharacterSetForString = CharacterSet(charactersIn: "\u{000A}\u{000D}")

extension String {
    var isObjectiveCHeaderFile: Bool {
        ["h", "hpp", "hh"].contains(URL(fileURLWithPath: self).pathExtension)
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

    var isSwiftFile: Bool {
        URL(fileURLWithPath: self).pathExtension == "swift"
    }

    func commentBody(range: NSRange? = nil) -> String? {
        let nsString = bridge()
        let patterns: [(pattern: String, options: NSRegularExpression.Options)] = [
            ("^\\s*\\/\\*\\*\\s*(.*?)\\*\\/", [.anchorsMatchLines, .dotMatchesLineSeparators]),
            ("^\\s*\\/\\/\\/(.+)?", [.anchorsMatchLines]),
        ]
        let searchRange = range ?? NSRange(location: 0, length: nsString.length)
        for patternDef in patterns {
            // sm:disable:next force_try
            let compiledRegex = try! RegularExpression.cached(
                pattern: patternDef.pattern, options: patternDef.options,
            )
            let matches = compiledRegex.matches(in: self, range: searchRange)
            let bodyParts = matches.flatMap { match -> [String] in
                let groupCount = compiledRegex.numberOfCaptureGroups
                if groupCount < 1 { return [] }
                return (1 ... groupCount).map { groupIndex in
                    guard let sub = match.output[groupIndex].substring else { return "" }
                    let subRange = NSRange(sub.startIndex ..< sub.endIndex, in: self)
                    var lineStart = 0
                    var lineEnd = nsString.length
                    let indexRange = NSRange(location: subRange.location, length: 0)
                    nsString.getLineStart(
                        &lineStart,
                        end: &lineEnd,
                        contentsEnd: nil,
                        for: indexRange,
                    )
                    let leadingWhitespaceCountToAdd = nsString.substring(
                        with: NSRange(location: lineStart, length: lineEnd - lineStart),
                    )
                    .countOfLeadingCharacters(in: .whitespacesAndNewlines)
                    let leadingWhitespaceToAdd = String(
                        repeating: " ",
                        count: leadingWhitespaceCountToAdd,
                    )
                    let bodySubstring = String(sub)
                    if bodySubstring.contains("@name") { return "" }
                    return leadingWhitespaceToAdd + bodySubstring
                }
            }
            if !bodyParts.isEmpty {
                return bodyParts.joined(separator: "\n")
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
        var unicodeScalars = self.unicodeScalars
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
            let lineLeadingCharacters = line
                .countOfLeadingCharacters(in: commentLinePrefixCharacterSet)
            if lineLeadingCharacters < minLeadingCharacters, lineLeadingWhitespace != line.count {
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

    func capitalizingFirstLetter() -> String {
        String(prefix(1)).capitalized + String(dropFirst())
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

extension String {
    func trimmingWhitespaceAndOpeningCurlyBrace() -> String? {
        var unwantedSet = CharacterSet.whitespacesAndNewlines
        unwantedSet.insert(charactersIn: "{")
        return trimmingCharacters(in: unwantedSet)
    }

    func byteOffsetOfInnerTypeName() -> ByteCount {
        range(of: ".", options: .backwards).map { range in
            ByteCount(self[...range.lowerBound].lengthOfBytes(using: .utf8))
        } ?? 0
    }
}
