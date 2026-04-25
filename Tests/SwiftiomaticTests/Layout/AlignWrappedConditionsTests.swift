import SwiftiomaticKit
import Testing

@Suite
struct AlignWrappedConditionsTests: LayoutTesting {
  private var config: Configuration {
    var c = Configuration.forTesting
    c[AlignWrappedConditions.self] = true
    return c
  }

  // MARK: - if

  @Test func ifAlignsTwoConditions() {
    assertLayout(
      input: """
        if let a = foo(), let b = bar() {
          a()
        }
        """,
      expected: """
        if let a = foo(),
           let b = bar()
        {
          a()
        }

        """,
      linelength: 30,
      configuration: config
    )
  }

  @Test func ifAlignsThreeConditions() {
    assertLayout(
      input: """
        if let a = foo(), let b = bar(), let c = baz() {
          a()
        }
        """,
      expected: """
        if let a = foo(),
           let b = bar(),
           let c = baz()
        {
          a()
        }

        """,
      linelength: 30,
      configuration: config
    )
  }

  @Test func ifNestedIndentation() {
    assertLayout(
      input: """
        func foo() {
          if let a = foo(), let b = bar() {
            a()
          }
        }
        """,
      expected: """
        func foo() {
          if let a = foo(),
             let b = bar()
          {
            a()
          }
        }

        """,
      linelength: 30,
      configuration: config
    )
  }

  @Test func ifSingleConditionUnchanged() {
    assertLayout(
      input: """
        if let x = foo() {
          a()
        }
        """,
      expected: """
        if let x = foo() {
          a()
        }

        """,
      linelength: 40,
      configuration: config
    )
  }

  @Test func ifFitsOnOneLine() {
    assertLayout(
      input: """
        if x, y {
          a()
        }
        """,
      expected: """
        if x, y {
          a()
        }

        """,
      linelength: 40,
      configuration: config
    )
  }

  // MARK: - guard

  @Test func guardAlignsTwoConditions() {
    assertLayout(
      input: """
        guard let a = foo(), let b = bar() else {
          return
        }
        """,
      expected: """
        guard let a = foo(),
              let b = bar()
        else {
          return
        }

        """,
      linelength: 30,
      configuration: config
    )
  }

  @Test func guardNestedIndentation() {
    assertLayout(
      input: """
        func foo() {
          guard let a = foo(), let b = bar() else {
            return
          }
        }
        """,
      expected: """
        func foo() {
          guard let a = foo(),
                let b = bar()
          else {
            return
          }
        }

        """,
      linelength: 35,
      configuration: config
    )
  }

  // MARK: - while

  @Test func whileAlignsTwoConditions() {
    assertLayout(
      input: """
        while let a = foo(), !done {
          process()
        }
        """,
      expected: """
        while let a = foo(),
              !done
        {
          process()
        }

        """,
      linelength: 25,
      configuration: config
    )
  }

  // MARK: - disabled (default)

  @Test func disabledUsesContinuationIndent() {
    var off = Configuration.forTesting
    off[AlignWrappedConditions.self] = false
    assertLayout(
      input: """
        if let a = foo(), let b = bar() {
          a()
        }
        """,
      expected: """
        if let a = foo(),
          let b = bar()
        {
          a()
        }

        """,
      linelength: 30,
      configuration: off
    )
  }
}
