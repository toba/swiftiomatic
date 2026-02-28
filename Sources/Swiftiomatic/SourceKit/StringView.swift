import Foundation

extension RandomAccessCollection {
    fileprivate func indexAssumingSorted(comparing: (Element) throws -> ComparisonResult) rethrows
        -> Index?
    {
        guard !isEmpty else { return nil }

        var lowerBound = startIndex
        var upperBound = index(before: endIndex)
        var midIndex: Index

        while lowerBound <= upperBound {
            let boundDistance = distance(from: lowerBound, to: upperBound)
            midIndex = index(lowerBound, offsetBy: boundDistance / 2)
            let midElem = self[midIndex]

            switch try comparing(midElem) {
                case .orderedDescending: lowerBound = index(midIndex, offsetBy: 1)
                case .orderedAscending: upperBound = index(midIndex, offsetBy: -1)
                case .orderedSame: return midIndex
            }
        }

        return nil
    }
}

private let newlinesCharacterSet = CharacterSet(charactersIn: "\u{000A}\u{000D}")

/// Structure that precalculates lines for the specified string and then uses this information for
/// ByteRange to NSRange and NSRange to ByteRange operations
struct StringView {
    let nsString: NSString
    let range: NSRange
    let string: String
    let lines: [Line]

    let utf8View: String.UTF8View
    let utf16View: String.UTF16View

    init(_ string: String) {
        self.init(string, string as NSString)
    }

    init(_ nsstring: NSString) {
        self.init(nsstring as String, nsstring)
    }

    private init(_ string: String, _ nsString: NSString) {
        self.string = string
        self.nsString = nsString
        range = Foundation.NSRange(location: 0, length: nsString.length)

        utf8View = string.utf8
        utf16View = string.utf16

        var utf16CountSoFar = 0
        var bytesSoFar: ByteCount = 0
        var lines = [Line]()
        let lineContents = string.components(separatedBy: newlinesCharacterSet)
        let endsWithNewLineCharacter: Bool
        if let lastChar = string.utf16.last,
           let lastCharScalar = UnicodeScalar(lastChar)
        {
            endsWithNewLineCharacter = newlinesCharacterSet.contains(lastCharScalar)
        } else {
            endsWithNewLineCharacter = false
        }
        let effectiveLines = endsWithNewLineCharacter ? lineContents.dropLast() : lineContents[...]
        for (index, content) in effectiveLines.enumerated() {
            let index = index + 1
            let rangeStart = utf16CountSoFar
            let utf16Count = content.utf16.count
            utf16CountSoFar += utf16Count

            let byteRangeStart = bytesSoFar
            let byteCount = ByteCount(content.lengthOfBytes(using: .utf8))
            bytesSoFar += byteCount

            let newlineLength = index != lineContents.count ? 1 : 0

            let line = Line(
                index: index,
                content: content,
                range: Foundation.NSRange(location: rangeStart, length: utf16Count + newlineLength),
                byteRange: ByteRange(
                    location: byteRangeStart,
                    length: byteCount + ByteCount(newlineLength),
                ),
            )
            lines.append(line)

            utf16CountSoFar += newlineLength
            bytesSoFar += ByteCount(newlineLength)
        }
        self.lines = lines
    }

    func substring(with range: NSRange) -> String {
        nsString.substring(with: range)
    }

    func substringWithByteRange(_ byteRange: ByteRange) -> String? {
        byteRangeToNSRange(byteRange).map(nsString.substring)
    }

    func byteRangeToNSRange(_ byteRange: ByteRange) -> NSRange? {
        guard !string.isEmpty else { return nil }
        let utf16Start = location(fromByteOffset: byteRange.location)
        if byteRange.length == 0 {
            return Foundation.NSRange(location: utf16Start, length: 0)
        }
        let utf16End = location(fromByteOffset: byteRange.upperBound)
        return Foundation.NSRange(location: utf16Start, length: utf16End - utf16Start)
    }

    func byteOffset(fromLocation location: Int) -> ByteCount {
        if lines.isEmpty { return 0 }
        let index = lines.indexAssumingSorted { line in
            if location < line.range.location {
                return .orderedAscending
            } else if location >= line.range.location + line.range.length {
                return .orderedDescending
            }
            return .orderedSame
        }
        guard let line = (index.map { lines[$0] } ?? lines.last) else {
            fatalError("No line found for character location \(location)")
        }
        let diff = location - line.range.location
        if diff == 0 {
            return line.byteRange.location
        } else if line.range.length == diff {
            return line.byteRange.upperBound
        }
        let utf16View = line.content.utf16
        let endUTF8index = utf16View.index(
            utf16View.startIndex, offsetBy: diff, limitedBy: utf16View.endIndex,
        )!
            .samePosition(in: line.content.utf8)!
        let byteDiff = line.content.utf8.distance(
            from: line.content.utf8.startIndex,
            to: endUTF8index,
        )
        return ByteCount(line.byteRange.location.value + byteDiff)
    }

    func NSRangeToByteRange(start: Int, length: Int) -> ByteRange? {
        let startUTF16Index = utf16View.index(utf16View.startIndex, offsetBy: start)
        let endUTF16Index = utf16View.index(startUTF16Index, offsetBy: length)

        guard let startUTF8Index = startUTF16Index.samePosition(in: utf8View),
              let endUTF8Index = endUTF16Index.samePosition(in: utf8View)
        else {
            return nil
        }

        let length = utf8View.distance(from: startUTF8Index, to: endUTF8Index)
        return ByteRange(location: byteOffset(fromLocation: start), length: ByteCount(length))
    }

    func NSRangeToByteRange(_ range: NSRange) -> ByteRange? {
        NSRangeToByteRange(start: range.location, length: range.length)
    }

    func location(fromByteOffset byteOffset: ByteCount) -> Int {
        if lines.isEmpty { return 0 }
        let index = lines.indexAssumingSorted { line in
            if byteOffset < line.byteRange.location {
                return .orderedAscending
            } else if byteOffset >= line.byteRange.upperBound {
                return .orderedDescending
            }
            return .orderedSame
        }
        guard let line = (index.map { lines[$0] } ?? lines.last) else {
            fatalError("No line found for byte offset \(byteOffset)")
        }
        let diff = byteOffset - line.byteRange.location
        if diff == 0 {
            return line.range.location
        } else if line.byteRange.length == diff {
            return NSMaxRange(line.range)
        }
        let utf8View = line.content.utf8
        let endUTF8Index =
            utf8View.index(utf8View.startIndex, offsetBy: diff.value, limitedBy: utf8View.endIndex)
                ?? utf8View.endIndex
        let utf16Diff = line.content.utf16.distance(
            from: line.content.utf16.startIndex, to: endUTF8Index,
        )
        return line.range.location + utf16Diff
    }

    func substringStartingLinesWithByteRange(_ byteRange: ByteRange) -> String? {
        byteRangeToNSRange(byteRange).map { range in
            var lineStart = 0
            var lineEnd = 0
            nsString.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, for: range)
            return nsString.substring(
                with: Foundation.NSRange(
                    location: lineStart,
                    length: NSMaxRange(range) - lineStart,
                ),
            )
        }
    }

    func substringLinesWithByteRange(_ byteRange: ByteRange) -> String? {
        byteRangeToNSRange(byteRange).map { range in
            var lineStart = 0
            var lineEnd = 0
            nsString.getLineStart(&lineStart, end: &lineEnd, contentsEnd: nil, for: range)
            return nsString.substring(
                with: Foundation.NSRange(location: lineStart, length: lineEnd - lineStart),
            )
        }
    }

    func lineRangeWithByteRange(_ byteRange: ByteRange) -> (start: Int, end: Int)? {
        byteRangeToNSRange(byteRange).flatMap { range in
            var numberOfLines = 0
            var index = 0
            var lineRangeStart = 0
            while index < nsString.length {
                numberOfLines += 1
                if index <= range.location {
                    lineRangeStart = numberOfLines
                }
                index = NSMaxRange(nsString.lineRange(for: Foundation.NSRange(
                    location: index,
                    length: 1,
                )))
                if index > NSMaxRange(range) {
                    return (lineRangeStart, numberOfLines)
                }
            }
            return nil
        }
    }

    func lineAndCharacter(forByteOffset offset: ByteCount, expandingTabsToWidth tabWidth: Int = 1)
        -> (line: Int, character: Int)?
    {
        let characterOffset = location(fromByteOffset: offset)
        return lineAndCharacter(forCharacterOffset: characterOffset, expandingTabsToWidth: tabWidth)
    }

    func lineAndCharacter(forCharacterOffset offset: Int,
                          expandingTabsToWidth tabWidth: Int = 1) -> (
        line: Int, character: Int,
    )? {
        assert(tabWidth > 0)

        let index = lines.indexAssumingSorted { line in
            if offset < line.range.location {
                return .orderedAscending
            } else if offset >= line.range.location + line.range.length {
                return .orderedDescending
            }
            return .orderedSame
        }
        return index.map {
            let line = lines[$0]
            let prefixLength = offset - line.range.location
            let character: Int
            if tabWidth == 1 {
                character = prefixLength
            } else {
                character = line.content.prefix(prefixLength).reduce(0) { sum, character in
                    if character == "\t" {
                        return sum - (sum % tabWidth) + tabWidth
                    } else {
                        return sum + 1
                    }
                }
            }
            return (line: line.index, character: character + 1)
        }
    }
}
