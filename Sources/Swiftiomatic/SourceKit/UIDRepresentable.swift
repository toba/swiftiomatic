// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt

protocol UIDRepresentable {
    var uid: UID { get }
}

extension UID: UIDRepresentable {
    var uid: UID { self }
}

extension String: UIDRepresentable {
    var uid: UID { UID(self) }
}
