import Testing
@testable import Swiftiomatic

extension TokenizerTests {
    // MARK: Operators

    @Test func basicOperator() {
        let input = "+="
        let output: [Token] = [.operator("+=", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func divide() {
        let input = "a / b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("/", .infix),
            .space(" "),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func customOperator() {
        let input = "~="
        let output: [Token] = [.operator("~=", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func customOperator2() {
        let input = "a <> b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("<>", .infix),
            .space(" "),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func customOperator3() {
        let input = "a |> b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("|>", .infix),
            .space(" "),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func customOperator4() {
        let input = "a <<>> b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("<<>>", .infix),
            .space(" "),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func sequentialOperators() {
        let input = "a *= -b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("*=", .infix),
            .space(" "),
            .operator("-", .prefix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func dotPrefixedOperator() {
        let input = "..."
        let output: [Token] = [.operator("...", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func angleBracketSuffixedOperator() {
        let input = "..<"
        let output: [Token] = [.operator("..<", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func angleBracketSuffixedOperator2() {
        let input = "a..<b"
        let output: [Token] = [
            .identifier("a"),
            .operator("..<", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func unicodeOperator() {
        let input = "≥"
        let output: [Token] = [.operator("≥", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func operatorFollowedByComment() {
        let input = "a+/* b */b"
        let output: [Token] = [
            .identifier("a"),
            .operator("+", .postfix),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("b"),
            .space(" "),
            .endOfScope("*/"),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func operatorPrecededBySpaceFollowedByComment() {
        let input = "a +/* b */b"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("+", .infix),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("b"),
            .space(" "),
            .endOfScope("*/"),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func operatorPrecededByComment() {
        let input = "a/* a */-b"
        let output: [Token] = [
            .identifier("a"),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("a"),
            .space(" "),
            .endOfScope("*/"),
            .operator("-", .prefix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func operatorPrecededByCommentFollowedBySpace() {
        let input = "a/* a */- b"
        let output: [Token] = [
            .identifier("a"),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("a"),
            .space(" "),
            .endOfScope("*/"),
            .operator("-", .infix),
            .space(" "),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func operatorMayContainDotIfStartsWithDot() {
        let input = ".*.."
        let output: [Token] = [.operator(".*..", .none)]
        #expect(tokenize(input) == output)
    }

    @Test func operatorMayNotContainDotUnlessStartsWithDot() {
        let input = "*.."
        let output: [Token] = [
            .operator("*", .prefix), // TODO: should be postfix
            .operator("..", .none),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func operatorStitchingDoesNotCreateIllegalToken() {
        let input = "a*..b"
        let output: [Token] = [
            .identifier("a"),
            .operator("*", .postfix),
            .operator("..", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func nullCoalescingOperator() {
        let input = "foo ?? bar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("??", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func ternary() {
        let input = "a ? b() : c"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("?", .infix),
            .space(" "),
            .identifier("b"),
            .startOfScope("("),
            .endOfScope(")"),
            .space(" "),
            .operator(":", .infix),
            .space(" "),
            .identifier("c"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func ternaryWithOddSpacing() {
        let input = "a ?b(): c"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator("?", .infix),
            .identifier("b"),
            .startOfScope("("),
            .endOfScope(")"),
            .operator(":", .infix),
            .space(" "),
            .identifier("c"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixOperatorBeforeLinebreak() {
        let input = "foo +\nbar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("+", .infix),
            .linebreak("\n", 1),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixOperatorAfterLinebreak() {
        let input = "foo\n+ bar"
        let output: [Token] = [
            .identifier("foo"),
            .linebreak("\n", 1),
            .operator("+", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixOperatorBeforeComment() {
        let input = "foo +/**/bar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("+", .infix),
            .startOfScope("/*"),
            .endOfScope("*/"),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixOperatorAfterComment() {
        let input = "foo/**/+ bar"
        let output: [Token] = [
            .identifier("foo"),
            .startOfScope("/*"),
            .endOfScope("*/"),
            .operator("+", .infix),
            .space(" "),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func prefixMinusBeforeMember() {
        let input = "-.foo"
        let output: [Token] = [
            .operator("-", .prefix),
            .operator(".", .prefix),
            .identifier("foo"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixMinusBeforeMember() {
        let input = "foo - .bar"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("-", .infix),
            .space(" "),
            .operator(".", .prefix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func postfixOperatorBeforeMember() {
        let input = "foo′.bar"
        let output: [Token] = [
            .identifier("foo"),
            .operator("′", .postfix),
            .operator(".", .infix),
            .identifier("bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func notOperator() {
        let input = "!foo"
        let output: [Token] = [
            .operator("!", .prefix),
            .identifier("foo"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func notOperatorAfterKeyword() {
        let input = "return !foo"
        let output: [Token] = [
            .keyword("return"),
            .space(" "),
            .operator("!", .prefix),
            .identifier("foo"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func stringDotMethod() {
        let input = "\"foo\".isEmpty"
        let output: [Token] = [
            .startOfScope("\""),
            .stringBody("foo"),
            .endOfScope("\""),
            .operator(".", .infix),
            .identifier("isEmpty"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func stringAssignment() {
        let input = "foo = \"foo\""
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .startOfScope("\""),
            .stringBody("foo"),
            .endOfScope("\""),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func infixNotEqualsInParens() {
        let input = "(!=)"
        let output: [Token] = [
            .startOfScope("("),
            .operator("!=", .none),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    // MARK: chevrons (might be operators or generics)

    @Test func lessThanGreaterThan() {
        let input = "a<b == a>c"
        let output: [Token] = [
            .identifier("a"),
            .operator("<", .infix),
            .identifier("b"),
            .space(" "),
            .operator("==", .infix),
            .space(" "),
            .identifier("a"),
            .operator(">", .infix),
            .identifier("c"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func lessThanGreaterThanFollowedByOperator() {
        let input = "a > -x, a<x, b > -y, b<y"
        let output: [Token] = [
            .identifier("a"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .operator("-", .prefix),
            .identifier("x"),
            .delimiter(","),
            .space(" "),
            .identifier("a"),
            .operator("<", .infix),
            .identifier("x"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .space(" "),
            .operator(">", .infix),
            .space(" "),
            .operator("-", .prefix),
            .identifier("y"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .operator("<", .infix),
            .identifier("y"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericTypeAmpersandProtocol() {
        let input = "Foo<Int> & Bar"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Int"),
            .endOfScope(">"),
            .space(" "),
            .operator("&", .infix),
            .space(" "),
            .identifier("Bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func customChevronOperatorFollowedByParen() {
        let input = "foo <?> (bar)"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("<?>", .infix),
            .space(" "),
            .startOfScope("("),
            .identifier("bar"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rightShift() {
        let input = "a>>b"
        let output: [Token] = [
            .identifier("a"),
            .operator(">>", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func leftShift() {
        let input = "a<<b"
        let output: [Token] = [
            .identifier("a"),
            .operator("<<", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func tripleShift() {
        let input = "a>>>b"
        let output: [Token] = [
            .identifier("a"),
            .operator(">>>", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func rightShiftEquals() {
        let input = "a>>=b"
        let output: [Token] = [
            .identifier("a"),
            .operator(">>=", .infix),
            .identifier("b"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func leftShiftInsideTernary() {
        let input = "foo ? bar<<24 : 0"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("?", .infix),
            .space(" "),
            .identifier("bar"),
            .operator("<<", .infix),
            .number("24", .integer),
            .space(" "),
            .operator(":", .infix),
            .space(" "),
            .number("0", .integer),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func bitshiftThatLooksLikeAGeneric() {
        let input = "a<b, b<c, d>>e"
        let output: [Token] = [
            .identifier("a"),
            .operator("<", .infix),
            .identifier("b"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .operator("<", .infix),
            .identifier("c"),
            .delimiter(","),
            .space(" "),
            .identifier("d"),
            .operator(">>", .infix),
            .identifier("e"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func basicGeneric() {
        let input = "Foo<Bar, Baz>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .delimiter(","),
            .space(" "),
            .identifier("Baz"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func nestedGenerics() {
        let input = "Foo<Bar<Baz>>"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .startOfScope("<"),
            .identifier("Baz"),
            .endOfScope(">"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func parameterPackGeneric() {
        let input = "Optional<(Wrapped, Other, repeat each Another)>"
        let output: [Token] = [
            .identifier("Optional"),
            .startOfScope("<"),
            .startOfScope("("),
            .identifier("Wrapped"),
            .delimiter(","),
            .space(" "),
            .identifier("Other"),
            .delimiter(","),
            .space(" "),
            .keyword("repeat"),
            .space(" "),
            .identifier("each"),
            .space(" "),
            .identifier("Another"),
            .endOfScope(")"),
            .endOfScope(">"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func functionThatLooksLikeGenericType() {
        let input = "y<CGRectGetMaxY(r)"
        let output: [Token] = [
            .identifier("y"),
            .operator("<", .infix),
            .identifier("CGRectGetMaxY"),
            .startOfScope("("),
            .identifier("r"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericClassDeclaration() {
        let input = "class Foo<T,U> {}"
        let output: [Token] = [
            .keyword("class"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .endOfScope(">"),
            .space(" "),
            .startOfScope("{"),
            .endOfScope("}"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericSubclassDeclaration() {
        let input = "class Foo<T,U>: Bar"
        let output: [Token] = [
            .keyword("class"),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .endOfScope(">"),
            .delimiter(":"),
            .space(" "),
            .identifier("Bar"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericFunctionDeclaration() {
        let input = "func foo<T>(bar:T)"
        let output: [Token] = [
            .keyword("func"),
            .space(" "),
            .identifier("foo"),
            .startOfScope("<"),
            .identifier("T"),
            .endOfScope(">"),
            .startOfScope("("),
            .identifier("bar"),
            .delimiter(":"),
            .identifier("T"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericClassInit() {
        let input = "foo = Foo<Int,String>()"
        let output: [Token] = [
            .identifier("foo"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Int"),
            .delimiter(","),
            .identifier("String"),
            .endOfScope(">"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericFollowedByDot() {
        let input = "Foo<Bar>.baz()"
        let output: [Token] = [
            .identifier("Foo"),
            .startOfScope("<"),
            .identifier("Bar"),
            .endOfScope(">"),
            .operator(".", .infix),
            .identifier("baz"),
            .startOfScope("("),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func constantThatLooksLikeGenericType() {
        let input = "(y<Pi)"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("y"),
            .operator("<", .infix),
            .identifier("Pi"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func tupleOfBoolsThatLooksLikeGeneric() {
        let input = "(Foo<T,U>V)"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("Foo"),
            .operator("<", .infix),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .operator(">", .infix),
            .identifier("V"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func tupleOfBoolsThatReallyLooksLikeGeneric() {
        let input = "(Foo<T,U>=V)"
        let output: [Token] = [
            .startOfScope("("),
            .identifier("Foo"),
            .operator("<", .infix),
            .identifier("T"),
            .delimiter(","),
            .identifier("U"),
            .operator(">=", .infix),
            .identifier("V"),
            .endOfScope(")"),
        ]
        #expect(tokenize(input) == output)
    }

    @Test func genericDeclarationThatLooksLikeTwoExpressions() {
        let input = "let d: a < b, b > = c"
        let output: [Token] = [
            .keyword("let"),
            .space(" "),
            .identifier("d"),
            .delimiter(":"),
            .space(" "),
            .identifier("a"),
            .space(" "),
            .startOfScope("<"),
            .space(" "),
            .identifier("b"),
            .delimiter(","),
            .space(" "),
            .identifier("b"),
            .space(" "),
            .endOfScope(">"),
            .space(" "),
            .operator("=", .infix),
            .space(" "),
            .identifier("c"),
        ]
        #expect(tokenize(input) == output)
    }

}
