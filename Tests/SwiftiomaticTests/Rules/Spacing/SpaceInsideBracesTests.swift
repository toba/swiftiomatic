import Testing
@testable import Swiftiomatic

@Suite struct SpaceInsideBracesTests {
    @Test func spaceInsideBraces() {
        let input = """
        foo({bar})
        """
        let output = """
        foo({ bar })
        """
        testFormatting(for: input, output, rule: .spaceInsideBraces, exclude: [.trailingClosures])
    }

    @Test func noExtraSpaceInsidebraces() {
        let input = """
        { foo }
        """
        testFormatting(for: input, rule: .spaceInsideBraces, exclude: [.trailingClosures])
    }

    @Test func noSpaceAddedInsideEmptybraces() {
        let input = """
        foo({})
        """
        testFormatting(for: input, rule: .spaceInsideBraces, exclude: [.trailingClosures])
    }

    @Test func noSpaceAddedBetweenDoublebraces() {
        let input = """
        func foo() -> () -> Void {{ bar() }}
        """
        testFormatting(for: input, rule: .spaceInsideBraces, exclude: [.wrapFunctionBodies])
    }
}
