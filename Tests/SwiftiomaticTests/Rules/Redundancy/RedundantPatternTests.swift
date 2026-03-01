import Testing
@testable import Swiftiomatic

@Suite struct RedundantPatternTests {
    @Test func removeRedundantPatternInIfCase() {
        let input = """
        if case let .foo(_, _) = bar {}
        """
        let output = """
        if case .foo = bar {}
        """
        testFormatting(for: input, output, rule: .redundantPattern)
    }

    @Test func noRemoveRequiredPatternInIfCase() {
        let input = """
        if case (_, _) = bar {}
        """
        testFormatting(for: input, rule: .redundantPattern)
    }

    @Test func removeRedundantPatternInSwitchCase() {
        let input = """
        switch foo {
        case let .bar(_, _): break
        default: break
        }
        """
        let output = """
        switch foo {
        case .bar: break
        default: break
        }
        """
        testFormatting(for: input, output, rule: .redundantPattern)
    }

    @Test func noRemoveRequiredPatternLetInSwitchCase() {
        let input = """
        switch foo {
        case let .bar(_, a): break
        default: break
        }
        """
        testFormatting(for: input, rule: .redundantPattern)
    }

    @Test func noRemoveRequiredPatternInSwitchCase() {
        let input = """
        switch foo {
        case (_, _): break
        default: break
        }
        """
        testFormatting(for: input, rule: .redundantPattern)
    }

    @Test func simplifyLetPattern() {
        let input = """
        let(_, _) = bar
        """
        let output = """
        let _ = bar
        """
        testFormatting(for: input, output, rule: .redundantPattern, exclude: [.redundantLet])
    }

    @Test func noRemoveVoidFunctionCall() {
        let input = """
        if case .foo() = bar {}
        """
        testFormatting(for: input, rule: .redundantPattern)
    }

    @Test func noRemoveMethodSignature() {
        let input = """
        func foo(_, _) {}
        """
        testFormatting(for: input, rule: .redundantPattern)
    }
}
