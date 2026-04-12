// Fixture: performance anti-pattern patterns

import Foundation
import SwiftiomaticSyntax

// Should flag: withLock containing await
struct SafeState {
  let mutex = NSLock()

  func unsafeAsync() {
    mutex.withLock {
      // await inside lock
    }
  }
}

// Should flag: chained map/filter/compactMap without .lazy
let results = [1, 2, 3]
  .map { $0 * 2 }
  .filter { $0 > 2 }
  .compactMap { Optional($0) }

// Should NOT flag: uses .lazy
let lazyResults = [1, 2, 3].lazy
  .map { $0 * 2 }
  .filter { $0 > 2 }
  .compactMap { Optional($0) }

// Should flag: @TaskLocal for business-logic state
enum TaskLocals {
  @TaskLocal static var currentUser: String?

  // Should NOT flag: @TaskLocal for diagnostics
  @TaskLocal static var requestID: String?
  @TaskLocal static var traceID: String?
}

// Should flag: public generic function without @inlinable
public func transform<T>(_ value: T) -> T { value }

// Should NOT flag: has @inlinable
@inlinable
public func inlinableTransform<T>(_ value: T) -> T { value }

// Should flag: collection parameter that could be Span
func process(items: [Int]) {}
func processSlice(data: ArraySlice<UInt8>) {}

// Should NOT flag: inout parameter
func mutate(items: inout [Int]) {}
