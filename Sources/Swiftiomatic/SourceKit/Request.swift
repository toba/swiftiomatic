// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt
// Pruned to cases actually used by Swiftiomatic.

import Dispatch
import Foundation
import SourceKitC

protocol SourceKitRepresentable {
    func isEqualTo(_ rhs: SourceKitRepresentable) -> Bool
}
extension Array: SourceKitRepresentable {}
extension Dictionary: SourceKitRepresentable {}
extension String: SourceKitRepresentable {}
extension Int64: SourceKitRepresentable {}
extension Bool: SourceKitRepresentable {}
extension Data: SourceKitRepresentable {}

extension SourceKitRepresentable {
    func isEqualTo(_ rhs: SourceKitRepresentable) -> Bool {
        switch self {
        case let lhs as [SourceKitRepresentable]:
            for (idx, value) in lhs.enumerated() {
                if let rhs = rhs as? [SourceKitRepresentable], rhs[idx].isEqualTo(value) {
                    continue
                }
                return false
            }
            return true
        case let lhs as [String: SourceKitRepresentable]:
            for (key, value) in lhs {
                if let rhs = rhs as? [String: SourceKitRepresentable],
                   let rhsValue = rhs[key], rhsValue.isEqualTo(value) {
                    continue
                }
                return false
            }
            return true
        case let lhs as String:
            return lhs == rhs as? String
        case let lhs as Int64:
            return lhs == rhs as? Int64
        case let lhs as Bool:
            return lhs == rhs as? Bool
        default:
            fatalError("Should never happen because we've checked all SourceKitRepresentable types")
        }
    }
}

// swiftlint:disable:next cyclomatic_complexity
private func fromSourceKit(_ sourcekitObject: sourcekitd_variant_t) -> SourceKitRepresentable? {
    switch sourcekitd_variant_get_type(sourcekitObject) {
    case SOURCEKITD_VARIANT_TYPE_ARRAY:
        var array = [SourceKitRepresentable]()
        _ = withUnsafeMutablePointer(to: &array) { arrayPtr in
            sourcekitd_variant_array_apply_f(sourcekitObject, { index, value, context in
                if let value = fromSourceKit(value), let context = context {
                    let localArray = context.assumingMemoryBound(to: [SourceKitRepresentable].self)
                    localArray.pointee.insert(value, at: Int(index))
                }
                return true
            }, arrayPtr)
        }
        return array
    case SOURCEKITD_VARIANT_TYPE_DICTIONARY:
        var dict = [String: SourceKitRepresentable]()
        _ = withUnsafeMutablePointer(to: &dict) { dictPtr in
            sourcekitd_variant_dictionary_apply_f(sourcekitObject, { key, value, context in
                if let key = String(sourceKitUID: key!), let value = fromSourceKit(value), let context = context {
                    let localDict = context.assumingMemoryBound(to: [String: SourceKitRepresentable].self)
                    localDict.pointee[key] = value
                }
                return true
            }, dictPtr)
        }
        return dict
    case SOURCEKITD_VARIANT_TYPE_STRING:
        return String(cString: sourcekitd_variant_string_get_ptr(sourcekitObject)!)
    case SOURCEKITD_VARIANT_TYPE_INT64:
        return sourcekitd_variant_int64_get_value(sourcekitObject)
    case SOURCEKITD_VARIANT_TYPE_BOOL:
        return sourcekitd_variant_bool_get_value(sourcekitObject)
    case SOURCEKITD_VARIANT_TYPE_UID:
        return String(sourceKitUID: sourcekitd_variant_uid_get_value(sourcekitObject)!)
    case SOURCEKITD_VARIANT_TYPE_NULL:
        return nil
    case SOURCEKITD_VARIANT_TYPE_DATA:
        return sourcekitd_variant_data_get_ptr(sourcekitObject).map { ptr in
            Data(bytes: ptr, count: sourcekitd_variant_data_get_size(sourcekitObject))
        }
    default:
        fatalError("Should never happen because we've checked all SourceKitRepresentable types")
    }
}

private let initializeSourceKit: Void = {
    sourcekitd_initialize()
}()
private let initializeSourceKitFailable: Void = {
    initializeSourceKit
    sourcekitd_set_notification_handler { response in
        if !sourcekitd_response_is_error(response!) {
            fflush(stdout)
            fputs("swiftiomatic: connection to SourceKitService restored!\n", stderr)
            sourceKitWaitingRestoredSemaphore.signal()
        }
        sourcekitd_response_dispose(response!)
    }
}()

nonisolated(unsafe) private var sourceKitWaitingRestoredSemaphore = DispatchSemaphore(value: 0)

private extension String {
    init?(sourceKitUID: sourcekitd_uid_t) {
        let bytes = sourcekitd_uid_get_string_ptr(sourceKitUID)
        self = String(cString: bytes!)
    }
}

/// Represents a SourceKit request.
enum Request {
    /// An `editor.open` request for the given File.
    case editorOpen(file: File)
    /// A `cursorinfo` request for an offset in the given file, using the `arguments` given.
    case cursorInfo(file: String, offset: ByteCount, arguments: [String])
    /// A `cursorinfo` request for a USR in the given file, using the `arguments` given.
    case cursorInfoUSR(file: String, usr: String, arguments: [String], cancelOnSubsequentRequest: Bool)
    /// A custom request by passing in the `SourceKitObject` directly.
    case customRequest(request: SourceKitObject)
    /// A request generated by sourcekit using the yaml representation.
    case yamlRequest(yaml: String)
    /// Index
    case index(file: String, arguments: [String])

    fileprivate var sourcekitObject: SourceKitObject {
        switch self {
        case let .editorOpen(file):
            if let path = file.path {
                return [
                    "key.request": UID("source.request.editor.open"),
                    "key.name": path,
                    "key.sourcefile": path,
                ]
            } else {
                return [
                    "key.request": UID("source.request.editor.open"),
                    "key.name": String(abs(file.contents.hash)),
                    "key.sourcetext": file.contents,
                ]
            }
        case let .cursorInfo(file, offset, arguments):
            return [
                "key.request": UID("source.request.cursorinfo"),
                "key.name": file,
                "key.sourcefile": file,
                "key.offset": Int64(offset.value),
                "key.compilerargs": arguments,
            ]
        case let .cursorInfoUSR(file, usr, arguments, cancelOnSubsequentRequest):
            return [
                "key.request": UID("source.request.cursorinfo"),
                "key.sourcefile": file,
                "key.usr": usr,
                "key.compilerargs": arguments,
                "key.cancel_on_subsequent_request": cancelOnSubsequentRequest ? 1 : 0,
            ]
        case let .customRequest(request):
            return request
        case let .yamlRequest(yaml):
            return SourceKitObject(yaml: yaml)
        case let .index(file, arguments):
            return [
                "key.request": UID("source.request.indexsource"),
                "key.sourcefile": file,
                "key.compilerargs": arguments,
            ]
        }
    }

    internal static func cursorInfoRequest(filePath: String?, arguments: [String]) -> SourceKitObject? {
        if let path = filePath {
            return Request.cursorInfo(file: path, offset: 0, arguments: arguments).sourcekitObject
        }
        return nil
    }

    internal static func send(cursorInfoRequest: SourceKitObject, atOffset offset: ByteCount) -> [String: SourceKitRepresentable]? {
        if offset == 0 {
            return nil
        }
        cursorInfoRequest.updateValue(Int64(offset.value), forKey: SwiftDocKey.offset)
        return try? Request.customRequest(request: cursorInfoRequest).send()
    }

    func asyncSend() async throws -> [String: SourceKitRepresentable] {
        initializeSourceKitFailable
        let response = try await sourcekitObject.sendAsync()
        defer { sourcekitd_response_dispose(response) }
        return fromSourceKit(sourcekitd_response_get_value(response)) as! [String: SourceKitRepresentable]
    }

    func send() throws -> [String: SourceKitRepresentable] {
        initializeSourceKitFailable
        let response = sourcekitObject.sendSync()
        defer { sourcekitd_response_dispose(response!) }
        if sourcekitd_response_is_error(response!) {
            let error = Request.Error(response: response!)
            if case .connectionInterrupted = error {
                _ = sourceKitWaitingRestoredSemaphore.wait(timeout: DispatchTime.now() + 10)
            }
            throw error
        }
        return fromSourceKit(sourcekitd_response_get_value(response!)) as! [String: SourceKitRepresentable]
    }

    /// A enum representation of SOURCEKITD_ERROR_*
    enum Error: Swift.Error, CustomStringConvertible {
        case connectionInterrupted(String?)
        case invalid(String?)
        case failed(String?)
        case cancelled(String?)
        case unknown(String?)

        var description: String {
            getDescription() ?? "no description"
        }

        private func getDescription() -> String? {
            switch self {
            case let .connectionInterrupted(string): return string
            case let .invalid(string): return string
            case let .failed(string): return string
            case let .cancelled(string): return string
            case let .unknown(string): return string
            }
        }

        fileprivate init(response: sourcekitd_response_t) {
            let description = String(validatingUTF8: sourcekitd_response_error_get_description(response)!)
            switch sourcekitd_response_error_get_kind(response) {
            case SOURCEKITD_ERROR_CONNECTION_INTERRUPTED: self = .connectionInterrupted(description)
            case SOURCEKITD_ERROR_REQUEST_INVALID: self = .invalid(description)
            case SOURCEKITD_ERROR_REQUEST_FAILED: self = .failed(description)
            case SOURCEKITD_ERROR_REQUEST_CANCELLED: self = .cancelled(description)
            default: self = .unknown(description)
            }
        }
    }
}

extension Request: CustomStringConvertible {
    var description: String { sourcekitObject.description }
}
