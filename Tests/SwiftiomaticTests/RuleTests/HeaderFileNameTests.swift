import Testing
@testable import Swiftiomatic

@Suite struct HeaderFileNameTests {
    @Test func headerFileNameReplaced() {
        let input = """
        // MyFile.swift

        let foo = bar
        """
        let output = """
        // YourFile.swift

        let foo = bar
        """
        let options = FormatOptions(fileInfo: FileInfo(filePath: "~/YourFile.swift"))
        testFormatting(for: input, output, rule: .headerFileName, options: options)
    }
}
