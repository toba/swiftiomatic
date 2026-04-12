import SwiftiomaticSyntax

extension String {
  /// Returns a copy with markdown code-formatting (backticks) stripped.
  var strippingMarkdown: String {
    var result = ""
    var startCount = 0
    var endCount = 0
    var escaped = false
    for c in self {
      if c == "`" {
        if escaped {
          endCount += 1
        } else {
          startCount += 1
        }
      } else {
        if escaped, endCount > 0 {
          if endCount != startCount {
            result += String(repeating: "`", count: endCount)
          } else {
            escaped = false
            startCount = 0
          }
          endCount = 0
        }
        if startCount > 0 {
          escaped = true
        }
        result.append(c)
      }
    }
    return result
  }
}

/// Legacy free-function wrapper -- prefer ``String/strippingMarkdown``
///
/// - Parameters:
///   - input: A string potentially containing markdown backtick formatting.
func stripMarkdown(_ input: String) -> String {
  input.strippingMarkdown
}
