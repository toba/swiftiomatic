import Testing
@testable import Swiftiomatic

@Suite struct SpaceInsideGenericsTests {
    @Test func spaceInsideGenerics() {
        let input = """
        Foo< Bar< Baz > >
        """
        let output = """
        Foo<Bar<Baz>>
        """
        testFormatting(for: input, output, rule: .spaceInsideGenerics)
    }
}
