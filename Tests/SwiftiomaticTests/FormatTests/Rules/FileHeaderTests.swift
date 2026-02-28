import Testing
@testable import Swiftiomatic

@Suite struct FileHeaderTests {
    @Test func stripHeader() {
        let input = """
        //
        //  test.swift
        //  SwiftFormat
        //
        //  Created by Nick Lockwood on 08/11/2016.
        //  Copyright © 2016 Nick Lockwood. All rights reserved.
        //

        /// func
        func foo() {}
        """
        let output = """
        /// func
        func foo() {}
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func stripHeaderWithWhenHeaderContainsUrl() {
        let input = """
        //
        //  RulesTests+General.swift
        //  SwiftFormatTests
        //
        //  Created by Nick Lockwood on 02/10/2021.
        //  Copyright © 2021 Nick Lockwood. All rights reserved.
        //  https://some.example.com
        //

        /// func
        func foo() {}
        """
        let output = """
        /// func
        func foo() {}
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func replaceHeaderWhenFileContainsNoCode() {
        let input = """
        // foobar
        """
        let options = FormatOptions(fileHeader: "// foobar")
        testFormatting(for: input, rule: .fileHeader, options: options,
                       exclude: [.linebreakAtEndOfFile])
    }

    @Test func replaceHeaderWhenFileContainsNoCode2() {
        let input = """
        // foobar

        """
        let options = FormatOptions(fileHeader: "// foobar")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func multilineCommentHeader() {
        let input = """
        /****************************/
        /* Created by Nick Lockwood */
        /****************************/

        /// func
        func foo() {}
        """
        let output = """
        /// func
        func foo() {}
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func noStripHeaderWhenDisabled() {
        let input = """
        //
        //  test.swift
        //  SwiftFormat
        //
        //  Created by Nick Lockwood on 08/11/2016.
        //  Copyright © 2016 Nick Lockwood. All rights reserved.
        //

        /// func
        func foo() {}
        """
        let options = FormatOptions(fileHeader: .ignore)
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func noStripComment() {
        let input = """

        /// func
        func foo() {}
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func noStripPackageHeader() {
        let input = """
        // swift-tools-version:4.2

        import PackageDescription
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func noStripFormatDirective() {
        let input = """
        // swiftformat:options --swiftversion 5.2

        import PackageDescription
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func noStripFormatDirectiveAfterHeader() {
        let input = """
        // header
        // swiftformat:options --swiftversion 5.2

        import PackageDescription
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func noReplaceFormatDirective() {
        let input = """
        // swiftformat:options --swiftversion 5.2

        import PackageDescription
        """
        let output = """
        // Hello World

        // swiftformat:options --swiftversion 5.2

        import PackageDescription
        """
        let options = FormatOptions(fileHeader: "// Hello World")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func setSingleLineHeader() {
        let input = """
        //
        //  test.swift
        //  SwiftFormat
        //
        //  Created by Nick Lockwood on 08/11/2016.
        //  Copyright © 2016 Nick Lockwood. All rights reserved.
        //

        /// func
        func foo() {}
        """
        let output = """
        // Hello World

        /// func
        func foo() {}
        """
        let options = FormatOptions(fileHeader: "// Hello World")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func setMultilineHeader() {
        let input = """
        //
        //  test.swift
        //  SwiftFormat
        //
        //  Created by Nick Lockwood on 08/11/2016.
        //  Copyright © 2016 Nick Lockwood. All rights reserved.
        //

        /// func
        func foo() {}
        """
        let output = """
        // Hello
        // World

        /// func
        func foo() {}
        """
        let options = FormatOptions(fileHeader: "// Hello\n// World")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func setMultilineHeaderWithMarkup() {
        let input = """
        //
        //  test.swift
        //  SwiftFormat
        //
        //  Created by Nick Lockwood on 08/11/2016.
        //  Copyright © 2016 Nick Lockwood. All rights reserved.
        //

        /// func
        func foo() {}
        """
        let output = """
        /*--- Hello ---*/
        /*--- World ---*/

        /// func
        func foo() {}
        """
        let options = FormatOptions(fileHeader: "/*--- Hello ---*/\n/*--- World ---*/")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func noStripHeaderIfRuleDisabled() {
        let input = """
        // swiftformat:disable fileHeader
        // test
        // swiftformat:enable fileHeader

        func foo() {}
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func noStripHeaderIfNextRuleDisabled() {
        let input = """
        // swiftformat:disable:next fileHeader
        // test

        func foo() {}
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func noStripHeaderDocWithNewlineBeforeCode() {
        let input = """
        /// Header doc

        class Foo {}
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: .fileHeader, options: options, exclude: [.docComments])
    }

    @Test func noDuplicateHeaderIfMissingTrailingBlankLine() {
        let input = """
        // Header comment
        class Foo {}
        """
        let output = """
        // Header comment

        class Foo {}
        """
        let options = FormatOptions(fileHeader: "Header comment")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func noDuplicateHeaderContainingPossibleCommentDirective() {
        let input = """
        // Copyright (c) 2010-2023 Foobar
        //
        // SPDX-License-Identifier: EPL-2.0

        class Foo {}
        """
        let output = """
        // Copyright (c) 2010-2024 Foobar
        //
        // SPDX-License-Identifier: EPL-2.0

        class Foo {}
        """
        let options = FormatOptions(fileHeader: "// Copyright (c) 2010-2024 Foobar\n//\n// SPDX-License-Identifier: EPL-2.0")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func noDuplicateHeaderContainingCommentDirective() {
        let input = """
        // Copyright (c) 2010-2023 Foobar
        //
        // swiftformat:disable all

        class Foo {}
        """
        let output = """
        // Copyright (c) 2010-2024 Foobar
        //
        // swiftformat:disable all

        class Foo {}
        """
        let options = FormatOptions(fileHeader: "// Copyright (c) 2010-2024 Foobar\n//\n// swiftformat:disable all")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderYearReplacement() {
        let input = """
        let foo = bar
        """
        let output: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return "// Copyright © \(formatter.string(from: Date()))\n\nlet foo = bar"
        }()
        let options = FormatOptions(fileHeader: "// Copyright © {year}")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderCreationYearReplacement() {
        let input = """
        let foo = bar
        """
        let date = Date(timeIntervalSince1970: 0)
        let output: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return "// Copyright © \(formatter.string(from: date))\n\nlet foo = bar"
        }()
        let fileInfo = FileInfo(creationDate: date)
        let options = FormatOptions(fileHeader: "// Copyright © {created.year}", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderAuthorReplacement() {
        let name = """
        Test User
        """
        let email = """
        test@email.com
        """
        let input = """
        let foo = bar
        """
        let output = """
        // Created by \(name) \(email)

        let foo = bar
        """
        let fileInfo = FileInfo(replacements: [.authorName: .constant(name), .authorEmail: .constant(email)])
        let options = FormatOptions(fileHeader: "// Created by {author.name} {author.email}", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderAuthorReplacement2() {
        let author = """
        Test User <test@email.com>
        """
        let input = """
        let foo = bar
        """
        let output = """
        // Created by \(author)

        let foo = bar
        """
        let fileInfo = FileInfo(replacements: [.author: .constant(author)])
        let options = FormatOptions(fileHeader: "// Created by {author}", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderMultipleReplacement() {
        let name = """
        Test User
        """
        let input = """
        let foo = bar
        """
        let output = """
        // Copyright © \(name)
        // Created by \(name)

        let foo = bar
        """
        let fileInfo = FileInfo(replacements: [.authorName: .constant(name)])
        let options = FormatOptions(fileHeader: "// Copyright © {author.name}\n// Created by {author.name}", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderCreationDateReplacement() {
        let input = """
        let foo = bar
        """
        let date = Date(timeIntervalSince1970: 0)
        let output: String = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return "// Created by Nick Lockwood on \(formatter.string(from: date)).\n\nlet foo = bar"
        }()
        let fileInfo = FileInfo(creationDate: date)
        let options = FormatOptions(fileHeader: "// Created by Nick Lockwood on {created}.", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderDateFormattingIso() {
        let date = createTestDate("2023-08-09")

        let input = """
        let foo = bar
        """
        let output = """
        // 2023-08-09

        let foo = bar
        """
        let fileInfo = FileInfo(creationDate: date)
        let options = FormatOptions(fileHeader: "// {created}", dateFormat: .iso, fileInfo: fileInfo)
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderDateFormattingDayMonthYear() {
        let date = createTestDate("2023-08-09")

        let input = """
        let foo = bar
        """
        let output = """
        // 09/08/2023

        let foo = bar
        """
        let fileInfo = FileInfo(creationDate: date)
        let options = FormatOptions(fileHeader: "// {created}", dateFormat: .dayMonthYear, fileInfo: fileInfo)
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderDateFormattingMonthDayYear() {
        let date = createTestDate("2023-08-09")

        let input = """
        let foo = bar
        """
        let output = """
        // 08/09/2023

        let foo = bar
        """
        let fileInfo = FileInfo(creationDate: date)
        let options = FormatOptions(fileHeader: "// {created}",
                                    dateFormat: .monthDayYear,
                                    fileInfo: fileInfo)
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderDateFormattingCustom() {
        let date = createTestDate("2023-08-09T12:59:30.345Z", .timestamp)

        let input = """
        let foo = bar
        """
        let output = """
        // 23.08.09-12.59.30.345

        let foo = bar
        """
        let fileInfo = FileInfo(creationDate: date)
        let options = FormatOptions(fileHeader: "// {created}",
                                    dateFormat: .custom("yy.MM.dd-HH.mm.ss.SSS"),
                                    timeZone: .identifier("UTC"),
                                    fileInfo: fileInfo)
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderFileReplacement() {
        let input = """
        let foo = bar
        """
        let output = """
        // MyFile.swift

        let foo = bar
        """
        let fileInfo = FileInfo(filePath: "~/MyFile.swift")
        let options = FormatOptions(fileHeader: "// {file}", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func edgeCaseHeaderEndIndexPlusNewHeaderTokensCountEqualsFileTokensEndIndex() {
        let input = """
        // Header comment

        class Foo {}
        """
        let output = """
        // Header line1
        // Header line2

        class Foo {}
        """
        let options = FormatOptions(fileHeader: "// Header line1\n// Header line2")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderBlankLineNotRemovedBeforeFollowingComment() {
        let input = """
        //
        // Header
        //

        // Something else...
        """
        let options = FormatOptions(fileHeader: "//\n// Header\n//")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderBlankLineNotRemovedBeforeFollowingComment2() {
        let input = """
        //
        // Header
        //

        //
        // Something else...
        //
        """
        let options = FormatOptions(fileHeader: "//\n// Header\n//")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderRemovedAfterHashbang() {
        let input = """
        #!/usr/bin/swift

        // Header line1
        // Header line2

        let foo = 5
        """
        let output = """
        #!/usr/bin/swift

        let foo = 5
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func fileHeaderPlacedAfterHashbang() {
        let input = """
        #!/usr/bin/swift

        let foo = 5
        """
        let output = """
        #!/usr/bin/swift

        // Header line1
        // Header line2

        let foo = 5
        """
        let options = FormatOptions(fileHeader: "// Header line1\n// Header line2")
        testFormatting(for: input, output, rule: .fileHeader, options: options)
    }

    @Test func blankLineAfterHashbangNotRemovedByFileHeader() {
        let input = """
        #!/usr/bin/swift

        let foo = 5
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func lineAfterHashbangNotAffectedByFileHeaderRemoval() {
        let input = """
        #!/usr/bin/swift
        let foo = 5
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func disableFileHeaderCommentRespectedAfterHashbang() {
        let input = """
        #!/usr/bin/swift
        // swiftformat:disable fileHeader

        // Header line1
        // Header line2

        let foo = 5
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    @Test func disableFileHeaderCommentRespectedAfterHashbang2() {
        let input = """
        #!/usr/bin/swift

        // swiftformat:disable fileHeader
        // Header line1
        // Header line2

        let foo = 5
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: .fileHeader, options: options)
    }

    private func testTimeZone(
        timeZone: FormatTimeZone,
        tests: [String: String]
    ) {
        for (input, expected) in tests {
            let date = createTestDate(input, .time)
            let input = """
            let foo = bar
            """
            let output = """
            // \(expected)

            let foo = bar
            """

            let fileInfo = FileInfo(creationDate: date)

            let options = FormatOptions(
                fileHeader: "// {created}",
                dateFormat: .custom("HH:mm"),
                timeZone: timeZone,
                fileInfo: fileInfo
            )

            testFormatting(for: input, output,
                           rule: .fileHeader,
                           options: options)
        }
    }

    @Test func fileHeaderDateTimeZoneSystem() {
        let baseDate = createTestDate("15:00Z", .time)
        let offset = TimeZone.current.secondsFromGMT(for: baseDate)

        let date = baseDate.addingTimeInterval(Double(offset))

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let expected = formatter.string(from: date)

        testTimeZone(timeZone: .system, tests: [
            "15:00Z": expected,
            "16:00+1": expected,
            "01:00+10": expected,
            "16:30+0130": expected,
        ])
    }

    @Test func fileHeaderDateTimeZoneAbbreviations() throws {
        // GMT+0530
        try testTimeZone(timeZone: try #require(FormatTimeZone(rawValue: "IST")), tests: [
            "15:00Z": "20:30",
            "16:00+1": "20:30",
            "01:00+10": "20:30",
            "16:30+0130": "20:30",
        ])
    }

    @Test func fileHeaderDateTimeZoneIdentifiers() throws {
        // GMT+0845
        try testTimeZone(timeZone: try #require(FormatTimeZone(rawValue: "Australia/Eucla")), tests: [
            "15:00Z": "23:45",
            "16:00+1": "23:45",
            "01:00+10": "23:45",
            "16:30+0130": "23:45",
        ])
    }

    @Test func gitHelpersReturnsInfo() {
        let info = GitFileInfo(url: URL(fileURLWithPath: #file))
        #expect(info?.authorName != nil)
        #expect(info?.authorEmail != nil)
        #expect(info?.creationDate != nil)
    }

    @Test func gitHelpersWorksWithFilesNotCommitedYet() throws {
        try withTempProjectFile { url in
            let info = GitFileInfo(url: url)
            #expect(info?.authorName != nil)
            #expect(info?.authorEmail != nil)
            #expect(info?.creationDate == nil)
        }
    }

    @Test func fileHeaderRuleThrowsIfCreationDateUnavailable() {
        let input = """
        let foo = bar
        """
        let options = FormatOptions(fileHeader: "// Created by Nick Lockwood on {created}.", fileInfo: FileInfo())
        #expect(throws: (any Error).self) { try format(input, rules: [.fileHeader], options: options) }
    }

    @Test func fileHeaderRuleThrowsIfFileNameUnavailable() {
        let input = """
        let foo = bar
        """
        let options = FormatOptions(fileHeader: "// {file}.", fileInfo: FileInfo())
        #expect(throws: (any Error).self) { try format(input, rules: [.fileHeader], options: options) }
    }
}

private enum TestDateFormat: String {
    case basic = "yyyy-MM-dd"
    case time = "HH:mmZZZZZ"
    case timestamp = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
}

private func createTestDate(
    _ input: String,
    _ format: TestDateFormat = .basic
) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = format.rawValue
    formatter.timeZone = .current

    return formatter.date(from: input)!
}

private func withTempProjectFile(fn: (URL) -> Void) throws {
    let prefix = UUID().uuidString

    var components = URL(fileURLWithPath: #file)
        .pathComponents
        .prefix(while: { $0 != "Tests" })

    components.append(".temp")

    let directory = components.joined(separator: "/")

    if !FileManager.default.fileExists(atPath: directory) {
        try FileManager.default.createDirectory(atPath: directory,
                                                withIntermediateDirectories: true)
    }

    let url = URL(fileURLWithPath: directory).appendingPathComponent(prefix + ".swift")

    FileManager.default.createFile(atPath: url.path, contents: nil)
    fn(url)
    try FileManager.default.removeItem(at: url)
}
