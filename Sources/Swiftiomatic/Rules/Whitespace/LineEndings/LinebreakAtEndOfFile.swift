import Foundation

extension FormatRule {
  /// Always end file with a linebreak, to avoid incompatibility with certain unix tools:
  /// http://stackoverflow.com/questions/2287967/why-is-it-recommended-to-have-empty-line-in-the-end-of-file
  static let linebreakAtEndOfFile = FormatRule(
    help: "Add empty blank line at end of file.",
    sharedOptions: ["linebreaks"],
  ) { formatter in
    guard !formatter.options.fragment else { return }
    var wasLinebreak = true
    formatter.forEachToken(onlyWhereEnabled: false) { _, token in
      switch token {
      case .lineBreak:
        wasLinebreak = true
      case .space:
        break
      default:
        wasLinebreak = false
      }
    }
    if formatter.isEnabled, !wasLinebreak {
      formatter.insertLinebreak(at: formatter.tokens.count)
    }
  } examples: {
    """
    ```diff
      struct Foo {↩
          let bar: Bar↩
    - }
    + }↩
    +
    ```
    """
  }
}
