// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt

import SourceKitC

/// Swift representation of sourcekitd_uid_t
struct UID: Hashable {
    let sourcekitdUID: sourcekitd_uid_t
    init(_ uid: sourcekitd_uid_t) {
        self.sourcekitdUID = uid
    }

    init(_ string: String) {
        self.init(sourcekitd_uid_get_from_cstr(string)!)
    }

    init<T>(_ rawRepresentable: T) where T: RawRepresentable, T.RawValue == String {
        self.init(rawRepresentable.rawValue)
    }

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
