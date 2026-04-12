import SwiftiomaticSyntax

/// A type that can provide a ``UID`` for use as a sourcekitd dictionary key
protocol UIDRepresentable {
  /// The ``UID`` representation of this value
  var uid: UID { get }
}

extension UID: UIDRepresentable {
  var uid: UID { self }
}

extension String: UIDRepresentable {
  var uid: UID { UID(self) }
}
