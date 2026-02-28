import Testing

@testable import Swiftiomatic

@Suite struct InitCoderUnavailableTests {
  @Test func initCoderUnavailableEmptyFunction() {
    let input = """
      struct A: UIView {
          required init?(coder aDecoder: NSCoder) {}
      }
      """
    let output = """
      struct A: UIView {
          @available(*, unavailable)
          required init?(coder aDecoder: NSCoder) {}
      }
      """
    testFormatting(
      for: input, output, rule: .initCoderUnavailable,
      exclude: [.unusedArguments])
  }

  @Test func initCoderUnavailableFatalErrorNilDisabled() {
    let input = """
      extension Module {
          final class A: UIView {
              required init?(coder _: NSCoder) {
                  fatalError("init(coder:) has not been implemented")
              }
          }
      }
      """
    let output = """
      extension Module {
          final class A: UIView {
              @available(*, unavailable)
              required init?(coder _: NSCoder) {
                  fatalError("init(coder:) has not been implemented")
              }
          }
      }
      """
    let options = FormatOptions(initCoderNil: false)
    testFormatting(for: input, output, rule: .initCoderUnavailable, options: options)
  }

  @Test func initCoderUnavailableFatalErrorNilEnabled() {
    let input = """
      extension Module {
          final class A: UIView {
              required init?(coder _: NSCoder) {
                  fatalError("init(coder:) has not been implemented")
              }
          }
      }
      """
    let output = """
      extension Module {
          final class A: UIView {
              @available(*, unavailable)
              required init?(coder _: NSCoder) {
                  nil
              }
          }
      }
      """
    let options = FormatOptions(initCoderNil: true)
    testFormatting(for: input, output, rule: .initCoderUnavailable, options: options)
  }

  @Test func initCoderUnavailableAlreadyPresent() {
    let input = """
      extension Module {
          final class A: UIView {
              @available(*, unavailable)
              required init?(coder _: NSCoder) {
                  fatalError()
              }
          }
      }
      """
    testFormatting(for: input, rule: .initCoderUnavailable)
  }

  @Test func initCoderUnavailableImplemented() {
    let input = """
      extension Module {
          final class A: UIView {
              required init?(coder aCoder: NSCoder) {
                  aCoder.doSomething()
              }
          }
      }
      """
    testFormatting(for: input, rule: .initCoderUnavailable)
  }

  @Test func publicInitCoderUnavailable() {
    let input = """
      public class Foo: UIView {
          public required init?(coder _: NSCoder) {
              fatalError("init(coder:) has not been implemented")
          }
      }
      """
    let output = """
      public class Foo: UIView {
          @available(*, unavailable)
          public required init?(coder _: NSCoder) {
              fatalError("init(coder:) has not been implemented")
          }
      }
      """
    testFormatting(for: input, output, rule: .initCoderUnavailable)
  }

  @Test func publicInitCoderUnavailable2() {
    let input = """
      public class Foo: UIView {
          required public init?(coder _: NSCoder) {
              fatalError("init(coder:) has not been implemented")
          }
      }
      """
    let output = """
      public class Foo: UIView {
          @available(*, unavailable)
          required public init?(coder _: NSCoder) {
              nil
          }
      }
      """
    let options = FormatOptions(initCoderNil: true)
    testFormatting(
      for: input, output, rule: .initCoderUnavailable,
      options: options, exclude: [.modifierOrder])
  }
}
