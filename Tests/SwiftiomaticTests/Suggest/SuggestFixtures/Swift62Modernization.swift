// Fixture: Swift 6.2 modernization patterns

import Foundation

// Should flag: tuple as fixed-size buffer
let buffer: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0)

// Should NOT flag: heterogeneous tuple
let pair: (Int, String) = (1, "hello")

// Should NOT flag: tuple with fewer than 3 elements
let smallTuple: (Int, Int) = (1, 2)

// Should flag: static var without isolation
struct GlobalState {
  static var counter: Int = 0
  static var name: String = ""
}

// Should NOT flag: private static var
struct PrivateGlobalState {
  private static var counter: Int = 0
}

// Should flag: nonisolated in @MainActor type
@MainActor
class ViewModel {
  nonisolated func hashValue() -> Int { 0 }
}

// Should NOT flag: method without nonisolated
@MainActor
class GoodViewModel {
  func update() {}
}

// Should flag: context parameter threaded through all calls
func processRequest(context: RequestContext) {
  validate(context: context)
  transform(context: context)
}

func validate(context: RequestContext) {}
func transform(context: RequestContext) {}
struct RequestContext {}

// Should NOT flag: context param not threaded to all calls
func partialContext(context: RequestContext) {
  validate(context: context)
  doSomethingElse()
}

func doSomethingElse() {}

// Should flag: weak var never reassigned
class WeakVarHolder {
  weak var delegate: AnyObject?
  func doWork() { print(delegate as Any) }
}

// Should NOT flag: weak var that is reassigned
class WeakVarReassigned {
  weak var delegate: AnyObject?
  func reset() { delegate = nil }
}

// Should NOT flag: weak var with property observer
class WeakVarWithObserver {
  weak var delegate: AnyObject? {
    didSet { print("changed") }
  }
}

// Should flag: weak var in local scope, never reassigned
func localWeakVar() {
  weak var ref: AnyObject? = nil
  print(ref as Any)
}

// Should NOT flag: weak var in local scope, reassigned
func localWeakVarReassigned() {
  weak var ref: AnyObject? = nil
  ref = nil
  print(ref as Any)
}
