import Testing

/// Layout of the module selector `::` operator.
///
/// The operator binds a module name to the declaration that follows it. It carries no space on
/// either side, and the printer must never break a line at it.
@Suite
struct ModuleSelectorTests: LayoutTesting {
  @Test func moduleSelectorInExpression() {
    let input =
      """
      let x = Foundation::Data
      let y = Foundation::Data()
      let z = MyModule::value.property
      """

    let expected =
      """
      let x = Foundation::Data
      let y = Foundation::Data()
      let z = MyModule::value.property

      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  @Test func moduleSelectorOnKeywordName() {
    let input =
      """
      let x = MyModule::default
      let y = MyModule::`init`
      """

    let expected =
      """
      let x = MyModule::default
      let y = MyModule::`init`

      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  @Test func moduleSelectorOnKeywordCall() {
    // swift-syntax parses `as` and `is` after a selector as a declaration reference. The printer
    // keeps the call on one line and adds no space.
    let input =
      """
      func use(_ x: Int) {
        MyModule::as(x)
        MyModule::is(x)
      }
      """

    let expected =
      """
      func use(_ x: Int) {
        MyModule::as(x)
        MyModule::is(x)
      }

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func moduleSelectorInTypePosition() {
    let input =
      """
      let x: Foundation::Data = value
      func f(_ p: MyModule::Thing) -> MyModule::Result {}
      """

    let expected =
      """
      let x: Foundation::Data = value
      func f(_ p: MyModule::Thing) -> MyModule::Result {}

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func moduleSelectorInGenericArguments() {
    let input =
      """
      let x: MyModule::Box<Other::Item> = value
      let y = MyModule::Box<Other::Item>()
      """

    let expected =
      """
      let x: MyModule::Box<Other::Item> = value
      let y = MyModule::Box<Other::Item>()

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func moduleSelectorStaysOnOneLineWhenTheCallWraps() {
    let input =
      """
      let value = MyModule::functionWithALongName(firstArgument, secondArgument)
      """

    // The selector holds the module name and the function name together. The printer breaks at
    // the assignment and at the argument list instead. A plain identifier of the same length
    // wraps the same way, so the selector costs no extra break.
    let expected =
      """
      let value =
        MyModule::functionWithALongName(
          firstArgument, secondArgument)

      """

    assertLayout(input: input, expected: expected, linelength: 40)
  }

  @Test func moduleSelectorStaysOnOneLineWhenTheLineOverflows() {
    let input =
      """
      let value = MyModule::someLongMemberName
      """

    // No break fits inside the selector, so the line runs past the limit rather than splitting
    // `MyModule` from `someLongMemberName`.
    let expected =
      """
      let value =
        MyModule::someLongMemberName

      """

    assertLayout(input: input, expected: expected, linelength: 20)
  }

  @Test func moduleSelectorHoldsTheFirstLinkOfAMemberChain() {
    let input =
      """
      let value = MyModule::first.second.third.fourth.fifth
      """

    let expected =
      """
      let value =
        MyModule::first.second
        .third.fourth.fifth

      """

    assertLayout(input: input, expected: expected, linelength: 24)
  }
}
