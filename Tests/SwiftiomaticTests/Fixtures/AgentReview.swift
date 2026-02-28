// Fixture: agent review candidates

import Foundation

// 8b: Fire-and-forget Task
func doWork() {
  Task {
    print("fire and forget")
  }
}

// Should NOT flag: assigned Task
func doWorkAssigned() {
  let task = Task {
    print("assigned")
  }
  _ = task
}

// 8d: Error enum without LocalizedError
enum AppError: Error {
  case somethingFailed
}

// Should NOT flag: has LocalizedError
enum GoodError: Error, LocalizedError {
  case oops
  var errorDescription: String? { "oops" }
}

// 8g: nonisolated(unsafe)
nonisolated(unsafe) let sharedRegex = /hello/
