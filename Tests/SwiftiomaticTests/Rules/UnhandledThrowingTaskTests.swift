@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UnhandledThrowingTaskTests: RuleTesting {
  @Test func taskWithUnhandledTry() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      1️⃣Task {
        try await myThrowingFunction()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "errors thrown inside this Task are not handled — use `try?`/`try!`, or wrap in do/catch"),
      ]
    )
  }

  @Test func taskWithUnhandledThrow() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      1️⃣Task {
        throw FooError.bar
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "errors thrown inside this Task are not handled — use `try?`/`try!`, or wrap in do/catch"),
      ]
    )
  }

  @Test func taskWithGenericWildcardErrorType() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      1️⃣Task<_, _> {
        throw FooError.bar
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "errors thrown inside this Task are not handled — use `try?`/`try!`, or wrap in do/catch"),
      ]
    )
  }

  @Test func taskInsideFunction() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      func doTask() {
        1️⃣Task {
          try await someThrowingFunction()
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "errors thrown inside this Task are not handled — use `try?`/`try!`, or wrap in do/catch"),
      ]
    )
  }

  @Test func taskWithExplicitErrorTypeDoesNotTrigger() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      Task<Void, Never> {
        try await myThrowingFunction()
      }
      """,
      findings: []
    )
  }

  @Test func taskWithTryQuestionDoesNotTrigger() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      Task {
        try? await myThrowingFunction()
      }
      Task {
        try! await myThrowingFunction()
      }
      """,
      findings: []
    )
  }

  @Test func taskWithDoCatchDoesNotTrigger() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      Task {
        do {
          try myThrowingFunction()
        } catch let e {
          print(e)
        }
      }
      """,
      findings: []
    )
  }

  @Test func taskAssignedToVariableDoesNotTrigger() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      let task = Task {
        try await myThrowingFunction()
      }
      """,
      findings: []
    )
  }

  @Test func taskValueAccessDoesNotTrigger() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      try await Task {
        try await myThrowingFunction()
      }.value
      """,
      findings: []
    )
  }

  @Test func taskResultAccessDoesNotTrigger() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      let result = await Task {
        throw CancellationError()
      }.result
      """,
      findings: []
    )
  }

  @Test func taskAsReturnValueDoesNotTrigger() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      func makeTask() -> Task<String, Error> {
        return Task {
          try await someThrowingFunction()
        }
      }
      """,
      findings: []
    )
  }

  @Test func taskAsImplicitReturnValueDoesNotTrigger() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      func makeTask() -> Task<String, Error> {
        Task {
          try await someThrowingFunction()
        }
      }
      """,
      findings: []
    )
  }

  @Test func resultInitializerHandlesErrors() {
    assertLint(
      UnhandledThrowingTask.self,
      """
      Task {
        return Result {
          try someThrowingFunc()
        }
      }
      """,
      findings: []
    )
  }
}
