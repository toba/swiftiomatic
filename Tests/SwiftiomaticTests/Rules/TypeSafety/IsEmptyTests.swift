import Testing
@testable import Swiftiomatic

@Suite struct IsEmptyTests {
    // count == 0

    @Test func countEqualsZero() {
        let input = """
        if foo.count == 0 {}
        """
        let output = """
        if foo.isEmpty {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func functionCountEqualsZero() {
        let input = """
        if foo().count == 0 {}
        """
        let output = """
        if foo().isEmpty {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func expressionCountEqualsZero() {
        let input = """
        if foo || bar.count == 0 {}
        """
        let output = """
        if foo || bar.isEmpty {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func compoundIfCountEqualsZero() {
        let input = """
        if foo, bar.count == 0 {}
        """
        let output = """
        if foo, bar.isEmpty {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func optionalCountEqualsZero() {
        let input = """
        if foo?.count == 0 {}
        """
        let output = """
        if foo?.isEmpty == true {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func optionalChainCountEqualsZero() {
        let input = """
        if foo?.bar.count == 0 {}
        """
        let output = """
        if foo?.bar.isEmpty == true {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func compoundIfOptionalCountEqualsZero() {
        let input = """
        if foo, bar?.count == 0 {}
        """
        let output = """
        if foo, bar?.isEmpty == true {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func ternaryCountEqualsZero() {
        let input = """
        foo ? bar.count == 0 : baz.count == 0
        """
        let output = """
        foo ? bar.isEmpty : baz.isEmpty
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    // count != 0

    @Test func countNotEqualToZero() {
        let input = """
        if foo.count != 0 {}
        """
        let output = """
        if !foo.isEmpty {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func functionCountNotEqualToZero() {
        let input = """
        if foo().count != 0 {}
        """
        let output = """
        if !foo().isEmpty {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func expressionCountNotEqualToZero() {
        let input = """
        if foo || bar.count != 0 {}
        """
        let output = """
        if foo || !bar.isEmpty {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func compoundIfCountNotEqualToZero() {
        let input = """
        if foo, bar.count != 0 {}
        """
        let output = """
        if foo, !bar.isEmpty {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    // count > 0

    @Test func countGreaterThanZero() {
        let input = """
        if foo.count > 0 {}
        """
        let output = """
        if !foo.isEmpty {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func countExpressionGreaterThanZero() {
        let input = """
        if a.count - b.count > 0 {}
        """
        testFormatting(for: input, rule: .isEmpty)
    }

    // optional count

    @Test func optionalCountNotEqualToZero() {
        let input = """
        if foo?.count != 0 {}
        """ // nil evaluates to true
        let output = """
        if foo?.isEmpty != true {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func optionalChainCountNotEqualToZero() {
        let input = """
        if foo?.bar.count != 0 {}
        """ // nil evaluates to true
        let output = """
        if foo?.bar.isEmpty != true {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func compoundIfOptionalCountNotEqualToZero() {
        let input = """
        if foo, bar?.count != 0 {}
        """
        let output = """
        if foo, bar?.isEmpty != true {}
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    // edge cases

    @Test func ternaryCountNotEqualToZero() {
        let input = """
        foo ? bar.count != 0 : baz.count != 0
        """
        let output = """
        foo ? !bar.isEmpty : !baz.isEmpty
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func countEqualsZeroAfterOptionalOnPreviousLine() {
        let input = """
        _ = foo?.bar
        bar.count == 0 ? baz() : quux()
        """
        let output = """
        _ = foo?.bar
        bar.isEmpty ? baz() : quux()
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func countEqualsZeroAfterOptionalCallOnPreviousLine() {
        let input = """
        foo?.bar()
        bar.count == 0 ? baz() : quux()
        """
        let output = """
        foo?.bar()
        bar.isEmpty ? baz() : quux()
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func countEqualsZeroAfterTrailingCommentOnPreviousLine() {
        let input = """
        foo?.bar() // foobar
        bar.count == 0 ? baz() : quux()
        """
        let output = """
        foo?.bar() // foobar
        bar.isEmpty ? baz() : quux()
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func countGreaterThanZeroAfterOpenParen() {
        let input = """
        foo(bar.count > 0)
        """
        let output = """
        foo(!bar.isEmpty)
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }

    @Test func countGreaterThanZeroAfterArgumentLabel() {
        let input = """
        foo(bar: baz.count > 0)
        """
        let output = """
        foo(bar: !baz.isEmpty)
        """
        testFormatting(for: input, output, rule: .isEmpty)
    }
}
