// Fixture: naming heuristics

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
