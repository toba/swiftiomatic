import Testing

@testable import Swiftiomatic

@Suite struct RedundantTypeTests {
  @Test func varRedundantTypeRemoval() {
    let input = """
      var view: UIView = UIView()
      """
    let output = """
      var view = UIView()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options,
    )
  }

  @Test func varRedundantArrayTypeRemoval() {
    let input = """
      var foo: [String] = [String]()
      """
    let output = """
      var foo = [String]()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options,
    )
  }

  @Test func varRedundantDictionaryTypeRemoval() {
    let input = """
      var foo: [String: Int] = [String: Int]()
      """
    let output = """
      var foo = [String: Int]()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options,
    )
  }

  @Test func letRedundantGenericTypeRemoval() {
    let input = """
      let relay: BehaviourRelay<Int?> = BehaviourRelay<Int?>(value: nil)
      """
    let output = """
      let relay = BehaviourRelay<Int?>(value: nil)
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options,
    )
  }

  @Test func varNonRedundantTypeDoesNothing() {
    let input = """
      var view: UIView = UINavigationBar()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(for: input, rule: .redundantType, options: options)
  }

  @Test func letRedundantTypeRemoval() {
    let input = """
      let view: UIView = UIView()
      """
    let output = """
      let view = UIView()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options,
    )
  }

  @Test func letNonRedundantTypeDoesNothing() {
    let input = """
      let view: UIView = UINavigationBar()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(for: input, rule: .redundantType, options: options)
  }

  @Test func typeNoRedundancyDoesNothing() {
    let input = """
      let foo: Bar = 5
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(for: input, rule: .redundantType, options: options)
  }

  @Test func classTwoVariablesNoRedundantTypeDoesNothing() {
    let input = """
      final class LGWebSocketClient: WebSocketClient, WebSocketLibraryDelegate {
          var webSocket: WebSocketLibraryProtocol
          var timeoutIntervalForRequest: TimeInterval = LGCoreKitConstants.websocketTimeOutTimeInterval
      }
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(for: input, rule: .redundantType, options: options)
  }

  @Test func redundantTypeRemovedIfValueOnNextLine() {
    let input = """
      let view: UIView
          = UIView()
      """
    let output = """
      let view
          = UIView()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options,
    )
  }

  @Test func redundantTypeRemovedIfValueOnNextLine2() {
    let input = """
      let view: UIView =
          UIView()
      """
    let output = """
      let view =
          UIView()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options,
    )
  }

  @Test func allRedundantTypesRemovedInCommaDelimitedDeclaration() {
    let input = """
      var foo: Int = 0, bar: Int = 0
      """
    let output = """
      var foo = 0, bar = 0
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.singlePropertyPerLine],
    )
  }

  @Test func redundantTypeRemovalWithComment() {
    let input = """
      var view: UIView /* view */ = UIView()
      """
    let output = """
      var view /* view */ = UIView()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options,
    )
  }

  @Test func redundantTypeRemovalWithComment2() {
    let input = """
      var view: UIView = /* view */ UIView()
      """
    let output = """
      var view = /* view */ UIView()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options,
    )
  }

  @Test func nonRedundantTernaryConditionTypeNotRemoved() {
    let input = """
      let foo: Bar = Bar.baz() ? .bar1 : .bar2
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(for: input, rule: .redundantType, options: options)
  }

  @Test func ternaryConditionAfterLetNotTreatedAsPartOfExpression() {
    let input = """
      let foo: Bar = Bar.baz()
      baz ? bar2() : bar2()
      """
    let output = """
      let foo = Bar.baz()
      baz ? bar2() : bar2()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options,
    )
  }

  @Test func noRemoveRedundantTypeIfVoid() {
    let input = """
      let foo: Void = Void()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, rule: .redundantType,
      options: options, exclude: [.void],
    )
  }

  @Test func noRemoveRedundantTypeIfVoid2() {
    let input = """
      let foo: () = ()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, rule: .redundantType,
      options: options, exclude: [.void],
    )
  }

  @Test func noRemoveRedundantTypeIfVoid3() {
    let input = """
      let foo: [Void] = [Void]()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(for: input, rule: .redundantType, options: options)
  }

  @Test func noRemoveRedundantTypeIfVoid4() {
    let input = """
      let foo: Array<Void> = Array<Void>()
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, rule: .redundantType,
      options: options, exclude: [.typeSugar],
    )
  }

  @Test func noRemoveRedundantTypeIfVoid5() {
    let input = """
      let foo: Void? = Void?.none
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(for: input, rule: .redundantType, options: options)
  }

  @Test func noRemoveRedundantTypeIfVoid6() {
    let input = """
      let foo: Optional<Void> = Optional<Void>.none
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, rule: .redundantType,
      options: options, exclude: [.typeSugar],
    )
  }

  @Test func redundantTypeWithLiterals() {
    let input = """
      let a1: Bool = true
      let a2: Bool = false

      let b1: String = "foo"
      let b2: String = "\\(b1)"

      let c1: Int = 1
      let c2: Int = 1.0

      let d1: Double = 3.14
      let d2: Double = 3

      let e1: [Double] = [3.14]
      let e2: [Double] = [3]

      let f1: [String: Int] = ["foo": 5]
      let f2: [String: Int?] = ["foo": nil]
      """
    let output = """
      let a1 = true
      let a2 = false

      let b1 = "foo"
      let b2 = "\\(b1)"

      let c1 = 1
      let c2: Int = 1.0

      let d1 = 3.14
      let d2: Double = 3

      let e1 = [3.14]
      let e2: [Double] = [3]

      let f1 = ["foo": 5]
      let f2: [String: Int?] = ["foo": nil]
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options,
    )
  }

  @Test func redundantTypePreservesLiteralRepresentableTypes() {
    let input = """
      let a: MyBoolRepresentable = true
      let b: MyStringRepresentable = "foo"
      let c: MyIntRepresentable = 1
      let d: MyDoubleRepresentable = 3.14
      let e: MyArrayRepresentable = ["bar"]
      let f: MyDictionaryRepresentable = ["baz": 1]
      """
    let options = FormatOptions(propertyTypes: .inferred)
    testFormatting(for: input, rule: .redundantType, options: options)
  }

  @Test func preservesTypeWithIfExpressionInSwift5_8() {
    let input = """
      let foo: Foo
      if condition {
          foo = Foo("foo")
      } else {
          foo = Foo("bar")
      }
      """
    let options = FormatOptions(propertyTypes: .inferred, swiftVersion: "5.8")
    testFormatting(for: input, rule: .redundantType, options: options)
  }

  @Test func preservesNonRedundantTypeWithIfExpression() {
    let input = """
      let foo: Foo = if condition {
          Foo("foo")
      } else {
          FooSubclass("bar")
      }
      """
    let options = FormatOptions(propertyTypes: .inferred, swiftVersion: "5.9")
    testFormatting(
      for: input, rule: .redundantType, options: options,
      exclude: [.wrapMultilineConditionalAssignment],
    )
  }

  @Test func redundantTypeWithIfExpression_inferred() {
    let input = """
      let foo: Foo = if condition {
          Foo("foo")
      } else {
          Foo("bar")
      }
      """
    let output = """
      let foo = if condition {
          Foo("foo")
      } else {
          Foo("bar")
      }
      """
    let options = FormatOptions(propertyTypes: .inferred, swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .redundantType, options: options,
      exclude: [.wrapMultilineConditionalAssignment],
    )
  }

  @Test func redundantTypeWithIfExpression_explicit() {
    let input = """
      let foo: Foo = if condition {
          Foo("foo")
      } else {
          Foo("bar")
      }
      """
    let output = """
      let foo: Foo = if condition {
          .init("foo")
      } else {
          .init("bar")
      }
      """
    let options = FormatOptions(propertyTypes: .explicit, swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .redundantType, options: options,
      exclude: [.wrapMultilineConditionalAssignment, .propertyTypes],
    )
  }

  @Test func redundantTypeWithNestedIfExpression_inferred() {
    let input = """
      let foo: Foo = if condition {
          switch condition {
          case true:
              if condition {
                  Foo("foo")
              } else {
                  Foo("bar")
              }

          case false:
              Foo("baaz")
          }
      } else {
          Foo("quux")
      }
      """
    let output = """
      let foo = if condition {
          switch condition {
          case true:
              if condition {
                  Foo("foo")
              } else {
                  Foo("bar")
              }

          case false:
              Foo("baaz")
          }
      } else {
          Foo("quux")
      }
      """
    let options = FormatOptions(propertyTypes: .inferred, swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .redundantType, options: options,
      exclude: [.wrapMultilineConditionalAssignment],
    )
  }

  @Test func redundantTypeWithNestedIfExpression_explicit() {
    let input = """
      let foo: Foo = if condition {
          switch condition {
          case true:
              if condition {
                  Foo("foo")
              } else {
                  Foo("bar")
              }

          case false:
              Foo("baaz")
          }
      } else {
          Foo("quux")
      }
      """
    let output = """
      let foo: Foo = if condition {
          switch condition {
          case true:
              if condition {
                  .init("foo")
              } else {
                  .init("bar")
              }

          case false:
              .init("baaz")
          }
      } else {
          .init("quux")
      }
      """
    let options = FormatOptions(propertyTypes: .explicit, swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .redundantType, options: options,
      exclude: [.wrapMultilineConditionalAssignment, .propertyTypes],
    )
  }

  @Test func redundantTypeWithLiteralsInIfExpression() {
    let input = """
      let foo: String = if condition {
          "foo"
      } else {
          "bar"
      }
      """
    let output = """
      let foo = if condition {
          "foo"
      } else {
          "bar"
      }
      """
    let options = FormatOptions(propertyTypes: .inferred, swiftVersion: "5.9")
    testFormatting(
      for: input, output, rule: .redundantType, options: options,
      exclude: [.wrapMultilineConditionalAssignment],
    )
  }

  // --redundanttype explicit

  @Test func varRedundantTypeRemovalExplicitType() {
    let input = """
      var view: UIView = UIView()
      """
    let output = """
      var view: UIView = .init()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func varRedundantTypeRemovalExplicitType2() {
    let input = """
      var view: UIView = UIView /* foo */()
      """
    let output = """
      var view: UIView = .init /* foo */()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.spaceAroundComments, .propertyTypes],
    )
  }

  @Test func letRedundantGenericTypeRemovalExplicitType() {
    let input = """
      let relay: BehaviourRelay<Int?> = BehaviourRelay<Int?>(value: nil)
      """
    let output = """
      let relay: BehaviourRelay<Int?> = .init(value: nil)
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func letRedundantGenericTypeRemovalExplicitTypeIfValueOnNextLine() {
    let input = """
      let relay: Foo<Int?> = Foo<Int?>
          .default
      """
    let output = """
      let relay: Foo<Int?> = 
          .default
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.trailingSpace, .propertyTypes],
    )
  }

  @Test func varNonRedundantTypeDoesNothingExplicitType() {
    let input = """
      var view: UIView = UINavigationBar()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(for: input, rule: .redundantType, options: options)
  }

  @Test func letRedundantTypeRemovalExplicitType() {
    let input = """
      let view: UIView = UIView()
      """
    let output = """
      let view: UIView = .init()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeRemovedIfValueOnNextLineExplicitType() {
    let input = """
      let view: UIView
          = UIView()
      """
    let output = """
      let view: UIView
          = .init()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeRemovedIfValueOnNextLine2ExplicitType() {
    let input = """
      let view: UIView =
          UIView()
      """
    let output = """
      let view: UIView =
          .init()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeRemovalWithCommentExplicitType() {
    let input = """
      var view: UIView /* view */ = UIView()
      """
    let output = """
      var view: UIView /* view */ = .init()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeRemovalWithComment2ExplicitType() {
    let input = """
      var view: UIView = /* view */ UIView()
      """
    let output = """
      var view: UIView = /* view */ .init()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeRemovalWithStaticMember() {
    let input = """
      let session: URLSession = URLSession.default

      init(foo: Foo, bar: Bar) {
          self.foo = foo
          self.bar = bar
      }
      """
    let output = """
      let session: URLSession = .default

      init(foo: Foo, bar: Bar) {
          self.foo = foo
          self.bar = bar
      }
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeRemovalWithStaticFunc() {
    let input = """
      let session: URLSession = URLSession.default()

      init(foo: Foo, bar: Bar) {
          self.foo = foo
          self.bar = bar
      }
      """
    let output = """
      let session: URLSession = .default()

      init(foo: Foo, bar: Bar) {
          self.foo = foo
          self.bar = bar
      }
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeDoesNothingWithChainedMember() {
    let input = """
      let session: URLSession = URLSession.default.makeCopy()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input,
      rule: .redundantType,
      options: options,
      exclude: [.propertyTypes],
    )
  }

  @Test func redundantRedundantChainedMemberTypeRemovedOnSwift5_4() {
    let input = """
      let session: URLSession = URLSession.default.makeCopy()
      """
    let output = """
      let session: URLSession = .default.makeCopy()
      """
    let options = FormatOptions(propertyTypes: .explicit, swiftVersion: "5.4")
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeDoesNothingWithChainedMember2() {
    let input = """
      let color: UIColor = UIColor.red.withAlphaComponent(0.5)
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input,
      rule: .redundantType,
      options: options,
      exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeDoesNothingWithChainedMember3() {
    let input = """
      let url: URL = URL(fileURLWithPath: #file).deletingLastPathComponent()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input,
      rule: .redundantType,
      options: options,
      exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeRemovedWithChainedMemberOnSwift5_4() {
    let input = """
      let url: URL = URL(fileURLWithPath: #file).deletingLastPathComponent()
      """
    let output = """
      let url: URL = .init(fileURLWithPath: #file).deletingLastPathComponent()
      """
    let options = FormatOptions(propertyTypes: .explicit, swiftVersion: "5.4")
    testFormatting(
      for: input, output, rule: .redundantType, options: options, exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeDoesNothingIfLet() {
    let input = """
      if let foo: Foo = Foo() {}
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input,
      rule: .redundantType,
      options: options,
      exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeDoesNothingGuardLet() {
    let input = """
      guard let foo: Foo = Foo() else {}
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input,
      rule: .redundantType,
      options: options,
      exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeDoesNothingIfLetAfterComma() {
    let input = """
      if check == true, let foo: Foo = Foo() {}
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input,
      rule: .redundantType,
      options: options,
      exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeWorksAfterIf() {
    let input = """
      if foo {}
      let foo: Foo = Foo()
      """
    let output = """
      if foo {}
      let foo: Foo = .init()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeIfVoid() {
    let input = """
      let foo: [Void] = [Void]()
      """
    let output = """
      let foo: [Void] = .init()
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func redundantTypeWithIntegerLiteralNotMangled() {
    let input = """
      let foo: Int = 1.toFoo
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, rule: .redundantType,
      options: options,
    )
  }

  @Test func redundantTypeWithFloatLiteralNotMangled() {
    let input = """
      let foo: Double = 1.0.toFoo
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, rule: .redundantType,
      options: options,
    )
  }

  @Test func redundantTypeWithArrayLiteralNotMangled() {
    let input = """
      let foo: [Int] = [1].toFoo
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, rule: .redundantType,
      options: options,
    )
  }

  @Test func redundantTypeWithBoolLiteralNotMangled() {
    let input = """
      let foo: Bool = false.toFoo
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(
      for: input, rule: .redundantType,
      options: options,
    )
  }

  @Test func redundantTypeInModelClassNotStripped() {
    // See: https://github.com/nicklockwood/SwiftFormat/issues/1649
    let input = """
      @Model
      class FooBar {
          var created: Date = Date.now
      }
      """
    let options = FormatOptions(propertyTypes: .explicit)
    testFormatting(for: input, rule: .redundantType, options: options)
  }

  // --redundanttype infer-locals-only

  @Test func redundantTypeinferLocalsOnly() {
    let input = """
      let globalFoo: Foo = Foo()

      struct SomeType {
          let instanceFoo: Foo = Foo()

          func method() {
              let localFoo: Foo = Foo()
              let localString: String = "foo"
          }

          let instanceString: String = "foo"
      }

      let globalString: String = "foo"
      """

    let output = """
      let globalFoo: Foo = .init()

      struct SomeType {
          let instanceFoo: Foo = .init()

          func method() {
              let localFoo = Foo()
              let localString = "foo"
          }

          let instanceString: String = "foo"
      }

      let globalString: String = "foo"
      """

    let options = FormatOptions(propertyTypes: .inferLocalsOnly)
    testFormatting(
      for: input, output, rule: .redundantType,
      options: options, exclude: [.propertyTypes],
    )
  }

  @Test func classWithWhereNotMistakenForLocalScope() {
    let input = """
      final class Foo<Bar> where Bar: Equatable {
          var isFoo: Bool = false
          var fooName: String = "name"
      }
      """

    let options = FormatOptions(propertyTypes: .inferLocalsOnly)
    testFormatting(
      for: input, rule: .redundantType, options: options,
      exclude: [.simplifyGenericConstraints],
    )
  }
}
