// Fixture: CaseIterable usage patterns

// Should flag: CaseIterable with no .allCases reference
enum Status: CaseIterable {
  case active
  case inactive
  case pending
}

// Should NOT flag: CaseIterable with .allCases reference
enum Direction: CaseIterable {
  case north
  case south
  case east
  case west
}

let allDirections = Direction.allCases

// Should NOT flag: not CaseIterable
enum Color {
  case red
  case green
  case blue
}
