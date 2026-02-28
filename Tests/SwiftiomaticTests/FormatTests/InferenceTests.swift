import Testing

@testable import Swiftiomatic

@Suite struct InferenceTests {
  // MARK: indent

  @Test func inferIndentLevel() {
    let input = """
      \t
      class Foo {
          func bar() {
              baz()
              quux()
              let foo = Foo()
          }
      }
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.indent.count == 4)
  }

  @Test func inferIndentWithComment() {
    let input = """
      class Foo {
          /*
           A multiline comment
            which has unusual
             indenting that
              might screw up
               the indent inference
           */
      }
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.indent.count == 4)
  }

  @Test func inferIndentWithWrappedFunction() {
    let input = """
      class Foo {
          func foo(arg: Int,
                   arg: Int,
                   arg: Int) {}

          func bar(arg: Int,
                   arg: Int,
                   arg: Int) {}

          func baz(arg: Int,
                   arg: Int,
                   arg: Int) {}
      }
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.indent.count == 4)
  }

  @Test func ignoreMultilineCommentWhenInferringIndent() {
    let input = """
      /**
       a
       b
       c
       */
      func foo(
          bar: Int
      )
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.indent.count == 4)
  }

  // MARK: linebreak

  @Test func inferLinebreaks() {
    let input = "foo\nbar\r\nbaz\rquux\r\n"
    let output = "\r\n"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.linebreak == output)
  }

  // MARK: allowInlineSemicolons

  @Test func inferAllowInlineSemicolons() {
    let input = "let foo = 5; let bar = 6"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.semicolons == .inlineOnly)
  }

  @Test func inferNoAllowInlineSemicolons() {
    let input = "let foo = 5\nlet bar = 6"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.semicolons == .never)
  }

  @Test func noInferAllowInlineSemicolonsFromTerminatingSemicolon() {
    let input = "let foo = 5;\nlet bar = 6"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.semicolons == .never)
  }

  // MARK: useVoid

  @Test func inferUseVoid() {
    let input = "func foo(bar: () -> (Void), baz: ()->(), quux: () -> Void) {}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.useVoid)
  }

  @Test func inferDontUseVoid() {
    let input = "func foo(bar: () -> (), baz: ()->(), quux: () -> Void) {}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(!(options.useVoid))
  }

  // MARK: trailingCommas

  @Test func inferTrailingCommas() {
    let input = "let foo = [\nbar,\n]\n let baz = [\nquux\n]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.trailingCommas == .always)
  }

  @Test func inferNoTrailingCommas() {
    let input = "let foo = [\nbar\n]\n let baz = [\nquux\n]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.trailingCommas == .never)
  }

  // MARK: truncateBlankLines

  @Test func inferNoTruncateBlanklines() {
    let input = "class Foo {\n    \nfunc bar() {\n        \n        //baz\n\n}\n    \n}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(!(options.truncateBlankLines))
  }

  // MARK: allmanBraces

  @Test func inferAllmanComments() {
    let input = "func foo()\n{\n}\n\nfunc bar() {\n}\n\nfunc baz()\n{\n}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.allmanBraces)
  }

  // MARK: ifdefIndent

  @Test func inferIfdefIndent() {
    let input = "#if foo\n    //foo\n#endif"
    let output = IndentMode.indent
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.ifdefIndent == output)
  }

  @Test func inferIdententIfdefIndent() {
    let input = "{\n    {\n#    if foo\n        //foo\n    #endif\n    }\n}"
    let output = IndentMode.indent
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.ifdefIndent == output)
  }

  @Test func inferIfdefNoIndent() {
    let input = "#if foo\n//foo\n#endif"
    let output = IndentMode.noIndent
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.ifdefIndent == output)
  }

  @Test func inferIdententIfdefNoIndent() {
    let input = "{\n    {\n    #if foo\n    //foo\n    #endif\n    }\n}"
    let output = IndentMode.noIndent
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.ifdefIndent == output)
  }

  @Test func inferIfdefPreserve() {
    let input = """
      struct ContentView {
          var body: some View {
              Text("Example")
                  .frame(maxWidth: 200)
                  #if DEBUG
                  .font(.body)
                  #endif
                  .padding()
          }
      }
      """
    let output = IndentMode.preserve
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.ifdefIndent == output)
  }

  @Test func inferIndentedIfdefOutdent() {
    let input = "{\n    {\n#if foo\n        //foo\n#endif\n    }\n}"
    let output = IndentMode.outdent
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.ifdefIndent == output)
  }

  // MARK: wrapArguments

  @Test func inferWrapBeforeFirstArgument() {
    let input = """
      foo(
          bar: Int,
          baz: String)
      foo(
          bar: Int,
          baz: String
      )
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.wrapArguments == .beforeFirst)
  }

  @Test func inferWrapBeforeFirstParameter() {
    let input = """
      func foo(
          bar: Int,
          baz: String) {}
      func foo(
          bar: Int,
          baz: String)
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.wrapParameters == .beforeFirst)
  }

  @Test func inferWrapAfterFirstArgument() {
    let input = """
      foo(bar: Int,
          baz: String, quux: String)
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.wrapArguments == .afterFirst)
  }

  @Test func inferWrapAfterFirstParameter() {
    let input = """
      func foo(bar: Int,
               baz: String,
               quux: String) {}
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.wrapParameters == .afterFirst)
  }

  @Test func inferWrapPreserve() {
    let input = """
      func foo(
          bar: Int,
          baz: String) {}
      func foo(
          bar: Int,
          baz: String) {}
      func foo(
          bar: Int,
          baz: String)
      func foo(bar: Int,
               baz: String,
               quux: String) {}
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.wrapArguments == .preserve)
  }

  // MARK: wrapCollections

  @Test func inferWrapElementsAfterFirstArgument() {
    let input = "[foo: 1,\n    bar: 2, baz: 3]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.wrapCollections == .afterFirst)
  }

  @Test func inferWrapElementsAfterSecondArgument() {
    let input = "[foo, bar,\n]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.wrapCollections == .afterFirst)
  }

  // MARK: closingParenPosition

  @Test func inferParenOnSameLine() {
    let input =
      "func foo(\n    bar: Int,\n    baz: String) {\n}\nfunc foo(\n    bar: Int,\n    baz: String)"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.closingParenPosition == .sameLine)
  }

  @Test func inferParenOnNextLine() {
    let input =
      "func foo(\n    bar: Int,\n    baz: String) {\n}\nfunc foo(\n    bar: Int,\n    baz: String\n)"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.closingParenPosition == .balanced)
  }

  // MARK: uppercaseHex

  @Test func inferUppercaseHex() {
    let input = "[0xFF00DD, 0xFF00ee, 0xff00ee"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.uppercaseHex)
  }

  @Test func inferLowercaseHex() {
    let input = "[0xff00dd, 0xFF00ee, 0xff00ee"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(!(options.uppercaseHex))
  }

  // MARK: uppercaseExponent

  @Test func inferUppercaseExponent() {
    let input = "[1.34E-5, 1.34E-5]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.uppercaseExponent)
  }

  @Test func inferLowercaseExponent() {
    let input = "[1.34E-5, 1.34e-5]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(!(options.uppercaseExponent))
  }

  @Test func inferUppercaseHexExponent() {
    let input = "[0xF1.34P5, 0xF1.34P5]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.uppercaseExponent)
  }

  @Test func inferLowercaseHexExponent() {
    let input = "[0xF1.34P5, 0xF1.34p5]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(!(options.uppercaseExponent))
  }

  // MARK: decimalGrouping

  @Test func inferThousands() {
    let input = "[100_000, 1_000, 1, 23, 50]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.decimalGrouping == .group(3, 4))
  }

  @Test func inferMillions() {
    let input = "[1_000_000, 1000, 1, 23, 50]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.decimalGrouping == .group(3, 7))
  }

  @Test func inferNoDecimalGrouping() {
    let input = "[100000, 1000, 1, 23, 50]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.decimalGrouping == .none)
  }

  @Test func inferIgnoreDecimalGrouping() {
    let input = "[1000_00, 1_000, 100, 23, 50]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.decimalGrouping == .ignore)
  }

  // MARK: fractionGrouping

  @Test func inferFractionGrouping() {
    let input = "[100.0_001, 1.00_002, 1.0, 23.001, 50]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.fractionGrouping)
  }

  @Test func inferFractionGrouping2() {
    let input = "[100.0_001, 1.00_002, 1_000.0, 23_234.001, 50]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.fractionGrouping)
  }

  @Test func inferNoFractionGrouping() {
    let input = "[1.00002, 1.0001, 1.103, 0.23, 0.50]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(!(options.fractionGrouping))
  }

  @Test func inferNoFractionGrouping2() {
    let input = "[1_000.00002, 1_123.0001, 1.103, 0.23, 0.50]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(!(options.fractionGrouping))
  }

  // MARK: binaryGrouping

  @Test func inferNibbleGrouping() {
    let input = "[0b100_0000, 0b1_0000, 0b1, 0b01, 0b11]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.binaryGrouping == .group(4, 5))
  }

  @Test func inferByteGrouping() {
    let input = "[0b1000_1101, 0b10010000, 0b1, 0b01, 0b11]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.binaryGrouping == .group(4, 8))
  }

  @Test func inferNoBinaryGrouping() {
    let input = "[0b1010100000, 0b100100, 0b1, 0b01, 0b11]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.binaryGrouping == .none)
  }

  @Test func inferIgnoreBinaryGrouping() {
    let input = "[0b10_000_00, 0b10_000, 0b1, 0b01, 0b11]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.binaryGrouping == .ignore)
  }

  // MARK: octalGrouping

  @Test func inferQuadOctalGrouping() {
    let input = "[0o123_4523, 0b1_4523, 0o5, 0o23, 0o14]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.octalGrouping == .group(4, 7))
  }

  @Test func inferOctetOctalGrouping() {
    let input = "[0o1123_4523_1123_4523, 0o12344563, 0o1, 0o01, 0o12]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.octalGrouping == .group(4, 16))
  }

  @Test func inferNoOctalGrouping() {
    let input = "[0o11234523, 0o112345, 0o1, 0o01, 0o21]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.octalGrouping == .none)
  }

  @Test func inferIgnoreOctalGrouping() {
    let input = "[0o11_2345_23, 0o1_0000, 0o1, 0o01, 0o11]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.octalGrouping == .ignore)
  }

  // MARK: hexGrouping

  @Test func inferQuadHexGrouping() {
    let input = "[0x123_FF23, 0x1_4523, 0x5, 0x23, 0x14]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.hexGrouping == .group(4, 5))
  }

  @Test func inferOctetHexGrouping() {
    let input = "[0x1123_45FF_112A_A523, 0x12344563, 0x1, 0x01, 0x12]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.hexGrouping == .group(4, 16))
  }

  @Test func inferNoHexGrouping() {
    let input = "[0x11234523, 0x112345, 0x1, 0x01, 0x21]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.hexGrouping == .none)
  }

  @Test func inferIgnoreHexGrouping() {
    let input = "[0x11_2345_23, 0x10_F00, 0x1, 0x01, 0x11]"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.hexGrouping == .ignore)
  }

  // MARK: hoistPatternLet

  @Test func inferHoisted() {
    let input = "if case let .foo(bar, baz) = quux {}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.hoistPatternLet)
  }

  @Test func inferUnhoisted() {
    let input = "if case .foo(let bar, let baz) = quux {}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(!(options.hoistPatternLet))
  }

  @Test func inferUnhoisted2() {
    let input = "if case .foo(let bar, _) = quux {}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(!(options.hoistPatternLet))
  }

  // MARK: removeSelf

  @Test func inferInsertSelf() {
    let input = """
      struct Foo {
          var foo: Int
          var bar: Int
          func baz() {
              self.foo()
              self.bar()
          }
      }
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.explicitSelf == .insert)
  }

  @Test func inferRemoveSelf() {
    let input = """
      struct Foo {
          var foo: Int
          var bar: Int
          func baz() {
              foo()
              bar()
          }
      }
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.explicitSelf == .remove)
  }

  @Test func inferRemoveSelf2() {
    let input = """
      struct Foo {
          var foo: Int
          var bar: Int
          func baz() {
              self.foo()
              bar()
          }
      }
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.explicitSelf == .remove)
  }

  @Test func inferSelfInInitOnly() {
    let input = """
      struct Foo {
          var foo: Int
          var bar: Int
          init() {
              self.foo = 5
              self.bar = 6
          }
          func baz() {
              foo()
              bar()
          }
      }
      """
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.explicitSelf == .initOnly)
  }

  // MARK: spaceAroundOperatorDeclarations

  @Test func inferSpaceAfterOperatorFunc() {
    let input = "func == (lhs: Int, rhs: Int) -> Bool {}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.spaceAroundOperatorDeclarations == .insert)
  }

  @Test func inferNoSpaceAfterOperatorFunc() {
    let input = "func ==(lhs: Int, rhs: Int) -> Bool {}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.spaceAroundOperatorDeclarations == .remove)
  }

  // MARK: elseOnNextLine

  @Test func inferElseOnNextLine() {
    let input = "if foo {\n}\nelse {}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.elsePosition == .nextLine)
  }

  @Test func inferElseOnSameLine() {
    let input = "if foo {\n} else {}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.elsePosition == .sameLine)
  }

  @Test func ignoreInlineIfElse() {
    let input = "if foo {} else {}\nif foo {\n}\nelse {}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.elsePosition == .nextLine)
  }

  // MARK: indentCase

  @Test func inferIndentCase() {
    let input = "switch {\n    case foo: break\n}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.indentCase)
  }

  @Test func inferNoIndentCase() {
    let input = "switch {\ncase foo: break\n}"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(!(options.indentCase))
  }

  // MARK: nospaceoperators

  @Test func inferNoSpaceAroundTimesOperator() {
    let input = "let foo = a*b + c / d + e*f"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.noSpaceOperators == ["*"])
  }

  @Test func inferSpaceAroundTimesOperator() {
    let input = "let foo = a*b + c * d + e*f"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.noSpaceOperators == [])
  }

  @Test func inferNoSpaceAroundTimesAndDivideOperator() {
    let input = "let foo = a*b + c*d"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.noSpaceOperators == ["/", "*"])
  }

  @Test func inferSpaceAroundRangeOperators() {
    let input = "let foo = a ... b"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.noSpaceOperators == [])
  }

  @Test func inferSpaceAroundRangeOperators2() {
    let input = "let foo = a ..< b"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.noSpaceOperators == [])
  }

  @Test func inferSpaceAroundRangeOperators3() {
    let input = "let foo = a...b; let bar = a...b; let baz = a ..< b"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.noSpaceOperators == ["..."])
  }

  @Test func inferNoSpaceAroundRangeOperators3() {
    let input = "let foo = a...b; let bar = a...b"
    let options = inferFormatOptions(from: tokenize(input))
    #expect(options.noSpaceOperators == ["...", "..<"])
  }
}
