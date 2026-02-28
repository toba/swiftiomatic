import Foundation

extension FileHandle: @retroactive TextOutputStream {
    func write(_ string: String) {
        let data = Data(string.utf8)
        write(data)
    }
}
