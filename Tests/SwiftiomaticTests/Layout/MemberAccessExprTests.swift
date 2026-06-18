//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftiomaticKit
import Testing

@Suite
struct MemberAccessExprTests: LayoutTesting {
  @Test func memberAccess() {
    let input =
      """
      let a = one.two.three.four.five
      let b = (c as TypeD).one.two.three.four
      """

    let expected =
      """
      let a = one.two
        .three.four
        .five
      let b =
        (c as TypeD)
        .one.two
        .three.four

      """

    assertLayout(input: input, expected: expected, linelength: 15)
  }

  @Test func implicitMemberAccess() {
    let input =
      """
      let array = [.first, .second, .third]
      """

    let expected =
      """
      let array = [
        .first,
        .second,
        .third,
      ]

      """

    assertLayout(input: input, expected: expected, linelength: 15)
  }

  @Test func methodChainingWithClosures() {
    let input =
      """
      let result = [1, 2, 3, 4, 5]
          .filter{$0 % 2 == 0}
          .map{$0 * $0}
      """

    let expected =
      """
      let result = [1, 2, 3, 4, 5]
        .filter { $0 % 2 == 0 }
        .map { $0 * $0 }

      """

    assertLayout(input: input, expected: expected, linelength: 30)
  }

  @Test func methodChainingWithClosuresFullWrap() {
    let input =
      """
      let result = [1, 2, 3, 4, 5].filter { $0 % 2 == 0 }.map { $0 * $0 }
      array.filter { $0 }.map { $0 as FooBarBaz }.compactMap { $0 }
      array.filter {
        $0 is FooBarBaz
      }.map { $0 as FooBarBaz }.compactMap { $0 }
      """

    let expectedNoForcedBreaks =
      """
      let result = [
        1, 2, 3, 4, 5,
      ].filter {
        $0 % 2 == 0
      }.map { $0 * $0 }
      array.filter { $0 }
        .map {
          $0 as FooBarBaz
        }.compactMap {
          $0
        }
      array.filter {
        $0 is FooBarBaz
      }.map {
        $0 as FooBarBaz
      }.compactMap { $0 }

      """

    assertLayout(input: input, expected: expectedNoForcedBreaks, linelength: 20)

    let expectedWithForcedBreaks =
      """
      let result = [
        1, 2, 3, 4, 5,
      ]
      .filter {
        $0 % 2 == 0
      }
      .map { $0 * $0 }
      array.filter { $0 }
        .map {
          $0 as FooBarBaz
        }
        .compactMap { $0 }
      array.filter {
        $0 is FooBarBaz
      }
      .map {
        $0 as FooBarBaz
      }
      .compactMap { $0 }

      """

    var configuration = Configuration.forTesting
    configuration[BreakAroundMultilineChainParts.self] = true
    assertLayout(
      input: input,
      expected: expectedWithForcedBreaks,
      linelength: 20,
      configuration: configuration
    )
  }

  @Test func continuationRestorationAfterGroup() {
    let input =
      """
      someLongReceiverName.someEvenLongerMethodName {
      }

      someLongReceiverName.someEvenLongerMethodName {
        bar()
        baz()
      }
      """

    let expected =
      """
      someLongReceiverName
        .someEvenLongerMethodName {}

      someLongReceiverName
        .someEvenLongerMethodName {
          bar()
          baz()
        }

      """

    assertLayout(input: input, expected: expected, linelength: 30)
  }

  @Test func operatorChainedMemberAccessExprs() {
    let input =
      """
      let totalHeight = Constants.textFieldHeight + Constants.borderHeight + Constants.importantLabelHeight
      """

    let expected =
      """
      let totalHeight = Constants.textFieldHeight
        + Constants.borderHeight + Constants.importantLabelHeight

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func baselessMemberAccess() {
    let input =
      """
      foo.bar(.someImplicitlyTypedMemberFunc(
        a, b, c))
      """

    // brm-7t3: the inner call is the sole argument of `foo.bar(...)`, so user-supplied
    // discretionary breaks inside its parens are dropped when the whole line fits.
    let expected =
      """
      foo.bar(.someImplicitlyTypedMemberFunc(a, b, c))

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func chainsUsingNonTrailingClosures() {
    let input =
      """
      myWeirdFunc(foo: bar, withClosure: { abc in
        abc.frob() }).map { $0 }.filter { $0.isFrobbed }
      myWeirdFunc(withClosure: { abc in
        abc.frob() }).map { $0 }.filter { $0.isFrobbed }

      """

    let expectedNoForcedBreaking =
      """
      myWeirdFunc(
        foo: bar,
        withClosure: { abc in
          abc.frob()
        }
      ).map { $0 }.filter {
        $0.isFrobbed
      }
      myWeirdFunc(withClosure: { abc in
        abc.frob()
      }).map { $0 }.filter {
        $0.isFrobbed
      }

      """

    assertLayout(input: input, expected: expectedNoForcedBreaking, linelength: 35)

    let expectedWithForcedBreaking =
      """
      myWeirdFunc(
        foo: bar,
        withClosure: { abc in
          abc.frob()
        }
      )
      .map { $0 }.filter { $0.isFrobbed }
      myWeirdFunc(withClosure: { abc in
        abc.frob()
      })
      .map { $0 }.filter { $0.isFrobbed }

      """

    var configuration = Configuration.forTesting
    configuration[BreakAroundMultilineChainParts.self] = true
    assertLayout(
      input: input,
      expected: expectedWithForcedBreaking,
      linelength: 35,
      configuration: configuration
    )
  }

  @Test func memberItemClosureChaining() {
    let input =
      """
      struct ContentView: View {
        var body: some View {
          VStack(alignment: .leading) {
            Text("Turtle Rock")
              .headlineTextRenderingFont(.title)
            HStack {
              Text("Joshua Tree National Park")
                .font(.subheadline) { Color(.blue) }
                .bold(true)
            }
            Image(.turtle) {
              presentTurtle()
            }.foreground[tintColors]
            Image(.swiftyBird) {
              presentBirds()
            }
            .highlight[tintColors]
          }
          .padding(10)
          Text("Rabbit Rock") { Font(.serifs) }
            .backgroundColor(.red)
        }
      }
      """

    let expectedNoForcedBreaks =
      """
      struct ContentView: View {
        var body: some View {
          VStack(alignment: .leading) {
            Text("Turtle Rock")
              .headlineTextRenderingFont(.title)
            HStack {
              Text("Joshua Tree National Park")
                .font(.subheadline) { Color(.blue) }
                .bold(true)
            }
            Image(.turtle) {
              presentTurtle()
            }.foreground[tintColors]
            Image(.swiftyBird) {
              presentBirds()
            }
            .highlight[tintColors]
          }
          .padding(10)
          Text("Rabbit Rock") { Font(.serifs) }
            .backgroundColor(.red)
        }
      }

      """

    assertLayout(input: input, expected: expectedNoForcedBreaks, linelength: 50)

    let expectedWithForcedBreaks =
      """
      struct ContentView: View {
        var body: some View {
          VStack(alignment: .leading) {
            Text("Turtle Rock")
              .headlineTextRenderingFont(.title)
            HStack {
              Text("Joshua Tree National Park")
                .font(.subheadline) { Color(.blue) }
                .bold(true)
            }
            Image(.turtle) {
              presentTurtle()
            }
            .foreground[tintColors]
            Image(.swiftyBird) {
              presentBirds()
            }
            .highlight[tintColors]
          }
          .padding(10)
          Text("Rabbit Rock") { Font(.serifs) }
            .backgroundColor(.red)
        }
      }

      """

    var configuration = Configuration.forTesting
    configuration[BreakAroundMultilineChainParts.self] = true
    assertLayout(
      input: input,
      expected: expectedWithForcedBreaks,
      linelength: 50,
      configuration: configuration
    )
  }

  @Test func chainedTrailingClosureMethods() {
    let input =
      """
        var button =  View.Button { Text("ABC") }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans)
        var button =  View.Button {
          // comment #0
          Text("ABC")
        }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans)
        var button =  View.Button { Text("ABC") }
          .action { presentAction() }.background(.red).text(.blue) .text(.red).font(.appleSans)
        var button =  View.Button { Text("ABC") }
          .action {
            // comment #1
            presentAction()  // comment #2
          }.background(.red).text(.blue) .text(.red).font(.appleSans) /* trailing comment */
      var button =  View.Button { Text("ABC") }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans).foo {
        abc in
        return abc.foo.bar
      }
      """

    let expectedNoForcedBreaks =
      """
      var button = View.Button { Text("ABC") }.action {
        presentAction()
      }.background(.red).text(.blue).text(.red).font(
        .appleSans)
      var button = View.Button {
        // comment #0
        Text("ABC")
      }.action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button = View.Button { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button = View.Button { Text("ABC") }
        .action {
          // comment #1
          presentAction()  // comment #2
        }.background(.red).text(.blue).text(.red).font(
          .appleSans) /* trailing comment */
      var button = View.Button { Text("ABC") }.action {
        presentAction()
      }.background(.red).text(.blue).text(.red).font(
        .appleSans
      ).foo {
        abc in
        return abc.foo.bar
      }

      """

    assertLayout(input: input, expected: expectedNoForcedBreaks, linelength: 50)

    let expectedWithForcedBreaks =
      """
      var button = View.Button { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button =
        View.Button {
          // comment #0
          Text("ABC")
        }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button = View.Button { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button = View.Button { Text("ABC") }
        .action {
          // comment #1
          presentAction()  // comment #2
        }
        .background(.red).text(.blue).text(.red)
        .font(.appleSans) /* trailing comment */
      var button = View.Button { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
        .foo {
          abc in
          return abc.foo.bar
        }

      """

    var configuration = Configuration.forTesting
    configuration[BreakAroundMultilineChainParts.self] = true
    assertLayout(
      input: input,
      expected: expectedWithForcedBreaks,
      linelength: 50,
      configuration: configuration
    )
  }

  @Test func compactSingleFuncCallArgCollapsesWhenFits() {
    // When a chain tail has a single labeled FunctionCallExpr argument that fits on one line,
    // the formatter must collapse it even if the source had a discretionary newline after `(`.
    let input =
      """
      utf8.reversed()
          .drop { (48...57).contains($0) }
          .dropFirst(3)
          .starts(
              with: symbol.utf8.reversed()
          )
      """

    let expected =
      """
      utf8.reversed()
        .drop { (48...57).contains($0) }
        .dropFirst(3)
        .starts(with: symbol.utf8.reversed())

      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func nestedMultiArgCallCollapsesWhenFits() {
    // brm-7t3: when a function call is the sole argument of a chain-tail call and the entire
    // line fits, drop discretionary newlines inside the inner call's parens so it collapses.
    let input =
      """
      ContentView()
          .frame(width: 800, height: 500)
          .withTint(Color(
              red: 0.45,
              green: 0.6,
              blue: 0.45
          ))
          .withPreviewFile()
      """

    let expected =
      """
      ContentView()
        .frame(width: 800, height: 500)
        .withTint(Color(red: 0.45, green: 0.6, blue: 0.45))
        .withPreviewFile()

      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func chainedSubscriptExprs() {
    let input =
      """
      var button =  View.Button[5, 4, 3] { Text("ABC") }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans)
      var button =  View.Button[5,
        4, 3] { Text("ABC") }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans)
      var button =  View.Button[5, 4, 3
      ] {
        // comment #0
        Text("ABC")
      }.action {
        // comment #1
        presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans) /* trailing comment */
      var button =  View.Button[5, 4, 3] {
        Text("ABC")
      }.action { presentAction() }.background(.red).text(.blue).text(.red).font(.appleSans)[5]
      """

    let expectedNoForcedBreaks =
      """
      var button = View.Button[5, 4, 3] { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button = View.Button[
        5,
        4, 3
      ] { Text("ABC") }.action { presentAction() }
        .background(.red).text(.blue).text(.red).font(
          .appleSans)
      var button = View.Button[
        5, 4, 3
      ] {
        // comment #0
        Text("ABC")
      }.action {
        // comment #1
        presentAction()
      }.background(.red).text(.blue).text(.red).font(
        .appleSans) /* trailing comment */
      var button = View.Button[5, 4, 3] {
        Text("ABC")
      }.action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)[5]

      """

    assertLayout(input: input, expected: expectedNoForcedBreaks, linelength: 50)

    let expectedWithForcedBreaks =
      """
      var button = View.Button[5, 4, 3] { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button =
        View.Button[
          5,
          4, 3
        ] { Text("ABC") }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)
      var button =
        View.Button[
          5, 4, 3
        ] {
          // comment #0
          Text("ABC")
        }
        .action {
          // comment #1
          presentAction()
        }
        .background(.red).text(.blue).text(.red)
        .font(.appleSans) /* trailing comment */
      var button =
        View.Button[5, 4, 3] {
          Text("ABC")
        }
        .action { presentAction() }.background(.red)
        .text(.blue).text(.red).font(.appleSans)[5]

      """

    var configuration = Configuration.forTesting
    configuration[BreakAroundMultilineChainParts.self] = true
    assertLayout(
      input: input,
      expected: expectedWithForcedBreaks,
      linelength: 50,
      configuration: configuration
    )
  }

  // on8-mme: a member-access chain that continues a *multiline* base indents as a continuation
  // rather than aligning flush with the statement (upstream swift-format keeps it flush). A bare
  // expression chain indents one level; a chain bound by `return` / `throw` / assignment indents
  // two (one for the binding continuation, one for the chain). Single-line bases are unaffected
  // (see `chainedTrailingClosureMethods` , whose `View.Button { … }` base is a single identifier).
  @Test func multilineBaseChainIndentsAsContinuation() {
    let input =
      """
      func bare() -> some View {
        OuterView(context: InnerContext(
          idValue: 1, withinValue: 2, atValue: 0, styleValue: 3))
        .padding(30)
        .background(Rectangle())
      }

      func ret() -> some View {
        return OuterView(context: InnerContext(
          idValue: 1, withinValue: 2, atValue: 0, styleValue: 3))
        .padding(30)
        .background(Rectangle())
      }

      let assigned = OuterView(context: InnerContext(
        idValue: 1, withinValue: 2, atValue: 0, styleValue: 3))
      .padding(30)
      .background(Rectangle())
      """

    let expected =
      """
      func bare() -> some View {
          OuterView(context: InnerContext(
              idValue: 1, withinValue: 2, atValue: 0, styleValue: 3))
              .padding(30)
              .background(Rectangle())
      }

      func ret() -> some View {
          return OuterView(context: InnerContext(
              idValue: 1, withinValue: 2, atValue: 0, styleValue: 3))
                  .padding(30)
                  .background(Rectangle())
      }

      let assigned = OuterView(context: InnerContext(
          idValue: 1, withinValue: 2, atValue: 0, styleValue: 3))
              .padding(30)
              .background(Rectangle())

      """

    var configuration = Configuration.forTesting
    configuration[IndentationSetting.self] = .spaces(4)
    assertLayout(input: input, expected: expected, linelength: 80, configuration: configuration)
  }

  // m2x-4bl: a `.`-chain following a closing brace/paren that sits *alone on its own line* (a
  // trailing-closure base like `Button { … } label: { … }` or `HStack { … }`) must stay flush
  // with that closing delimiter, NOT indent as a continuation. This is the trailing-closure
  // counterpart to `multilineBaseChainIndentsAsContinuation` (whose base wraps its *arguments* on
  // a content line and so does indent). The lone closing brace returns to the base indent, so the
  // chain aligns there.
  @Test func chainAfterLoneClosingBraceStaysFlush() {
    let input =
      """
      HStack {
          Spacer()
          ImportMenu("Import", type: .project)
          Button { createFolder(nil) } label: {
              Image(systemName: "folder.badge.plus")
              Text("Add Folder")
          }
          Button { showNewProjectSheet.toggle() } label: {
              Image(systemName: "document.badge.plus")
              Text("Add Project")
          }
          .labelStyle(.iconOnly)
      }
      .padding()
      """

    let expected =
      """
      HStack {
          Spacer()
          ImportMenu("Import", type: .project)
          Button { createFolder(nil) } label: {
              Image(systemName: "folder.badge.plus")
              Text("Add Folder")
          }
          Button { showNewProjectSheet.toggle() } label: {
              Image(systemName: "document.badge.plus")
              Text("Add Project")
          }
          .labelStyle(.iconOnly)
      }
      .padding()

      """

    var configuration = Configuration.forTesting
    configuration[IndentationSetting.self] = .spaces(4)
    assertLayout(input: input, expected: expected, linelength: 80, configuration: configuration)
  }
}
