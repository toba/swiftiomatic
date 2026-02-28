import Testing
@testable import Swiftiomatic

@Suite struct BlankLineAfterImportsTests {
    @Test func blankLineAfterImport() {
        let input = """
        import ModuleA
        @testable import ModuleB
        import ModuleC
        @testable import ModuleD
        @_exported import ModuleE
        @_implementationOnly import ModuleF
        @_spi(SPI) import ModuleG
        @_spiOnly import ModuleH
        @preconcurrency import ModuleI
        class foo {}
        """
        let output = """
        import ModuleA
        @testable import ModuleB
        import ModuleC
        @testable import ModuleD
        @_exported import ModuleE
        @_implementationOnly import ModuleF
        @_spi(SPI) import ModuleG
        @_spiOnly import ModuleH
        @preconcurrency import ModuleI

        class foo {}
        """
        testFormatting(for: input, output, rule: .blankLineAfterImports)
    }

    @Test func blankLinesBetweenConditionalImports() {
        let input = """
        #if foo
            import ModuleA
        #else
            import ModuleB
        #endif
        import ModuleC
        func foo() {}
        """
        let output = """
        #if foo
            import ModuleA
        #else
            import ModuleB
        #endif
        import ModuleC

        func foo() {}
        """
        testFormatting(for: input, output, rule: .blankLineAfterImports)
    }

    @Test func blankLinesBetweenNestedConditionalImports() {
        let input = """
        #if foo
            import ModuleA
            #if bar
                import ModuleB
            #endif
        #else
            import ModuleC
        #endif
        import ModuleD
        func foo() {}
        """
        let output = """
        #if foo
            import ModuleA
            #if bar
                import ModuleB
            #endif
        #else
            import ModuleC
        #endif
        import ModuleD

        func foo() {}
        """
        testFormatting(for: input, output, rule: .blankLineAfterImports)
    }

    @Test func blankLineAfterScopedImports() {
        let input = """
        internal import UIKit
        internal import Foundation
        private import Time
        public class Foo {}
        """
        let output = """
        internal import UIKit
        internal import Foundation
        private import Time

        public class Foo {}
        """
        testFormatting(for: input, output, rule: .blankLineAfterImports)
    }
}
