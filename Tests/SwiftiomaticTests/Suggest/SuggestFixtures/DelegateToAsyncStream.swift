// Fixture: delegate to async stream patterns
import Foundation
import SwiftiomaticSyntax

// Should flag: all methods are delegate callbacks
protocol DownloadDelegate {
  func downloadDidStart(_ id: String)
  func downloadDidFinish(_ id: String, data: Data)
  func downloadDidFail(_ id: String, error: Error)
}

// Should NOT flag: has return types (not delegate-shaped)
protocol DataSource {
  func numberOfItems() -> Int
  func item(at index: Int) -> String
}

// Should NOT flag: only one method
protocol SingleCallback {
  func didComplete()
}

// Should flag: observer-style protocol
protocol StateObserver {
  func stateDidChange(_ state: String)
  func stateWillChange(_ state: String)
}

// Should NOT flag: mixed return types and void
protocol MixedProtocol {
  func willUpdate()
  func currentValue() -> Int
}
