import SwiftiomaticSyntax

extension Duration {
  /// Convert to a `TimeInterval` (seconds as `Double`) by combining seconds and attoseconds
  var timeInterval: Double {
    let (seconds, attoseconds) = components
    return Double(seconds) + Double(attoseconds) * 1e-18
  }
}
