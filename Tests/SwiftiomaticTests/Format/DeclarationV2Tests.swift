import Testing
@testable import Swiftiomatic

@Suite struct DeclarationTests {
    @Test func modifyingDeclarations() throws {
        let input = """
        import FooLib

        class Foo{
            internal var bar: Bar
            public var baaz: Baaz
        }
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()

        let fooType = try #require(declarations[1] as? TypeDeclaration)
        let barProperty = try #require(fooType.body[0] as? SimpleDeclaration)
        let baazProperty = try #require(fooType.body[1] as? SimpleDeclaration)

        #expect(
            barProperty.tokens.string == """
                internal var bar: Bar\n
            """,
        )

        #expect(
            baazProperty.tokens.string == """
                public var baaz: Baaz\n
            """,
        )

        #expect(
            fooType.tokens.string == """
            class Foo{
                internal var bar: Bar
                public var baaz: Baaz
            }
            """,
        )

        let fooIndex = fooType.keywordIndex
        formatter.insert(.space(" "), at: fooIndex + 3)
        formatter.insert([.keyword("final"), .space(" ")], at: fooIndex)

        for property in fooType.body {
            if let internalModifier = formatter.indexOfModifier(
                "internal", forDeclarationAt: property.keywordIndex,
            ) {
                formatter.removeTokens(in: internalModifier ... internalModifier + 1)
            }
        }

        #expect(
            barProperty.tokens.string == """
                var bar: Bar\n
            """,
        )

        #expect(
            baazProperty.tokens.string == """
                public var baaz: Baaz\n
            """,
        )

        #expect(
            fooType.tokens.string == """
            final class Foo {
                var bar: Bar
                public var baaz: Baaz
            }
            """,
        )
    }
}
