// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt
// bridge() convenience wrappers for Foundation types.

import Foundation

extension Array {
    func bridge() -> NSArray {
        self as NSArray
    }
}

extension CharacterSet {
    func bridge() -> NSCharacterSet {
        self as NSCharacterSet
    }
}

extension Dictionary {
    func bridge() -> NSDictionary {
        self as NSDictionary
    }
}

extension NSString {
    func bridge() -> String {
        self as String
    }
}

extension String {
    func bridge() -> NSString {
        self as NSString
    }
}
