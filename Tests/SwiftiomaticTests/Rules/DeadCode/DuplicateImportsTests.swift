import Testing
@testable import Swiftiomatic

@Suite struct DuplicateImportsTests {
    @Test func removeDuplicateImport() {
        let input = """
        import Foundation
        import Foundation
        """
        let output = """
        import Foundation
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    @Test func removeDuplicateConditionalImport() {
        let input = """
        #if os(iOS)
            import Foo
            import Foo
        #else
            import Bar
            import Bar
        #endif
        """
        let output = """
        #if os(iOS)
            import Foo
        #else
            import Bar
        #endif
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    @Test func noRemoveOverlappingImports() {
        let input = """
        import MyModule
        import MyModule.Private
        """
        testFormatting(for: input, rule: .duplicateImports)
    }

    @Test func noRemoveCaseDifferingImports() {
        let input = """
        import Auth0.Authentication
        import Auth0.authentication
        """
        testFormatting(for: input, rule: .duplicateImports)
    }

    @Test func removeDuplicateImportFunc() {
        let input = """
        import func Foo.bar
        import func Foo.bar
        """
        let output = """
        import func Foo.bar
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    @Test func noRemoveTestableDuplicateImport() {
        let input = """
        import Foo
        @testable import Foo
        """
        let output = """

        @testable import Foo
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    @Test func noRemoveTestableDuplicateImport2() {
        let input = """
        @testable import Foo
        import Foo
        """
        let output = """
        @testable import Foo
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    @Test func noRemoveExportedDuplicateImport() {
        let input = """
        import Foo
        @_exported import Foo
        """
        let output = """

        @_exported import Foo
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    @Test func noRemoveExportedDuplicateImport2() {
        let input = """
        @_exported import Foo
        import Foo
        """
        let output = """
        @_exported import Foo
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }
}
