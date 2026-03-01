import Foundation

protocol EnumAssociable {}

extension EnumAssociable {
    private var _associatedValue: Any? {
        let mirror = Mirror(reflecting: self)
        precondition(
            mirror.displayStyle == Mirror.DisplayStyle.enum,
            "Can only be apply to an Enum",
        )
        let optionalValue = mirror.children.first?.value
        if let value = optionalValue {
            let description = "\(value)"
            precondition(
                !description.contains("->") && !description.contains("(Function)"),
                "Doesn't work when associated value is a closure",
            )
        }
        return optionalValue
    }

    func associatedValue<T: _Optional>() -> T {
        guard let value = _associatedValue else {
            return T._none
        }
        guard let typed = value as? T else {
            preconditionFailure(
                "Associated value type mismatch: expected \(T.self), got \(type(of: value))",
            )
        }
        return typed
    }

    func associatedValue<T>() -> T {
        guard let typed = _associatedValue as? T else {
            preconditionFailure(
                "Associated value type mismatch: expected \(T.self), got \(type(of: _associatedValue as Any))",
            )
        }
        return typed
    }
}

protocol _Optional {
    static var _none: Self { get }
}

extension Optional: _Optional {
    static var _none: Optional {
        none
    }
}
