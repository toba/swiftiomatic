import Testing

@testable import Swiftiomatic

@Suite struct MarkTypesTests {
  @Test func addsMarkBeforeTypes() {
    let input = """
      struct Foo {}
      class Bar {}
      enum Baz {}
      protocol Quux {}
      """

    let output = """
      // MARK: - Foo

      struct Foo {}

      // MARK: - Bar

      class Bar {}

      // MARK: - Baz

      enum Baz {}

      // MARK: - Quux

      protocol Quux {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func doesNotAddMarkBeforeStructWithExistingMark() {
    let input = """
      // MARK: - Foo

      struct Foo {}
      extension Foo {}
      """

    testFormatting(for: input, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func correctsTypoInTypeMark() {
    let input = """
      // mark: foo

      struct Foo {}
      extension Foo {}
      """

    let output = """
      // MARK: - Foo

      struct Foo {}
      extension Foo {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func updatesMarkAfterTypeIsRenamed() {
    let input = """
      // MARK: - FooBarControllerFactory

      struct FooBarControllerBuilder {}
      extension FooBarControllerBuilder {}
      """

    let output = """
      // MARK: - FooBarControllerBuilder

      struct FooBarControllerBuilder {}
      extension FooBarControllerBuilder {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func addsMarkBeforeTypeWithDocComment() {
    let input = """
      /// This is a doc comment with several
      /// lines of prose at the start
      ///  - And then, after the prose,
      ///  - a few bullet points just for fun
      actor Foo {}
      extension Foo {}
      """

    let output = """
      // MARK: - Foo

      /// This is a doc comment with several
      /// lines of prose at the start
      ///  - And then, after the prose,
      ///  - a few bullet points just for fun
      actor Foo {}
      extension Foo {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func fragment() {
    let input = """
      struct Foo {}
      extension Foo {}
      """

    testFormatting(
      for: input, rule: .markTypes,
      options: FormatOptions(typeMarkComment: "TYPE DEFINITION: %t", fragment: true),
      exclude: [.emptyExtensions],
    )
  }

  @Test func customTypeMarkAfterFileHeader() {
    let input = """
      // MyFile.swift

      struct Foo {}
      extension Foo {}
      """

    let output = """
      // MyFile.swift

      // TYPE DEFINITION: Foo

      struct Foo {}
      extension Foo {}
      """

    testFormatting(
      for: input, output, rule: .markTypes,
      options: FormatOptions(typeMarkComment: "TYPE DEFINITION: %t"),
      exclude: [.emptyExtensions],
    )
  }

  @Test func doesNothingForExtensionWithoutProtocolConformance() {
    let input = """
      extension Foo {}
      extension Foo {}
      """

    testFormatting(for: input, rule: .markTypes, exclude: [.emptyExtensions])
  }

  func preservesExistingCommentForExtensionWithNoConformances() {
    let input = """
      // MARK: Description of extension

      extension Foo {}
      extension Foo {}
      """

    testFormatting(for: input, rule: .markTypes)
  }

  @Test func addsMarkCommentForExtensionWithConformance() {
    let input = """
      extension Foo: BarProtocol {}
      extension Foo {}
      """

    let output = """
      // MARK: - Foo + BarProtocol

      extension Foo: BarProtocol {}
      extension Foo {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func updatesExtensionMarkToCorrectMark() {
    let input = """
      // MARK: - BarProtocol

      extension Foo: BarProtocol {}
      extension Foo {}
      """

    let output = """
      // MARK: - Foo + BarProtocol

      extension Foo: BarProtocol {}
      extension Foo {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func addsMarkCommentForExtensionWithMultipleConformances() {
    let input = """
      extension Foo: BarProtocol, BazProtocol {}
      extension Foo {}
      """

    let output = """
      // MARK: - Foo + BarProtocol, BazProtocol

      extension Foo: BarProtocol, BazProtocol {}
      extension Foo {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func updatesMarkCommentWithCorrectConformances() {
    let input = """
      // MARK: - Foo + BarProtocol

      extension Foo: BarProtocol, BazProtocol {}
      extension Foo {}
      """

    let output = """
      // MARK: - Foo + BarProtocol, BazProtocol

      extension Foo: BarProtocol, BazProtocol {}
      extension Foo {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func customExtensionMarkComment() {
    let input = """
      struct Foo {}
      extension Foo: BarProtocol {}
      extension String: BarProtocol {}
      """

    let output = """
      // MARK: - Foo

      struct Foo {}

      // EXTENSION: - BarProtocol

      extension Foo: BarProtocol {}

      // EXTENSION: - String: BarProtocol

      extension String: BarProtocol {}
      """

    testFormatting(
      for: input, output, rule: .markTypes,
      options: FormatOptions(
        extensionMarkComment: "EXTENSION: - %t: %c",
        groupedExtensionMarkComment: "EXTENSION: - %c",
      ),
    )
  }

  @Test func typeAndExtensionMarksTogether() {
    let input = """
      struct Foo {}
      extension Foo: Bar {}
      extension String: Bar {}
      """

    let output = """
      // MARK: - Foo

      struct Foo {}

      // MARK: Bar

      extension Foo: Bar {}

      // MARK: - String + Bar

      extension String: Bar {}
      """

    testFormatting(for: input, output, rule: .markTypes)
  }

  @Test func fullyQualifiedTypeNames() {
    let input = """
      extension MyModule.Foo: MyModule.MyNamespace.BarProtocol, QuuxProtocol {}
      extension MyModule.Foo {}
      """

    let output = """
      // MARK: - MyModule.Foo + MyModule.MyNamespace.BarProtocol, QuuxProtocol

      extension MyModule.Foo: MyModule.MyNamespace.BarProtocol, QuuxProtocol {}
      extension MyModule.Foo {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func whereClauseConformanceWithExactConstraint() {
    let input = """
      extension Array: BarProtocol where Element == String {}
      extension Array {}
      """

    let output = """
      // MARK: - Array + BarProtocol

      extension Array: BarProtocol where Element == String {}
      extension Array {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func whereClauseConformanceWithConformanceConstraint() {
    let input = """
      extension Array: BarProtocol where Element: BarProtocol {}
      extension Array {}
      """

    let output = """
      // MARK: - Array + BarProtocol

      extension Array: BarProtocol where Element: BarProtocol {}
      extension Array {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func whereClauseWithExactConstraint() {
    let input = """
      extension Array where Element == String {}
      extension Array {}
      """

    testFormatting(for: input, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func whereClauseWithConformanceConstraint() {
    let input = """
      // MARK: [BarProtocol] helpers

      extension Array where Element: BarProtocol {}
      extension Rules {}
      """

    testFormatting(for: input, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func placesMarkAfterImports() {
    let input = """
      import Foundation
      import os

      /// All of SwiftFormat's Rule implementation
      class Rules {}
      extension Rules {}
      """

    let output = """
      import Foundation
      import os

      // MARK: - Rules

      /// All of SwiftFormat's Rule implementation
      class Rules {}
      extension Rules {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func placesMarkAfterFileHeader() {
    let input = """
      //  Created by Nick Lockwood on 12/08/2016.
      //  Copyright 2016 Nick Lockwood

      /// All of SwiftFormat's Rule implementation
      class Rules {}
      extension Rules {}
      """

    let output = """
      //  Created by Nick Lockwood on 12/08/2016.
      //  Copyright 2016 Nick Lockwood

      // MARK: - Rules

      /// All of SwiftFormat's Rule implementation
      class Rules {}
      extension Rules {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func placesMarkAfterFileHeaderAndImports() {
    let input = """
      //  Created by Nick Lockwood on 12/08/2016.
      //  Copyright 2016 Nick Lockwood

      import Foundation
      import os

      /// All of SwiftFormat's Rule implementation
      class Rules {}
      extension Rules {}
      """

    let output = """
      //  Created by Nick Lockwood on 12/08/2016.
      //  Copyright 2016 Nick Lockwood

      import Foundation
      import os

      // MARK: - Rules

      /// All of SwiftFormat's Rule implementation
      class Rules {}
      extension Rules {}
      """

    testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtensions])
  }

  @Test func doesNothingIfOnlyOneDeclaration() {
    let input = """
      //  Created by Nick Lockwood on 12/08/2016.
      //  Copyright 2016 Nick Lockwood

      import Foundation
      import os

      /// All of SwiftFormat's Rule implementation
      class Rules {}
      """

    testFormatting(for: input, rule: .markTypes)
  }

  @Test func multipleExtensionsOfSameType() {
    let input = """
      extension Foo: BarProtocol {}
      extension Foo: QuuxProtocol {}
      """

    let output = """
      // MARK: - Foo + BarProtocol

      extension Foo: BarProtocol {}

      // MARK: - Foo + QuuxProtocol

      extension Foo: QuuxProtocol {}
      """

    testFormatting(for: input, output, rule: .markTypes)
  }

  @Test func neverMarkTypes() {
    let input = """
      struct EmptyFoo {}
      struct EmptyBar { }
      struct EmptyBaz {

      }
      struct Quux {
          let foo = 1
      }
      """

    let options = FormatOptions(markTypes: .never)
    testFormatting(
      for: input, rule: .markTypes, options: options,
      exclude: [
        .emptyBraces, .blankLinesAtStartOfScope, .blankLinesAtEndOfScope,
        .blankLinesBetweenScopes,
      ],
    )
  }

}
