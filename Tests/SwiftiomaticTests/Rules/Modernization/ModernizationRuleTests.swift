import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

// MARK: - ConcurrencyModernizationRule

@Suite(.rulesRegistered)
struct ConcurrencyModernizationRuleTests {
  @Test func noViolationForTaskGroup() async {
    await assertNoViolation(
      ConcurrencyModernizationRule.self,
      "await withTaskGroup(of: Void.self) { _ in }")
  }

  @Test func detectsDispatchQueue() async {
    await assertViolates(
      ConcurrencyModernizationRule.self,
      "DispatchQueue.main.async { update() }")
  }

  @Test func detectsCompletionHandler() async {
    await assertViolates(
      ConcurrencyModernizationRule.self,
      "func fetch(completion: @escaping (Result<Data, Error>) -> Void) {}")
  }
}

// MARK: - AsyncStreamSafetyRule

@Suite(.rulesRegistered)
struct AsyncStreamSafetyRuleTests {
  @Test func noViolationForCompleteStream() async {
    await assertNoViolation(
      AsyncStreamSafetyRule.self,
      """
      let stream = AsyncStream<Int> { continuation in
          continuation.onTermination = { _ in cleanup() }
          Task {
              for i in 0..<10 {
                  continuation.yield(i)
              }
              continuation.finish()
          }
      }
      """)
  }

  @Test func detectsMissingFinish() async {
    await assertViolates(
      AsyncStreamSafetyRule.self,
      """
      let stream = AsyncStream<Int> { continuation in
          continuation.onTermination = { _ in cleanup() }
          Task {
              for i in 0..<10 {
                  continuation.yield(i)
              }
          }
      }
      """)
  }

  @Test func detectsMissingOnTermination() async {
    await assertViolates(
      AsyncStreamSafetyRule.self,
      """
      let stream = AsyncThrowingStream<Data, Error> { continuation in
          continuation.finish()
      }
      """)
  }

  @Test func detectsBothMissing() async {
    await assertViolates(
      AsyncStreamSafetyRule.self,
      """
      let stream = AsyncStream<Int> { continuation in
          continuation.yield(42)
      }
      """)
  }
}

// MARK: - DelegateToAsyncStreamRule

@Suite(.rulesRegistered)
struct DelegateToAsyncStreamRuleTests {
  @Test func noViolationForDataSource() async {
    await assertNoViolation(
      DelegateToAsyncStreamRule.self,
      """
      protocol DataSource {
          func numberOfItems() -> Int
          func item(at index: Int) -> Item
      }
      """)
  }

  @Test func detectsDelegatePattern() async {
    await assertViolates(
      DelegateToAsyncStreamRule.self,
      """
      protocol DownloadDelegate {
          func downloadDidStart(_ download: Download)
          func downloadDidFinish(_ download: Download, data: Data)
          func downloadDidFail(_ download: Download, error: Error)
      }
      """)
  }
}

// MARK: - FileMacroRule

@Suite(.rulesRegistered)
struct FileMacroRuleTests {
  @Test func noViolationForFileMacro() async {
    await assertNoViolation(
      FileMacroRule.self,
      "func foo(file: StaticString = #file) {}")
  }

  // #fileID detection requires specific parser handling
}

// MARK: - FireAndForgetTaskRule

@Suite(.rulesRegistered)
struct FireAndForgetTaskRuleTests {
  @Test func noViolationForAssignedTask() async {
    await assertNoViolation(FireAndForgetTaskRule.self, "let task = Task { await work() }")
  }

  @Test func detectsFireAndForgetInDeinit() async {
    await assertViolates(
      FireAndForgetTaskRule.self,
      """
      class Foo {
          deinit {
              Task { await cleanup() }
          }
      }
      """)
  }
}

// MARK: - ApplicationMainRule

@Suite(.rulesRegistered)
struct ApplicationMainRuleTests {
  @Test func noViolationForMainAttribute() async {
    await assertNoViolation(
      ApplicationMainRule.self,
      """
      @main
      class AppDelegate: UIResponder, UIApplicationDelegate {}
      """)
  }

  @Test func detectsUIApplicationMain() async {
    await assertViolates(
      ApplicationMainRule.self,
      """
      @UIApplicationMain
      class AppDelegate: UIResponder, UIApplicationDelegate {}
      """)
  }
}

// MARK: - PreferFinalClassesRule

@Suite(.rulesRegistered)
struct PreferFinalClassesRuleTests {
  @Test func noViolationForFinalClass() async {
    await assertNoViolation(PreferFinalClassesRule.self, "final class Foo {}")
  }

  @Test func noViolationForOpenClass() async {
    await assertNoViolation(PreferFinalClassesRule.self, "open class Foo {}")
  }

  @Test func detectsNonFinalClass() async {
    await assertViolates(PreferFinalClassesRule.self, "class Foo {}")
  }
}

// MARK: - URLMacroRule

@Suite(.rulesRegistered)
struct URLMacroRuleTests {
  @Test func noViolationForVariableURL() async {
    await assertNoViolation(URLMacroRule.self, "let url = URL(string: variable)")
  }

  @Test func detectsForceUnwrappedURL() async {
    await assertViolates(
      URLMacroRule.self,
      #"let url = URL(string: "https://example.com")!"#)
  }
}

// MARK: - EnvironmentEntryRule

@Suite(.rulesRegistered)
struct EnvironmentEntryRuleTests {
  @Test func noViolationForEntry() async {
    await assertNoViolation(
      EnvironmentEntryRule.self,
      """
      extension EnvironmentValues {
          @Entry var screenName: String = "default"
      }
      """)
  }

  @Test func detectsEnvironmentKey() async {
    await assertViolates(
      EnvironmentEntryRule.self,
      """
      struct ScreenNameKey: EnvironmentKey {
          static var defaultValue: String { "default" }
      }
      """)
  }
}
