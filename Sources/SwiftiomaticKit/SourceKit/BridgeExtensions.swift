/// Convenience bridging extensions for crossing the Swift/Objective-C boundary.
///
/// These methods wrap the implicit `as` casts in named calls so that
/// bridging intent is explicit at the call site.

import Foundation
import SwiftiomaticSyntax

extension Array {
  /// Bridge this Swift `Array` to an ``NSArray``
  func bridge() -> NSArray {
    self as NSArray
  }
}

extension CharacterSet {
  /// Bridge this Swift `CharacterSet` to an ``NSCharacterSet``
  func bridge() -> NSCharacterSet {
    self as NSCharacterSet
  }
}

extension Dictionary {
  /// Bridge this Swift `Dictionary` to an ``NSDictionary``
  func bridge() -> NSDictionary {
    self as NSDictionary
  }
}

extension NSString {
  /// Bridge this `NSString` to a Swift ``String``
  func bridge() -> String {
    self as String
  }
}

extension String {
  /// Bridge this Swift `String` to an ``NSString``
  func bridge() -> NSString {
    self as NSString
  }
}
