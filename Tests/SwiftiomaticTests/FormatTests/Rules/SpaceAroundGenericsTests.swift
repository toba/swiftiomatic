import Testing
@testable import Swiftiomatic

@Suite struct SpaceAroundGenericsTests {
    @Test func spaceAroundGenerics() {
        let input = """
        Foo <Bar <Baz>>
        """
        let output = """
        Foo<Bar<Baz>>
        """
        testFormatting(for: input, output, rule: .spaceAroundGenerics)
    }

    @Test func spaceAroundGenericsFollowedByAndOperator() {
        let input = """
        if foo is Foo<Bar> && baz {}
        """
        testFormatting(for: input, rule: .spaceAroundGenerics, exclude: [.andOperator])
    }

    @Test func spaceAroundGenericResultBuilder() {
        let input = """
        func foo(@SomeResultBuilder<Self> builder _: () -> Void) {}
        """
        testFormatting(for: input, rule: .spaceAroundGenerics)
    }
}
