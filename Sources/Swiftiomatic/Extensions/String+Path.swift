import Foundation

func expandPath(_ path: String, in directory: String) -> URL {
    let expanded = (path as NSString).expandingTildeInPath
    if expanded.hasPrefix("/") {
        return URL(fileURLWithPath: expanded).standardized
    }
    return URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(path)
        .standardized
}
