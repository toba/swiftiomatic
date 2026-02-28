import Testing
@testable import Swiftiomatic

@Suite struct BlankLinesBetweenImportsTests {
    @Test func blankLinesBetweenImportsShort() {
        let input = """
        import ModuleA

        import ModuleB
        """
        let output = """
        import ModuleA
        import ModuleB
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenImports)
    }

    @Test func blankLinesBetweenImportsLong() {
        let input = """
        import ModuleA
        import ModuleB

        import ModuleC
        import ModuleD
        import ModuleE

        import ModuleF

        import ModuleG
        import ModuleH
        """
        let output = """
        import ModuleA
        import ModuleB
        import ModuleC
        import ModuleD
        import ModuleE
        import ModuleF
        import ModuleG
        import ModuleH
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenImports)
    }

    @Test func blankLinesBetweenImportsWithTestable() {
        let input = """
        import ModuleA

        @testable import ModuleB
        import ModuleC

        @testable import ModuleD
        @testable import ModuleE

        @testable import ModuleF
        """
        let output = """
        import ModuleA
        @testable import ModuleB
        import ModuleC
        @testable import ModuleD
        @testable import ModuleE
        @testable import ModuleF
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenImports)
    }
}
