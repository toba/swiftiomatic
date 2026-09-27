import Testing

@testable import SwiftiomaticKit

/// Pins the pretty printer output for edge cases that the layout performance work touches. Each
/// expected string records the output before that work began.
@Suite
struct LayoutEdgeCasePinTests: LayoutTesting {
    @Test func mergedLineCommentRunKeepsTrailingSpaceTrimAndBlankLines() {
        let input = "struct S {\n    func f() {\n        // first line   \n        //\n        //   indented body\n        // last line\n        let x = 1\n    }\n}\n"
        assertLayout(input: input, expected: "struct S {\n  func f() {\n    // first line\n    //\n    //   indented body\n    // last line\n    let x = 1\n  }\n}\n", linelength: 80)
    }

    @Test func docLineRunFollowedByLineCommentRun() {
        let input = "enum E {\n    /// Doc one.\n    /// Doc two.\n    // plain one\n    // plain two\n    case a\n}\n"
        assertLayout(input: input, expected: "enum E {\n  /// Doc one.\n  /// Doc two.\n  //  plain one\n  //  plain two\n  case a\n}\n", linelength: 80)
    }

    @Test func commentedOutCodeAtColumnZeroKeepsItsColumn() {
        let input = "func f() {\n    if true {\n//    let a = 1\n//    let b = 2\n        g()\n    }\n}\n"
        assertLayout(input: input, expected: "func f() {\n  if true {\n//    let a = 1\n//    let b = 2\n    g()\n  }\n}\n", linelength: 80)
    }

    @Test func blockCommentsReindentWithLeadingIndent() {
        let input = "func f() {\n        /* first\n         * second\n\n         * third   \n         */\n    let a = 1\n      /** doc\n        body\n       */\n    let b = 2\n}\n"
        assertLayout(input: input, expected: "func f() {\n  /* first\n   * second\n\n   * third\n   */\n  let a = 1\n  /** doc\n    body\n   */\n  let b = 2\n}\n", linelength: 80)
    }

    @Test func blockCommentsReindentWithIndentBlankLines() {
        var config = Configuration.forTesting
        config[IndentBlankLines.self] = true
        let input = "func f() {\n    if true {\n        /* first\n\n           second */\n        let a = 1\n\n        let b = 2\n    }\n}\n"
        assertLayout(input: input, expected: "func f() {\n  if true {\n    /* first\n    \n       second */\n    let a = 1\n    \n    let b = 2\n  }\n}\n", linelength: 80, configuration: config)
    }

    @Test func ignoredNodeVerbatimIndentation() {
        let input = "struct S {\n    func f() {\n        // sm:ignore\n        let foo = bar( a, b,\n              c,\n    d)\n        g()\n    }\n}\n"
        assertLayout(input: input, expected: "struct S {\n  func f() {\n    // sm:ignore\n    let foo = bar( a, b,\n              c,\n    d)\n    g()\n  }\n}\n", linelength: 80)
    }

    @Test func tabIndentationWithContinuationAndAlignment() {
        var config = Configuration.forTesting
        config[IndentationSetting.self] = .tabs(1)
        config[TabWidth.self] = 4
        let input = "func f() {\n\tif aaaaaaaaaaaa && bbbbbbbbbbbbbb && cccccccccccccccccc {\n\t\tlet value = someFunction(argumentOne, argumentTwo, argumentThree)\n\t}\n}\n"
        assertLayout(input: input, expected: "func f() {\n\tif aaaaaaaaaaaa && bbbbbbbbbbbbbb\n\t\t&& cccccccccccccccccc\n\t{\n\t\tlet value = someFunction(\n\t\t\targumentOne, argumentTwo,\n\t\t\targumentThree)\n\t}\n}\n", linelength: 40, configuration: config)
    }

    @Test func nonASCIITokenWidthCountsGraphemes() {
        let input = "let s = f(\"日本語テキストの文字列です\", \"👩‍👩‍👧‍👦👩‍👩‍👧‍👦👩‍👩‍👧‍👦\", é)\nlet t = g(\"éééééééééééééééééééééééééé\", x)\n"
        assertLayout(input: input, expected: "let s = f(\"日本語テキストの文字列です\", \"👩‍👩‍👧‍👦👩‍👩‍👧‍👦👩‍👩‍👧‍👦\", é)\nlet t = g(\n  \"éééééééééééééééééééééééééé\", x)\n", linelength: 40)
    }

    @Test func chainAfterClosingDelimitersAloneOnLine() {
        let input = """
            let a = Button { doSomethingLong() } label: { Text("label text here") }.padding().foregroundStyle(.red)
            let b = OuterView(firstArgument: value, secondArgument: other, third: more).padding().bold()
            let c = [firstElement, secondElement, thirdElement, fourthElement].map { $0 }.filter { $0 }
            let d = view
                #if os(macOS)
                    .padding()
                #endif
                .frame(width: 100).background(Color.red).foregroundStyle(.blue)

            """
        assertLayout(input: input, expected: "let a = Button {\n  doSomethingLong()\n} label: { Text(\"label text here\") }\n    .padding().foregroundStyle(.red)\nlet b = OuterView(\n  firstArgument: value,\n  secondArgument: other, third: more\n).padding().bold()\nlet c = [\n  firstElement, secondElement,\n  thirdElement, fourthElement,\n].map { $0 }.filter { $0 }\nlet d = view\n  #if os(macOS)\n    .padding()\n  #endif\n  .frame(width: 100).background(\n    Color.red\n  ).foregroundStyle(.blue)\n", linelength: 40)
    }

    @Test func multilineChainBoostInBindingOperands() {
        let input = """
            func f() {
                let e = SomeType(argumentOne: 1, argumentTwo: 2).methodOne().methodTwo(parameter: value)
                return VStack { content() }.padding(.horizontal, 16).background(.red)
            }

            """
        assertLayout(input: input, expected: "func f() {\n  let e = SomeType(\n    argumentOne: 1, argumentTwo: 2\n  ).methodOne().methodTwo(\n    parameter: value)\n  return VStack { content() }.padding(\n    .horizontal, 16\n  ).background(.red)\n}\n", linelength: 40)
    }

    @Test func syntaxTokenWidthMatchesCharacterCount() {
        for text in ["", "abc", "a\r\nb", "\r", "é", "e\u{301}", "日本", "👩‍👩‍👧‍👦x", "tab\there"] {
            #expect(Token.columnWidth(of: text) == text.count, "\(text.debugDescription)")
        }
    }
}
