import SourceKitC
import SwiftiomaticSyntax

/// Swift wrapper around `sourcekitd_uid_t`, the interned string identifier used by sourcekitd
struct UID: Hashable {
  /// The underlying C UID handle
  let sourcekitdUID: sourcekitd_uid_t

  /// Create a UID from a raw `sourcekitd_uid_t`
  ///
  /// - Parameters:
  ///   - uid: The C UID handle.
  init(_ uid: sourcekitd_uid_t) {
    sourcekitdUID = uid
  }

  /// Create a UID by interning a string
  ///
  /// - Parameters:
  ///   - string: The UID string (e.g. `source.request.editor.open`).
  init(_ string: String) {
    self.init(sourcekitd_uid_get_from_cstr(string)!)
  }

  /// Create a UID from a `RawRepresentable` whose raw value is a string
  ///
  /// - Parameters:
  ///   - rawRepresentable: The value whose `rawValue` to intern.
  init<T>(_ rawRepresentable: T) where T: RawRepresentable, T.RawValue == String {
    self.init(rawRepresentable.rawValue)
  }

  /// The string representation of this UID
  var string: String {
    String(cString: sourcekitd_uid_get_string_ptr(sourcekitdUID)!)
  }
}

extension UID: CustomStringConvertible {
  var description: String {
    string
  }
}

extension UID: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self.init(value)
  }
}
