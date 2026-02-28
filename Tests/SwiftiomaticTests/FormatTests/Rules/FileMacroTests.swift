import Testing
@testable import Swiftiomatic

@Suite struct FileMacroTests {
    @Test func preservesFileMacroInSwift5Mode() {
        let input = """
        func foo(file: StaticString = #fileID) {
            print(file)
        }

        func bar(file: StaticString = #file) {
            print(file)
        }
        """

        let options = FormatOptions(languageMode: "5")
        testFormatting(for: input, rule: .fileMacro, options: options)
    }

    @Test func updatesFileIDInSwift6Mode() {
        let input = """
        func foo(file: StaticString = #fileID) {
            print(file)
        }
        """

        let output = """
        func foo(file: StaticString = #file) {
            print(file)
        }
        """

        let options = FormatOptions(preferFileMacro: true, languageMode: "6")
        testFormatting(for: input, output, rule: .fileMacro, options: options)
    }

    @Test func preferFileID() {
        let input = """
        func foo(file: StaticString = #file) {
            print(file)
        }
        """

        let output = """
        func foo(file: StaticString = #fileID) {
            print(file)
        }
        """

        let options = FormatOptions(preferFileMacro: false, languageMode: "6")
        testFormatting(for: input, output, rule: .fileMacro, options: options)
    }
}
