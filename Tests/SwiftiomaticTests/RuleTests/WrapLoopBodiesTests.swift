import Testing
@testable import Swiftiomatic

@Suite struct WrapLoopBodiesTests {
    @Test func wrapForLoop() {
        let input = """
        for foo in bar { print(foo) }
        """
        let output = """
        for foo in bar {
            print(foo)
        }
        """
        testFormatting(for: input, output, rule: .wrapLoopBodies)
    }

    @Test func wrapWhileLoop() {
        let input = """
        while let foo = bar.next() { print(foo) }
        """
        let output = """
        while let foo = bar.next() {
            print(foo)
        }
        """
        testFormatting(for: input, output, rule: .wrapLoopBodies)
    }

    @Test func wrapRepeatWhileLoop() {
        let input = """
        repeat { print(foo) } while condition()
        """
        let output = """
        repeat {
            print(foo)
        } while condition()
        """
        testFormatting(for: input, output, rule: .wrapLoopBodies)
    }
}
