import Testing
@testable import Swiftiomatic

@Suite struct RedundantBreakTests {
    @Test func redundantBreaksRemoved() {
        let input = """
        switch x {
        case foo:
            print("hello")
            break
        case bar:
            print("world")
            break
        default:
            print("goodbye")
            break
        }
        """
        let output = """
        switch x {
        case foo:
            print("hello")
        case bar:
            print("world")
        default:
            print("goodbye")
        }
        """
        testFormatting(for: input, output, rule: .redundantBreak)
    }

    @Test func breakInEmptyCaseNotRemoved() {
        let input = """
        switch x {
        case foo:
            break
        case bar:
            break
        default:
            break
        }
        """
        testFormatting(for: input, rule: .redundantBreak)
    }

    @Test func conditionalBreakNotRemoved() {
        let input = """
        switch x {
        case foo:
            if bar {
                break
            }
        }
        """
        testFormatting(for: input, rule: .redundantBreak)
    }

    @Test func breakAfterSemicolonNotMangled() {
        let input = """
        switch foo {
        case 1: print(1); break
        }
        """
        let output = """
        switch foo {
        case 1: print(1);
        }
        """
        testFormatting(for: input, output, rule: .redundantBreak, exclude: [.semicolons])
    }
}
