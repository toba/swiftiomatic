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

import Testing
@Suite
struct TernaryExprTests: LayoutTesting {
  @Test func bothBranchesOnTheirOwnLineWhenTernaryWraps() {
    // When the ternary itself wraps, both `?` and `:` each get their own line,
    // even if the `? a : b` portion would fit together on the wrapped line.
    let input =
      """
      let pendingLeadingTrivia = trailingNonSpace.isEmpty ? token.leadingTrivia : token.leadingTrivia + trailingNonSpace
      """
    let expected =
      """
      let pendingLeadingTrivia = trailingNonSpace.isEmpty
        ? token.leadingTrivia
        : token.leadingTrivia + trailingNonSpace

      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func assignmentPrefersTernaryBreaksOverEqualsBreak() {
    // Breaking after `=` is a last resort. When a ternary RHS doesn't fit, prefer
    // breaking before `?` and `:` over breaking after `=`.
    let input =
      """
      let string = expectParameterLabel ? text.string.dropFirst(parameterPrefix.count) : text.string[...]
      """
    let expected =
      """
      let string = expectParameterLabel
        ? text.string.dropFirst(parameterPrefix.count)
        : text.string[...]

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func ternaryExprs() {
    let input =
      """
      let x = a ? b : c
      let y = a ?b:c
      let z = a ? b: c
      let reallyLongName = a ? longTruePart : longFalsePart
      let reallyLongName = reallyLongCondition ? reallyLongTruePart : reallyLongFalsePart
      let reallyLongName = reallyLongCondition ? reallyReallyReallyLongTruePart : reallyLongFalsePart
      let reallyLongName = someCondition ? firstFunc(foo: arg) : secondFunc(bar: arg)
      """

    let expected =
      """
      let x = a ? b : c
      let y = a ? b : c
      let z = a ? b : c
      let reallyLongName = a
        ? longTruePart
        : longFalsePart
      let reallyLongName = reallyLongCondition
        ? reallyLongTruePart
        : reallyLongFalsePart
      let reallyLongName = reallyLongCondition
        ? reallyReallyReallyLongTruePart
        : reallyLongFalsePart
      let reallyLongName = someCondition
        ? firstFunc(foo: arg)
        : secondFunc(bar: arg)

      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  @Test func ternaryExprsWithMultiplePartChoices() {
    let input =
      """
      let someLocalizedText =
        shouldUseTheFirstOption ? stringFunc(name: "Name1", comment: "short comment") :
        stringFunc(name: "Name2", comment: "Some very, extremely long comment", details: "Another comment")
      """
    let expected =
      """
      let someLocalizedText = shouldUseTheFirstOption
        ? stringFunc(name: "Name1", comment: "short comment")
        : stringFunc(
          name: "Name2", comment: "Some very, extremely long comment",
          details: "Another comment")

      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func ternaryWithWrappingExpressions() {
    let input =
      """
      foo = firstTerm + secondTerm + thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      let foo = firstTerm + secondTerm + thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      foo = firstTerm || secondTerm && thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      let foo = firstTerm || secondTerm && thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      """

    let expected =
      """
      foo = firstTerm
        + secondTerm
        + thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm
      let foo =
        firstTerm
        + secondTerm
        + thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm
      foo = firstTerm
        || secondTerm
          && thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm
      let foo =
        firstTerm
        || secondTerm
          && thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm

      """

    assertLayout(input: input, expected: expected, linelength: 15)
  }

  @Test func nestedTernaries() {
    let input =
      """
      a = b ? c : d ? e : f
      let a = b ? c : d ? e : f
      a = b ? c0 + c1 : d ? e : f
      let a = b ? c0 + c1 : d ? e : f
      a = b ? c0 + c1 + c2 + c3 : d ? e : f
      let a = b ? c0 + c1 + c2 + c3 : d ? e : f
      foo = testA ? testB ? testC : testD : testE ? testF : testG
      let foo = testA ? testB ? testC : testD : testE ? testF : testG
      """

    let expected =
      """
      a = b
        ? c
        : d ? e : f
      let a = b
        ? c
        : d ? e : f
      a = b
        ? c0 + c1
        : d ? e : f
      let a = b
        ? c0 + c1
        : d ? e : f
      a = b
        ? c0 + c1
          + c2 + c3
        : d ? e : f
      let a = b
        ? c0 + c1
          + c2 + c3
        : d ? e : f
      foo = testA
        ? testB
          ? testC
          : testD
        : testE
          ? testF
          : testG
      let foo = testA
        ? testB
          ? testC
          : testD
        : testE
          ? testF
          : testG

      """

    assertLayout(input: input, expected: expected, linelength: 15)
  }

  @Test func expressionStartsWithTernary() {
    // When the ternary itself doesn't already start on a continuation line, we don't have a way
    // to indent the continuation of the condition differently from the first and second choices,
    // because we don't want to double-indent the condition's continuation lines, and we don't want
    // to keep put the choices at the same indentation level as the condition (because that would
    // be the start of the statement). Neither of these choices is really ideal, unfortunately.
    let input =
      """
      condition ? callSomething() : callSomethingElse()
      condition && otherCondition ? callSomething() : callSomethingElse()
      (condition && otherCondition) ? callSomething() : callSomethingElse()
      """

    let expected =
      """
      condition
        ? callSomething()
        : callSomethingElse()
      condition
        && otherCondition
        ? callSomething()
        : callSomethingElse()
      (condition
        && otherCondition)
        ? callSomething()
        : callSomethingElse()

      """

    assertLayout(input: input, expected: expected, linelength: 25)
  }

  @Test func parenthesizedTernary() {
    let input =
      """
      let a = (
          foo ?
            bar : baz
        )
      a = (
          foo ?
            bar : baz
        )
      b = foo ? (
        bar
        ) : (
        baz
        )
      c = foo ?
        (
          foo2 ? nestedBar : nestedBaz
        ) : (baz)
      """

    let expected =
      """
      let a = (foo ? bar : baz)
      a = (foo ? bar : baz)
      b = foo ? (bar) : (baz)
      c = foo ? (foo2 ? nestedBar : nestedBaz) : (baz)

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }
}
