import Testing
@testable import SwiftiomaticKit

@Suite struct GlobTests {
    @Test func matchesSingleStarWithinComponent() {
        #expect(Glob(pattern: "*.swift")?.matches("Foo.swift") == true)
        #expect(Glob(pattern: "*.swift")?.matches("a/Foo.swift") == false)
    }

    @Test func questionMarkMatchesSingleChar() {
        #expect(Glob(pattern: "?oo")?.matches("foo") == true)
        #expect(Glob(pattern: "?oo")?.matches("oo") == false)
    }

    @Test func doubleStarMatchesAnyDepth() {
        let g = Glob(pattern: ".build/**")
        #expect(g?.matches(".build/x.swift") == true)
        #expect(g?.matches(".build/a/b/c.swift") == true)
        #expect(g?.matches("not-build/x.swift") == false)
    }

    @Test func doubleStarLeading() {
        let g = Glob(pattern: "**/Generated/**")
        #expect(g?.matches("Sources/Foo/Generated/X.swift") == true)
        #expect(g?.matches("Generated/X.swift") == true)
        #expect(g?.matches("Sources/Foo/X.swift") == false)
    }

    @Test func charClass() {
        let g = Glob(pattern: "[abc]oo")
        #expect(g?.matches("aoo") == true)
        #expect(g?.matches("doo") == false)
    }

    @Test func negatedCharClass() {
        let g = Glob(pattern: "[!abc]oo")
        #expect(g?.matches("doo") == true)
        #expect(g?.matches("aoo") == false)
    }

    @Test func matchesAnyHelper() {
        #expect(Glob.matchesAny([".build/**", "**/*.gen.swift"], path: ".build/x") == true)
        #expect(Glob.matchesAny([".build/**", "**/*.gen.swift"], path: "Sources/X.gen.swift") == true)
        #expect(Glob.matchesAny([".build/**"], path: "Sources/X.swift") == false)
    }
}
