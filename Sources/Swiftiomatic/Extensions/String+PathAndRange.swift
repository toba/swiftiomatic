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

    func substring(from: Int, length: Int? = nil) -> String {
        if let length {
            return self[from ..< from + length]
        }
        guard let idx = index(startIndex, offsetBy: from, limitedBy: endIndex) else {
            preconditionFailure("substring(from:) offset \(from) exceeds string bounds")
        }
        return String(self[idx...])
    }

    func lastIndex(of search: String) -> Int? {
        if let range = range(of: search, options: [.literal, .backwards]) {
            return distance(from: startIndex, to: range.lowerBound)
        }
        return nil
    }

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

    /// Count the number of occurrences of the given character in `self`
    /// - Parameter character: Character to count
    /// - Returns: Number of times `character` occurs in `self`
    func countOccurrences(of character: Character) -> Int {
        reduce(0) { $1 == character ? $0 + 1 : $0 }
    }

    /// If self is a path, this method can be used to get a path expression relative to a root directory
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

    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

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

    func linesPrefixed(with prefix: Self) -> Self {
        split(separator: "\n").joined(separator: "\n\(prefix)")
    }

    func characterPosition(of utf8Offset: Int) -> Int? {
        guard utf8Offset != 0 else { return 0 }
        guard utf8Offset > 0, utf8Offset < utf8.count else { return nil }
        var byteCount = 0
        for (charIndex, index) in indices.enumerated() {
            let nextIndex = self.index(after: index)
            byteCount += utf8[index..<nextIndex].count
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
