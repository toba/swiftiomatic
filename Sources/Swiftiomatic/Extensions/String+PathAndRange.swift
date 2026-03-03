import Foundation

extension String {
    var hasTrailingWhitespace: Bool {
        if isEmpty { return false }

        if let unicodescalar = unicodeScalars.last {
            return CharacterSet.whitespaces.contains(unicodescalar)
        }

        return false
    }

    var isUppercase: Bool { self == uppercased() }

    var isLowercase: Bool { self == lowercased() }

    private subscript(range: Range<Int>) -> String {
        let nsrange = NSRange(
            location: range.lowerBound,
            length: range.upperBound - range.lowerBound,
        )
        if let indexRange = nsRangeToIndexRange(nsrange) {
            return String(self[indexRange])
        }
        Console.fatalError("invalid range")
    }

    /// Extract a substring starting at the given character offset
    ///
    /// - Parameters:
    ///   - from: Zero-based character offset to start from.
    ///   - length: Number of characters to include. When `nil`, returns everything
    ///     from `from` to the end of the string.
    func substring(from: Int, length: Int? = nil) -> String {
        if let length {
            return self[from ..< from + length]
        }
        guard let idx = index(startIndex, offsetBy: from, limitedBy: endIndex) else {
            preconditionFailure("substring(from:) offset \(from) exceeds string bounds")
        }
        return String(self[idx...])
    }

    /// Return the character offset of the last occurrence of `search`, or `nil` if not found
    ///
    /// - Parameters:
    ///   - search: The substring to locate.
    func lastIndex(of search: String) -> Int? {
        if let range = range(of: search, options: [.literal, .backwards]) {
            return distance(from: startIndex, to: range.lowerBound)
        }
        return nil
    }

    /// Convert an `NSRange` (UTF-16 offsets) to a native `Range<String.Index>`
    ///
    /// Returns `nil` when the range has `NSNotFound` as its location or when the
    /// UTF-16 offsets cannot be mapped to valid `String.Index` values.
    ///
    /// - Parameters:
    ///   - nsrange: The `NSRange` to convert.
    func nsRangeToIndexRange(_ nsrange: NSRange) -> Range<Index>? {
        guard nsrange.location != NSNotFound else {
            return nil
        }
        let from16 =
            utf16.index(
                utf16.startIndex, offsetBy: nsrange.location,
                limitedBy: utf16.endIndex,
            ) ?? utf16.endIndex
        let to16 =
            utf16.index(
                from16, offsetBy: nsrange.length,
                limitedBy: utf16.endIndex,
            ) ?? utf16.endIndex

        guard let fromIndex = Index(from16, within: self),
              let toIndex = Index(to16, within: self)
        else {
            return nil
        }

        return fromIndex ..< toIndex
    }

    var fullNSRange: NSRange {
        NSRange(location: 0, length: utf16.count)
    }

    /// Returns a new string, converting the path to a canonical absolute path.
    ///
    /// > Important: This method might use an incorrect working directory internally. This can cause test failures
    /// in Bazel builds but does not seem to cause trouble in production.
    ///
    /// - returns: A new `String`.
    func absolutePathStandardized() -> String {
        let standardized = URL(fileURLWithPath: self).standardizedFileURL.path
        return URL(fileURLWithPath: standardized.absolutePathRepresentation()).filepath
    }

    var isFile: Bool {
        if isEmpty {
            return false
        }
        var isDirectoryObjC: ObjCBool = false
        if FileManager.default.fileExists(atPath: self, isDirectory: &isDirectoryObjC) {
            return !isDirectoryObjC.boolValue
        }
        return false
    }

    /// Count the number of occurrences of a character in this string
    ///
    /// - Parameters:
    ///   - character: Character to count.
    func countOccurrences(of character: Character) -> Int {
        reduce(0) { $1 == character ? $0 + 1 : $0 }
    }

    /// Compute a relative path from `rootDirectory` to this path
    ///
    /// Both paths are standardized before comparison. The result may include
    /// leading `..` components when the receiver is outside the root directory tree.
    ///
    /// - Parameters:
    ///   - rootDirectory: The directory to make this path relative to.
    func path(relativeTo rootDirectory: String) -> String {
        let normalizedRootDir = URL(fileURLWithPath: rootDirectory).standardizedFileURL.path
        let normalizedSelf = URL(fileURLWithPath: self).standardizedFileURL.path
        if normalizedRootDir.isEmpty {
            return normalizedSelf
        }
        var rootDirComps = normalizedRootDir.components(separatedBy: "/")
        let rootDirCompsCount = rootDirComps.count

        while true {
            let sharedRootDir = rootDirComps.joined(separator: "/")
            if normalizedSelf == sharedRootDir || normalizedSelf.hasPrefix(sharedRootDir + "/") {
                let path =
                    (0 ..< rootDirCompsCount - rootDirComps.count).map { _ in "/.." }
                        .flatMap(\.self)
                        + String(normalizedSelf.dropFirst(sharedRootDir.count))
                return String(path.dropFirst()) // Remove leading '/'
            }
            rootDirComps = rootDirComps.dropLast()
        }
    }

    /// Return the string with the given prefix removed, or unchanged if the prefix is absent
    ///
    /// - Parameters:
    ///   - prefix: The prefix to strip.
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

    /// Indent every line by the given number of spaces
    ///
    /// - Parameters:
    ///   - spaces: Number of space characters to prepend to each line.
    ///   - skipFirst: When `true`, the first line is left unindented.
    ///   - skipEmptyLines: When `true`, empty lines are not indented.
    func indent(by spaces: Int, skipFirst: Bool = false, skipEmptyLines: Bool = true) -> String {
        let lines = components(separatedBy: "\n")
        if skipFirst, let firstLine = lines.first {
            return firstLine + "\n"
                + lines.dropFirst().indent(
                    by: spaces,
                    skipEmptyLines: skipEmptyLines,
                )
        }
        return lines.indent(by: spaces, skipEmptyLines: skipEmptyLines)
    }

    /// Prepend `prefix` to every line after the first
    ///
    /// - Parameters:
    ///   - prefix: The string to insert after each newline.
    func linesPrefixed(with prefix: Self) -> Self {
        split(separator: "\n").joined(separator: "\n\(prefix)")
    }

    /// Convert a UTF-8 byte offset to a zero-based character (grapheme cluster) position
    ///
    /// Returns `nil` when the offset is out of range or does not land on a character boundary.
    ///
    /// - Parameters:
    ///   - utf8Offset: The byte offset into the string's UTF-8 representation.
    func characterPosition(of utf8Offset: Int) -> Int? {
        guard utf8Offset != 0 else { return 0 }
        guard utf8Offset > 0, utf8Offset < utf8.count else { return nil }
        var byteCount = 0
        for (charIndex, index) in indices.enumerated() {
            let nextIndex = self.index(after: index)
            byteCount += utf8[index ..< nextIndex].count
            if byteCount == utf8Offset {
                return charIndex + 1
            }
        }
        return nil
    }
}

extension Sequence<String> {
    fileprivate func indent(by spaces: Int, skipEmptyLines: Bool = true) -> String {
        map { line in
            if skipEmptyLines, line.isEmpty {
                return line
            }
            return String(repeating: " ", count: spaces) + line
        }
        .joined(separator: "\n")
    }
}
