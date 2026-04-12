// Fixture: naming heuristics

import Foundation
import SwiftiomaticSyntax

// Should flag: Bool not reading as assertion
var enabled: Bool = true

// Should NOT flag: reads as assertion
var isEnabled: Bool = true
var hasError: Bool = false
var canEdit: Bool = true

// Should flag: factory method with create- prefix
struct Widget {
  static func createWidget() -> Widget { Widget() }
  static func newInstance() -> Widget { Widget() }
}

// Should NOT flag: uses make- prefix
struct GoodWidget {
  static func makeWidget() -> GoodWidget { GoodWidget() }
}

// Should flag: protocol with -able but conformer performs action
protocol Providable {
  func provideData() -> Data
}

// Should flag: mutating method with -ed suffix
extension Array {
  mutating func sorted() {}
}

// Should NOT flag: non-mutating with -ed suffix (correct convention)
extension Array {
  func reversed() -> [Element] { [] }
}

typealias Data = Foundation.Data
