import Testing
@testable import Swiftiomatic

extension TokenizerTests {
    // MARK: Identifiers & keywords

    @Test func foo() {
        let input = "foo"
        let output: [Token] = [.identifier("foo")]
        #expect(tokenize(input) == output)
    }

    @Test func dollar0() {
        let input = "$0"
        let output: [Token] = [.identifier("$0")]
        #expect(tokenize(input) == output)
    }

    @Test func dollar() {
        // Note: support for this is deprecated in Swift 3
        let input = "$"
        let output: [Token] = [.identifier("$")]
        #expect(tokenize(input) == output)
    }

    @Test func fooDollar() {
        let input = "foo$"
        let output: [Token] = [.identifier("foo$")]
        #expect(tokenize(input) == output)
    }

    @Test func underscore() {
        let input = "_"
        let output: [Token] = [.identifier("_")]
        #expect(tokenize(input) == output)
    }

    @Test func underscoreFoo() {
        let input = "_foo"
        let output: [Token] = [.identifier("_foo")]
        #expect(tokenize(input) == output)
    }

    @Test func foo_bar() {
        let input = "foo_bar"
        let output: [Token] = [.identifier("foo_bar")]
        #expect(tokenize(input) == output)
    }

    @Test func atFoo() {
        let input = "@foo"
        let output: [Token] = [.keyword("@foo")]
        #expect(tokenize(input) == output)
    }

    @Test func hashFoo() {
        let input = "#foo"
        let output: [Token] = [.keyword("#foo")]
        #expect(tokenize(input) == output)
    }

    @Test func unicode() {
        let input = "µsec"
        let output: [Token] = [.identifier("µsec")]
        #expect(tokenize(input) == output)
    }

    #if os(macOS)
    @Test func emoji() {
        let input = "🙃"
        let output: [Token] = [.identifier("🙃")]
        #expect(tokenize(input) == output)
    }
    #endif

    @Test func backtickEscapedClass() {
        let input = "`class`"
        let output: [Token] = [.identifier("`class`")]
        #expect(tokenize(input) == output)
    }

    @Test func dotPrefixedKeyword() {
        let input = ".default"
        let output: [Token] = [
            .operator(".", .prefix),
            .identifier("default"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func namespacedAttribute() {
        let input = "@OuterType.Wrapper"
        let output: [Token] = [
            .keyword("@OuterType"),
            .operator(".", .infix),
            .identifier("Wrapper"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func attributeArguments() {
        let input = "@derivative(of: subscript.get)"
        let output: [Token] = [
            .keyword("@derivative"),
            .startOfScope("("),
            .identifier("of"),
            .delimiter(":"),
            .space(" "),
            .identifier("subscript"),
            .operator(".", .infix),
            .identifier("get"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordsAsArgumentLabelNames() {
        let input = "foo(for: bar, if: baz)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("("),
            .identifier("for"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .delimiter(","),
            .space(" "),
            .identifier("if"),
            .delimiter(":"),
            .space(" "),
            .identifier("baz"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordsAsArgumentLabelNames2() {
        let input = "foo(case: bar, default: baz)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("("),
            .identifier("case"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .delimiter(","),
            .space(" "),
            .identifier("default"),
            .delimiter(":"),
            .space(" "),
            .identifier("baz"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordsAsArgumentLabelNames3() {
        let input = "foo(switch: bar, case: baz)"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("("),
            .identifier("switch"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .delimiter(","),
            .space(" "),
            .identifier("case"),
            .delimiter(":"),
            .space(" "),
            .identifier("baz"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordAsInternalArgumentLabelName() {
        let input = "func foo(all in: Array)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("all"),
            .space(" "),
            .identifier("in"),
            .delimiter(":"),
            .space(" "),
            .identifier("Array"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordAsExternalArgumentLabelName() {
        let input = "func foo(in array: Array)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("in"),
            .space(" "),
            .identifier("array"),
            .delimiter(":"),
            .space(" "),
            .identifier("Array"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordAsBothArgumentLabelNames() {
        let input = "func foo(for in: Array)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("("),
            .identifier("for"),
            .space(" "),
            .identifier("in"),
            .delimiter(":"),
            .space(" "),
            .identifier("Array"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordAsSubscriptLabels() {
        let input = "foo[for: bar]"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("["),
            .identifier("for"),
            .delimiter(":"),
            .space(" "),
            .identifier("bar"),
            .endOfScope("]"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func keywordAsClosureLabel() {
        let input = "foo.if(bar) { bar } else: { baz }"
        let output: [Token] = [
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("if"),
            .startOfScope("("),
            .identifier("bar"),
            .endOfScope(")"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .identifier("bar"),
            .space(" "),
            .endOfScope("}"),
            .space(" "),
            .identifier("else"),
            .delimiter(":"),
            .space(" "),
            .startOfScope("{"),
            .space(" "),
            .identifier("baz"),
            .space(" "),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func numberedTupleVariableMember() {
        let input = "foo.2"
        let output: [Token] = [
            .identifier("foo"),
            .operator(".", .infix),
            .identifier("2"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func numberedTupleExpressionMember() {
        let input = "(1,2).1"
        let output: [Token] = [
            .startOfScope("("),
            .number("1", .integer),
            .delimiter(","),
            .number("2", .integer),
            .endOfScope(")"),
            .operator(".", .infix),
            .identifier("1"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func xcodeToken() {
        let input = """
        test(image: <#T##UIImage#>)
        """
        let output: [Token] = [
            .identifier("test"),
            .startOfScope("("),
            .identifier("image"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##UIImage#>"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func xcodeWithArrayAndClosureToken() {
        let input = """
        monkey(smelly: <#T##Bool#>, happy: <#T##Bool#>, names: <#T##[String]#>, throw💩: <#T##((Int) -> Void)##((Int) -> Void)##(Int) -> Void#>)
        """
        let output: [Token] = [
            .identifier("monkey"),
            .startOfScope("("),
            .identifier("smelly"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##Bool#>"),
            .delimiter(","),
            .space(" "),
            .identifier("happy"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##Bool#>"),
            .delimiter(","),
            .space(" "),
            .identifier("names"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##[String]#>"),
            .delimiter(","),
            .space(" "),
            .identifier("throw💩"),
            .delimiter(":"),
            .space(" "),
            .identifier("<#T##((Int) -> Void)##((Int) -> Void)##(Int) -> Void#>"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

}
