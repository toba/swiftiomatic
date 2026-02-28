protocol UIDRepresentable {
    var uid: UID { get }
}

extension UID: UIDRepresentable {
    var uid: UID { self }
}

extension String: UIDRepresentable {
    var uid: UID { UID(self) }
}
