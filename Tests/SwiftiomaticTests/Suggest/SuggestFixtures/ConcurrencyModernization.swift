// Fixture: concurrency modernization patterns

import Foundation

// Should flag: AsyncStream without continuation.finish()
func makeStream() -> AsyncStream<Int> {
  AsyncStream { continuation in
    continuation.yield(1)
    continuation.yield(2)
    // Missing continuation.finish()
    // Missing onTermination handler
  }
}

// Should NOT flag: has continuation.finish() and onTermination
func makeGoodStream() -> AsyncStream<Int> {
  AsyncStream { continuation in
    continuation.onTermination = { _ in }
    continuation.yield(1)
    continuation.finish()
  }
}

// Should flag: withCheckedContinuation wrapping single async call
func unnecessaryContinuation() async -> Int {
  await withCheckedContinuation { continuation in
    Task {
      let result = await fetchValue()
      continuation.resume(returning: result)
    }
  }
}

func fetchValue() -> Int { 42 }

// Should flag: OperationQueue usage
func legacyQueue() {
  let queue = OperationQueue()
  queue.addOperation {}
}

// Should flag: Timer.scheduledTimer
func legacyTimer() {
  Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in }
}

// Should flag: NotificationCenter.addObserver in async context
func asyncNotification() {
  NotificationCenter.default.addObserver(
    forName: .init("test"), object: nil, queue: nil
  ) { _ in }
}

// Should NOT flag: addObserver outside async context
func syncNotification() {
  NotificationCenter.default.addObserver(
    forName: .init("test"), object: nil, queue: nil
  ) { _ in }
}
