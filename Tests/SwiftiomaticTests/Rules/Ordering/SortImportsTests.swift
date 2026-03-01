import Testing

@testable import Swiftiomatic

@Suite struct SortImportsTests {
  @Test func sortImportsSimpleCase() {
    let input = """
      import Foo
      import Bar
      """
    let output = """
      import Bar
      import Foo
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func sortImportsKeepsPreviousCommentWithImport() {
    let input = """
      import Foo
      // important comment
      // (very important)
      import Bar
      """
    let output = """
      // important comment
      // (very important)
      import Bar
      import Foo
      """
    testFormatting(
      for: input, output, rule: .sortImports,
      exclude: [.blankLineAfterImports],
    )
  }

  @Test func sortImportsKeepsPreviousCommentWithImport2() {
    let input = """
      // important comment
      // (very important)
      import Foo
      import Bar
      """
    let output = """
      import Bar
      // important comment
      // (very important)
      import Foo
      """
    testFormatting(
      for: input, output, rule: .sortImports,
      exclude: [.blankLineAfterImports],
    )
  }

  @Test func sortImportsDoesNotMoveHeaderComment() {
    let input = """
      // header comment

      import Foo
      import Bar
      """
    let output = """
      // header comment

      import Bar
      import Foo
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func sortImportsDoesNotMoveHeaderCommentFollowedByImportComment() {
    let input = """
      // header comment

      // important comment
      import Foo
      import Bar
      """
    let output = """
      // header comment

      import Bar
      // important comment
      import Foo
      """
    testFormatting(
      for: input, output, rule: .sortImports,
      exclude: [.blankLineAfterImports],
    )
  }

  @Test func sortImportsOnSameLine() {
    let input = """
      import Foo; import Bar
      import Baz
      """
    let output = """
      import Baz
      import Foo; import Bar
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func sortImportsWithSemicolonAndCommentOnSameLine() {
    let input = """
      import Foo; // foobar
      import Bar
      import Baz
      """
    let output = """
      import Bar
      import Baz
      import Foo; // foobar
      """
    testFormatting(for: input, output, rule: .sortImports, exclude: [.semicolons])
  }

  @Test func sortImportEnum() {
    let input = """
      import enum Foo.baz
      import Foo.bar
      """
    let output = """
      import Foo.bar
      import enum Foo.baz
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func sortImportFunc() {
    let input = """
      import func Foo.baz
      import Foo.bar
      """
    let output = """
      import Foo.bar
      import func Foo.baz
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func alreadySortImportsDoesNothing() {
    let input = """
      import Bar
      import Foo
      """
    testFormatting(for: input, rule: .sortImports)
  }

  @Test func preprocessorSortImports() {
    let input = """
      #if os(iOS)
          import Foo2
          import Bar2
      #else
          import Foo1
          import Bar1
      #endif
      import Foo3
      import Bar3
      """
    let output = """
      #if os(iOS)
          import Bar2
          import Foo2
      #else
          import Bar1
          import Foo1
      #endif
      import Bar3
      import Foo3
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func ableSortImports() {
    let input = """
      @testable import Foo3
      import Bar3
      """
    let output = """
      import Bar3
      @testable import Foo3
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func lengthSortImports() {
    let input = """
      import Foo
      import Module
      import Bar3
      """
    let output = """
      import Foo
      import Bar3
      import Module
      """
    let options = FormatOptions(importGrouping: .length)
    testFormatting(for: input, output, rule: .sortImports, options: options)
  }

  @Test func ableImportsWithTestableOnPreviousLine() {
    let input = """
      @testable
      import Foo3
      import Bar3
      """
    let output = """
      import Bar3
      @testable
      import Foo3
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func ableImportsWithGroupingTestableBottom() {
    let input = """
      @testable import Bar
      import Foo
      @testable import UIKit
      """
    let output = """
      import Foo
      @testable import Bar
      @testable import UIKit
      """
    let options = FormatOptions(importGrouping: .testableLast)
    testFormatting(for: input, output, rule: .sortImports, options: options)
  }

  @Test func ableImportsWithGroupingTestableTop() {
    let input = """
      @testable import Bar
      import Foo
      @testable import UIKit
      """
    let output = """
      @testable import Bar
      @testable import UIKit
      import Foo
      """
    let options = FormatOptions(importGrouping: .testableFirst)
    testFormatting(for: input, output, rule: .sortImports, options: options)
  }

  @Test func caseInsensitiveSortImports() {
    let input = """
      import Zlib
      import lib
      """
    let output = """
      import lib
      import Zlib
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func caseInsensitiveCaseDifferingSortImports() {
    let input = """
      import c
      import B
      import A.a
      import A.A
      """
    let output = """
      import A.A
      import A.a
      import B
      import c
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func noDeleteCodeBetweenImports() {
    let input = """
      import Foo
      func bar() {}
      import Bar
      """
    testFormatting(
      for: input, rule: .sortImports,
      exclude: [.blankLineAfterImports],
    )
  }

  @Test func noDeleteCodeBetweenImports2() {
    let input = """
      import Foo
      import Bar
      foo = bar
      import Bar
      """
    let output = """
      import Bar
      import Foo
      foo = bar
      import Bar
      """
    testFormatting(
      for: input, output, rule: .sortImports,
      exclude: [.blankLineAfterImports],
    )
  }

  @Test func noDeleteCodeBetweenImports3() {
    let input = """
      import Z

      // one

      #if FLAG
          print("hi")
      #endif

      import A
      """
    testFormatting(for: input, rule: .sortImports)
  }

  @Test func sortContiguousImports() {
    let input = """
      import Foo
      import Bar
      func bar() {}
      import Quux
      import Baz
      """
    let output = """
      import Bar
      import Foo
      func bar() {}
      import Baz
      import Quux
      """
    testFormatting(
      for: input, output, rule: .sortImports,
      exclude: [.blankLineAfterImports],
    )
  }

  @Test func noMangleImportsPrecededByComment() {
    let input = """
      // evil comment

      #if canImport(Foundation)
          import Foundation
          #if canImport(UIKit) && canImport(AVFoundation)
              import UIKit
              import AVFoundation
          #endif
      #endif
      """
    let output = """
      // evil comment

      #if canImport(Foundation)
          import Foundation
          #if canImport(UIKit) && canImport(AVFoundation)
              import AVFoundation
              import UIKit
          #endif
      #endif
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func noMangleFileHeaderNotFollowedByLinebreak() {
    let input = """
      //
      //  Code.swift
      //  Module
      //
      //  Created by Someone on 4/30/20.
      //
      import AModuleUI
      import AModule
      import AModuleHelper
      import SomeOtherModule
      """
    let output = """
      //
      //  Code.swift
      //  Module
      //
      //  Created by Someone on 4/30/20.
      //
      import AModule
      import AModuleHelper
      import AModuleUI
      import SomeOtherModule
      """
    testFormatting(for: input, output, rule: .sortImports)
  }

  @Test func noMoveSwiftToolsVersionLine() {
    let input = """
      // swift-tools-version: 6.2
      import PackageDescription
      import CompilerPluginSupport
      """
    let output = """
      // swift-tools-version: 6.2
      import CompilerPluginSupport
      import PackageDescription
      """
    testFormatting(for: input, output, rule: .sortImports)
  }
}
