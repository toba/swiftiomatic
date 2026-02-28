import Testing
@testable import Swiftiomatic

@Suite struct SwiftFormatTests {
    // MARK: enumerateFiles

    @Test func inputFileMatchesOutputFileForNilOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file)
        let errors = enumerateFiles(withInputURLs: [inputURL]) { inputURL, outputURL, _ in
            #expect(inputURL == outputURL)
            #expect(inputURL == URL(fileURLWithPath: #file))
            return { files.append(inputURL) }
        }
        #expect(errors.count == 0)
        #expect(files.count == 1)
    }

    @Test func inputFileMatchesOutputFileForSameOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file)
        let errors = enumerateFiles(withInputURLs: [inputURL], outputURL: inputURL) { inputURL, outputURL, _ in
            #expect(inputURL == outputURL)
            #expect(inputURL == URL(fileURLWithPath: #file))
            return { files.append(inputURL) }
        }
        #expect(errors.count == 0)
        #expect(files.count == 1)
    }

    @Test func inputFilesMatchOutputFilesForNilOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        let errors = enumerateFiles(withInputURLs: [inputURL]) { inputURL, outputURL, _ in
            #expect(inputURL == outputURL)
            return { files.append(inputURL) }
        }
        #expect(errors.count == 0)
        #expect(files.count >= 180)
    }

    @Test func inputFilesMatchOutputFilesForSameOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        let errors = enumerateFiles(withInputURLs: [inputURL], outputURL: inputURL) { inputURL, outputURL, _ in
            #expect(inputURL == outputURL)
            return { files.append(inputURL) }
        }
        #expect(errors.count == 0)
        #expect(files.count >= 180)
    }

    @Test func inputFileNotEnumeratedWhenExcluded() {
        var files = [URL]()
        let currentFile = URL(fileURLWithPath: #file)
        let options = Options(fileOptions: FileOptions(excludedGlobs: [
            Glob.path(currentFile.deletingLastPathComponent().path),
        ]))
        let inputURL = currentFile.deletingLastPathComponent().deletingLastPathComponent()
        let errors = enumerateFiles(withInputURLs: [inputURL], outputURL: inputURL, options: options) { inputURL, outputURL, _ in
            #expect(inputURL == outputURL)
            return { files.append(inputURL) }
        }

        var allFiles = [URL]()
        let allFilesInputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        _ = enumerateFiles(withInputURLs: [allFilesInputURL], outputURL: allFilesInputURL) { inputURL, outputURL, _ in
            #expect(inputURL == outputURL)
            return { allFiles.append(inputURL) }
        }

        #expect(errors.count == 0)
        #expect(files.count < allFiles.count)
    }

    // MARK: format function

    @Test func formatReturnsInputWithNoRules() {
        let input = "foo ()  "
        #expect(try format(input, rules: []).output == input)
    }

    @Test func formatUsesDefaultRulesIfNoneSpecified() {
        let input = "foo ()  "
        let output = "foo()\n"
        #expect(try format(input).output == output)
    }

    // MARK: lint function

    @Test func lintReturnsNoChangesWithNoRules() {
        let input = "foo ()  "
        #expect(try lint(input, rules: []) == [])
    }

    @Test func lintWithDefaultRules() {
        let input = "foo ()  "
        #expect(try lint(input) == [
            .init(line: 1, rule: .linebreakAtEndOfFile, filePath: nil, isMove: false),
            .init(line: 1, rule: .spaceAroundParens, filePath: nil, isMove: false),
            .init(line: 1, rule: .trailingSpace, filePath: nil, isMove: false),
        ])
    }

    @Test func lintConsecutiveBlankLinesAtEndOfFile() {
        let input = "foo\n\n"
        #expect(try lint(input) == [
            .init(line: 2, rule: .consecutiveBlankLines, filePath: nil, isMove: false),
        ])
    }

    // MARK: fragments

    @Test func formattingFailsForFragment() {
        let input = "foo () {"
        #expect(throws: (any Error).self) { try format(input, rules: []) }
        do {
            #expect("\($0)" == "Unexpected end of file at 1:9")
        }
    }

    @Test func formattingSucceedsForFragmentWithOption() {
        let input = "foo () {"
        let options = FormatOptions(fragment: true)
        #expect(try format(input, rules: [], options: options).output == input)
    }

    // MARK: conflict markers

    @Test func formattingFailsForConflict() {
        let input = "foo () {\n<<<<<< old\n    bar()\n======\n    baz()\n>>>>>> new\n}"
        #expect(throws: (any Error).self) { try format(input, rules: []) }
        do {
            #expect("\($0)" == "Found conflict marker <<<<<< at 2:1")
        }
    }

    @Test func formattingSucceedsForConflictWithOption() {
        let input = "foo () {\n<<<<<< old\n    bar()\n======\n    baz()\n>>>>>> new\n}"
        let options = FormatOptions(ignoreConflictMarkers: true)
        #expect(try format(input, rules: [], options: options).output == input)
    }

    // MARK: empty file

    @Test func noTimeoutForEmptyFile() {
        let input = ""
        #expect(try format(input).output == input)
    }

    // MARK: offsetForToken

    @Test func offsetForToken() {
        let tokens = tokenize("// a comment\n    let foo = 5\n")
        let offset = offsetForToken(at: 7, in: tokens, tabWidth: 1)
        #expect(offset == SourceOffset(line: 2, column: 9))
    }

    @Test func offsetForTokenWithTabs() {
        let tokens = tokenize("// a comment\n\tlet foo = 5\n")
        let offset = offsetForToken(at: 7, in: tokens, tabWidth: 2)
        #expect(offset == SourceOffset(line: 2, column: 7))
    }

    // MARK: tokenIndex for offset

    @Test func tokenIndexForOffset() {
        let tokens = tokenize("// a comment\n    let foo = 5\n")
        let offset = SourceOffset(line: 2, column: 9)
        #expect(tokenIndex(for: offset, in: tokens, tabWidth: 1) == 7)
    }

    @Test func tokenIndexForOffsetWithTabs() {
        let tokens = tokenize("// a comment\n\tlet foo = 5\n")
        let offset = SourceOffset(line: 2, column: 7)
        #expect(tokenIndex(for: offset, in: tokens, tabWidth: 2) == 7)
    }

    @Test func tokenIndexForLastLine() {
        let tokens = tokenize("""
        let foo = 5
        let bar = 6
        """)
        let offset = SourceOffset(line: 2, column: 0)
        #expect(tokenIndex(for: offset, in: tokens, tabWidth: 1) == 8)
    }

    @Test func tokenIndexPastEndOfFile() {
        let tokens = tokenize("""
        let foo = 5
        let bar = 6
        """)
        let offset = SourceOffset(line: 3, column: 0)
        #expect(tokenIndex(for: offset, in: tokens, tabWidth: 1) == 15)
    }

    @Test func tokenIndexForBlankLastLine() {
        let tokens = tokenize("""
        let foo = 5
        let bar = 6

        """)
        let offset = SourceOffset(line: 3, column: 0)
        #expect(tokenIndex(for: offset, in: tokens, tabWidth: 1) == 16)
    }

    // MARK: tokenRange

    @Test func tokenRange() {
        let tokens = tokenize("// a comment\n    let foo = 5\n")
        #expect(tokenRange(forLineRange: 1 ... 1, in: tokens) == 0 ..< 3)
    }

    // MARK: newOffset

    @Test func newOffsetsForUnchangedPosition() {
        let tokens = tokenize("foo\nbar\nbaz")
        let offset1 = SourceOffset(line: 1, column: 1)
        let offset2 = SourceOffset(line: 2, column: 1)
        let offset3 = SourceOffset(line: 3, column: 1)
        #expect(newOffset(for: offset1, in: tokens, tabWidth: 1) == offset1)
        #expect(newOffset(for: offset2, in: tokens, tabWidth: 1) == offset2)
        #expect(newOffset(for: offset3, in: tokens, tabWidth: 1) == offset3)
    }

    @Test func newOffsetsForRemovedLine() throws {
        let input = tokenize("foo\nbar\n\n\nbaz\nquux")
        let offset1 = SourceOffset(line: 1, column: 1)
        let offset2 = SourceOffset(line: 2, column: 1)
        let offset3 = SourceOffset(line: 5, column: 1)
        let offset4 = SourceOffset(line: 6, column: 1)
        let output = try format(input, rules: [.consecutiveBlankLines]).tokens
        let expected3 = SourceOffset(line: 4, column: 1)
        let expected4 = SourceOffset(line: 5, column: 1)
        #expect(newOffset(for: offset1, in: output, tabWidth: 1) == offset1)
        #expect(newOffset(for: offset2, in: output, tabWidth: 1) == offset2)
        #expect(newOffset(for: offset3, in: output, tabWidth: 1) == expected3)
        #expect(newOffset(for: offset4, in: output, tabWidth: 1) == expected4)
    }

    @Test func newOffsetsForEmptyOutput() {
        let offset = SourceOffset(line: 1, column: 1)
        #expect(newOffset(for: offset, in: [], tabWidth: 1) == offset)
    }

    // MARK: expand path

    @Test func expandPathWithRelativePath() {
        #expect(expandPath("relpath/to/file.swift", in: "/dir").path == "/dir/relpath/to/file.swift")
    }

    @Test func expandPathWithFullPath() {
        #expect(expandPath("/full/path/to/file.swift", in: "/dir").path == "/full/path/to/file.swift")
    }

    @Test func expandPathWithUserPath() {
        #expect(expandPath("~/file.swift", in: "/dir").path == NSString(string: "~/file.swift").expandingTildeInPath)
    }

    // MARK: shared option inference

    @Test func linebreakInferredForBlankLinesBetweenScopes() {
        let input = "class Foo {\r  func bar() {\r  }\r  func baz() {\r  }\r}"
        let output = "class Foo {\r  func bar() {\r  }\r\r  func baz() {\r  }\r}"
        #expect(try format(input, rules: [.blankLinesBetweenScopes]).output == output)
    }
}
