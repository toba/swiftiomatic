/// A generic LIFO stack where only the last inserted element can be accessed or removed
struct Stack<Element> {
  private var elements = [Element]()

  /// Creates an empty `Stack`.
  init() { /* Publish no-op initializer */  }

  /// The number of elements in this stack.
  var count: Int {
    elements.count
  }

  /// Pushes an element onto the top of the stack
  ///
  /// - Parameters:
  ///   - element: The element to push.
  mutating func push(_ element: Element) {
    elements.append(element)
  }

  /// Removes and returns the top element
  ///
  /// - Returns: The top element, or `nil` if the stack is empty.
  @discardableResult
  mutating func pop() -> Element? {
    elements.popLast()
  }

  /// Returns the top element without removing it
  func peek() -> Element? {
    elements.last
  }

  /// Checks whether any element satisfies the given predicate
  ///
  /// - Parameters:
  ///   - predicate: A closure that takes an element and returns whether it matches.
  /// - Returns: `true` if an element satisfying `predicate` exists.
  func contains(where predicate: (Element) -> Bool) -> Bool {
    elements.contains(where: predicate)
  }

  /// Mutates the top element in place
  ///
  /// Does nothing if the stack is empty.
  ///
  /// - Parameters:
  ///   - modifier: A closure applied to the top element as an `inout` reference.
  mutating func modifyLast(using modifier: (inout Element) -> Void) {
    if elements.isNotEmpty {
      modifier(&elements[count - 1])
    }
  }
}

extension Stack: Collection {
  var startIndex: Int {
    elements.startIndex
  }

  var endIndex: Int {
    elements.endIndex
  }

  subscript(position: Int) -> Element {
    elements[position]
  }

  func index(after index: Int) -> Int {
    elements.index(after: index)
  }
}

extension Stack: CustomDebugStringConvertible where Element: CustomDebugStringConvertible {
  var debugDescription: String {
    let intermediateElements = count > 1 ? elements[1..<count - 1] : []
    return """
      Stack with \(count) elements:
          first: \(elements.first?.debugDescription ?? "")
          intermediate: \(intermediateElements.map(\.debugDescription).joined(separator: ", "))
          last: \(peek()?.debugDescription ?? "")
      """
  }
}
