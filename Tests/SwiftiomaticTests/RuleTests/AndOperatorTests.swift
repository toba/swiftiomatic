import Testing
@testable import Swiftiomatic

@Suite struct AndOperatorTests {
    @Test func ifAndReplaced() {
        let input = """
        if true && true {}
        """
        let output = """
        if true, true {}
        """
        testFormatting(for: input, output, rule: .andOperator)
    }

    @Test func guardAndReplaced() {
        let input = """
        guard true && true
        else { return }
        """
        let output = """
        guard true, true
        else { return }
        """
        testFormatting(
            for: input, output, rule: .andOperator,
            exclude: [.wrapConditionalBodies],
        )
    }

    @Test func whileAndReplaced() {
        let input = """
        while true && true {}
        """
        let output = """
        while true, true {}
        """
        testFormatting(for: input, output, rule: .andOperator)
    }

    @Test func ifDoubleAndReplaced() {
        let input = """
        if true && true && true {}
        """
        let output = """
        if true, true, true {}
        """
        testFormatting(for: input, output, rule: .andOperator)
    }

    @Test func ifAndParensReplaced() {
        let input = """
        if true && (true && true) {}
        """
        let output = """
        if true, (true && true) {}
        """
        testFormatting(
            for: input, output, rule: .andOperator,
            exclude: [.redundantParens],
        )
    }

    @Test func ifFunctionAndReplaced() {
        let input = """
        if functionReturnsBool() && true {}
        """
        let output = """
        if functionReturnsBool(), true {}
        """
        testFormatting(for: input, output, rule: .andOperator)
    }

    @Test func noReplaceIfOrAnd() {
        let input = """
        if foo || bar && baz {}
        """
        testFormatting(for: input, rule: .andOperator)
    }

    @Test func noReplaceIfAndOr() {
        let input = """
        if foo && bar || baz {}
        """
        testFormatting(for: input, rule: .andOperator)
    }

    @Test func ifAndReplacedInFunction() {
        let input = """
        func someFunc() { if bar && baz {} }
        """
        let output = """
        func someFunc() { if bar, baz {} }
        """
        testFormatting(for: input, output, rule: .andOperator, exclude: [.wrapFunctionBodies])
    }

    @Test func noReplaceIfCaseLetAnd() {
        let input = """
        if case let a = foo && bar {}
        """
        testFormatting(for: input, rule: .andOperator)
    }

    @Test func noReplaceWhileCaseLetAnd() {
        let input = """
        while case let a = foo && bar {}
        """
        testFormatting(for: input, rule: .andOperator)
    }

    @Test func noReplaceRepeatWhileAnd() {
        let input = """
        repeat {} while true && !false
        foo {}
        """
        testFormatting(for: input, rule: .andOperator)
    }

    @Test func noReplaceIfLetAndLetAnd() {
        let input = """
        if let a = b && c, let d = e && f {}
        """
        testFormatting(for: input, rule: .andOperator)
    }

    @Test func noReplaceIfTryAnd() {
        let input = """
        if try true && explode() {}
        """
        testFormatting(for: input, rule: .andOperator)
    }

    @Test func handleAndAtStartOfLine() {
        let input = """
        if a == b
            && b == c {}
        """
        let output = """
        if a == b,
            b == c {}
        """
        testFormatting(for: input, output, rule: .andOperator, exclude: [.indent])
    }

    @Test func handleAndAtStartOfLineAfterComment() {
        let input = """
        if a == b // foo
            && b == c {}
        """
        let output = """
        if a == b, // foo
            b == c {}
        """
        testFormatting(for: input, output, rule: .andOperator, exclude: [.indent])
    }

    @Test func noReplaceAndOperatorWhereGenericsAmbiguous() {
        let input = """
        if x < y && z > (a * b) {}
        """
        testFormatting(for: input, rule: .andOperator)
    }

    @Test func noReplaceAndOperatorWhereGenericsAmbiguous2() {
        let input = """
        if x < y && z && w > (a * b) {}
        """
        let output = """
        if x < y, z && w > (a * b) {}
        """
        testFormatting(for: input, output, rule: .andOperator)
    }

    @Test func andOperatorCrash() {
        let input = """
        DragGesture().onChanged { gesture in
            if gesture.translation.width < 50 && gesture.translation.height > 50 {
                offset = gesture.translation
            }
        }
        """
        let output = """
        DragGesture().onChanged { gesture in
            if gesture.translation.width < 50, gesture.translation.height > 50 {
                offset = gesture.translation
            }
        }
        """
        testFormatting(for: input, output, rule: .andOperator)
    }

    @Test func noReplaceAndInViewBuilder() {
        let input = """
        SomeView {
            if foo == 5 && bar {
                Text("5")
            } else {
                Text("Not 5")
            }
        }
        """
        testFormatting(for: input, rule: .andOperator)
    }

    @Test func noReplaceAndInViewBuilder2() {
        let input = """
        var body: some View {
            ZStack {
                if self.foo && self.bar {
                    self.closedPath
                }
            }
        }
        """
        testFormatting(for: input, rule: .andOperator)
    }

    @Test func replaceAndInViewBuilderInSwift5_3() {
        let input = """
        SomeView {
            if foo == 5 && bar {
                Text("5")
            } else {
                Text("Not 5")
            }
        }
        """
        let output = """
        SomeView {
            if foo == 5, bar {
                Text("5")
            } else {
                Text("Not 5")
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .andOperator, options: options)
    }
}
