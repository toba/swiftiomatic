import Foundation
import SourceKitC
import Synchronization

// MARK: - SourceKitValue

/// Type-safe representation of values returned by SourceKit responses
///
/// Replaces the legacy `SourceKitRepresentable` protocol (effectively `Any`)
/// with an explicit sum type that preserves type information through the
/// response-parsing pipeline.
enum SourceKitValue: Sendable, Equatable, Encodable, CustomStringConvertible {
    case string(String)
    case int64(Int64)
    case bool(Bool)
    case data(Data)
    case array([SourceKitValue])
    case dictionary([String: SourceKitValue])

    // MARK: Typed Accessors

    var stringValue: String? {
        if case let .string(v) = self { return v }
        return nil
    }

    var int64Value: Int64? {
        if case let .int64(v) = self { return v }
        return nil
    }

    var boolValue: Bool? {
        if case let .bool(v) = self { return v }
        return nil
    }

    var dataValue: Data? {
        if case let .data(v) = self { return v }
        return nil
    }

    var arrayValue: [SourceKitValue]? {
        if case let .array(v) = self { return v }
        return nil
    }

    var dictionaryValue: [String: SourceKitValue]? {
        if case let .dictionary(v) = self { return v }
        return nil
    }

    subscript(key: String) -> SourceKitValue? {
        dictionaryValue?[key]
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case let .string(v): try container.encode(v)
            case let .int64(v): try container.encode(v)
            case let .bool(v): try container.encode(v)
            case let .data(v): try container.encode(v)
            case let .array(v): try container.encode(v)
            case let .dictionary(v): try container.encode(v)
        }
    }

    var description: String {
        switch self {
            case let .string(v): return v
            case let .int64(v): return String(v)
            case let .bool(v): return String(v)
            case let .data(v): return "Data(\(v.count) bytes)"
            case let .array(v): return "\(v)"
            case let .dictionary(v): return "\(v)"
        }
    }
}

// MARK: - SourceKitValue from sourcekitd

extension SourceKitValue {
    // sm:disable:next cyclomatic_complexity
    fileprivate init?(sourcekitVariant sourcekitObject: sourcekitd_variant_t) {
        switch sourcekitd_variant_get_type(sourcekitObject) {
            case SOURCEKITD_VARIANT_TYPE_ARRAY:
                var array = [SourceKitValue]()
                _ = withUnsafeMutablePointer(to: &array) { arrayPtr in
                    sourcekitd_variant_array_apply_f(
                        sourcekitObject,
                        { index, value, context in
                            if let value = SourceKitValue(sourcekitVariant: value), let context {
                                let localArray = context.assumingMemoryBound(
                                    to: [SourceKitValue].self,
                                )
                                localArray.pointee.insert(value, at: Int(index))
                            }
                            return true
                        }, arrayPtr,
                    )
                }
                self = .array(array)
            case SOURCEKITD_VARIANT_TYPE_DICTIONARY:
                var dict = [String: SourceKitValue]()
                _ = withUnsafeMutablePointer(to: &dict) { dictPtr in
                    sourcekitd_variant_dictionary_apply_f(
                        sourcekitObject,
                        { key, value, context in
                            if let key = String(sourceKitUID: key!),
                               let value = SourceKitValue(sourcekitVariant: value),
                               let context
                            {
                                let localDict =
                                    context
                                        .assumingMemoryBound(to: [String: SourceKitValue].self)
                                localDict.pointee[key] = value
                            }
                            return true
                        }, dictPtr,
                    )
                }
                self = .dictionary(dict)
            case SOURCEKITD_VARIANT_TYPE_STRING:
                self = .string(
                    String(cString: sourcekitd_variant_string_get_ptr(sourcekitObject)!),
                )
            case SOURCEKITD_VARIANT_TYPE_INT64:
                self = .int64(sourcekitd_variant_int64_get_value(sourcekitObject))
            case SOURCEKITD_VARIANT_TYPE_BOOL:
                self = .bool(sourcekitd_variant_bool_get_value(sourcekitObject))
            case SOURCEKITD_VARIANT_TYPE_UID:
                guard let uid = sourcekitd_variant_uid_get_value(sourcekitObject),
                      let str = String(sourceKitUID: uid)
                else { return nil }
                self = .string(str)
            case SOURCEKITD_VARIANT_TYPE_NULL:
                return nil
            case SOURCEKITD_VARIANT_TYPE_DATA:
                guard let ptr = sourcekitd_variant_data_get_ptr(sourcekitObject) else { return nil }
                self = .data(
                    Data(bytes: ptr, count: sourcekitd_variant_data_get_size(sourcekitObject)),
                )
            default:
                fatalError("Unknown SourceKit variant type")
        }
    }
}

private let _ensureSourceKitInitialized: Void = {
    sourcekitd_initialize()
}()

private let _ensureSourceKitNotificationHandler: Void = {
    _ensureSourceKitInitialized
    sourcekitd_set_notification_handler { response in
        if !sourcekitd_response_is_error(response!) {
            fflush(stdout)
            fputs("swiftiomatic: connection to SourceKitService restored!\n", stderr)
            sourceKitRestored.withLock { $0 = true }
        }
        sourcekitd_response_dispose(response!)
    }
}()

/// Set to `true` by the notification handler when SourceKitService reconnects after a crash.
/// `send()` polls this with a short sleep on connection-interrupted errors.
private let sourceKitRestored = Mutex(false)

/// When true, `send()` throws immediately without calling `sourcekitd_initialize()`.
/// Set once during test setup to prevent the in-process sourcekitd from loading
/// background threads that SIGSEGV during process exit (apple/swift#55112).
private let _sourceKitDisabled = Mutex(false)

/// Prevent sourcekitd from being initialized for the lifetime of this process.
/// Call once during test setup. Not reversible.
public func disableSourceKitForTesting() {
    _sourceKitDisabled.withLock { $0 = true }
}

/// Whether sourcekitd has been disabled for testing.
/// Check this **before** constructing any `UID` or `SourceKitObject` values,
/// since those trigger `dlopen` of sourcekitdInProc.framework (which spawns
/// background threads that SIGSEGV on process exit — apple/swift#55112).
public var isSourceKitDisabled: Bool {
    _sourceKitDisabled.withLock { $0 }
}

/// Serializes sourcekitd requests to avoid SIGSEGV crashes under parallel load.
/// sourcekitd runs as a single XPC service process and is not resilient to
/// unbounded concurrent requests (especially index/cursorinfo).
private let sourceKitRequestGate = Mutex(())

/// Block until the SourceKitService restore notification fires, or 10 seconds elapse.
private func waitForSourceKitRestore() {
    sourceKitRestored.withLock { $0 = false }
    let deadline = ContinuousClock.now.advanced(by: .seconds(10))
    while ContinuousClock.now < deadline {
        if sourceKitRestored.withLock({ $0 }) { return }
        Thread.sleep(forTimeInterval: 0.05)
    }
}

extension String {
    fileprivate init?(sourceKitUID: sourcekitd_uid_t) {
        let bytes = sourcekitd_uid_get_string_ptr(sourceKitUID)
        self = String(cString: bytes!)
    }
}

/// A SourceKit request that can be sent synchronously to sourcekitd
enum Request {
    /// An `editor.open` request for the given ``File``
    case editorOpen(file: File)
    /// A `cursorinfo` request for an offset in the given file with compiler arguments
    case cursorInfo(file: String, offset: ByteCount, arguments: [String])
    /// A `cursorinfo` request for a USR in the given file with compiler arguments
    case cursorInfoUSR(
        file: String, usr: String, arguments: [String], cancelOnSubsequentRequest: Bool,
    )
    /// A custom request constructed from a ``SourceKitObject`` directly
    case customRequest(request: SourceKitObject)
    /// A request parsed from a YAML string representation
    case yamlRequest(yaml: String)
    /// An `indexsource` request for the given file with compiler arguments
    case index(file: String, arguments: [String])

    private var sourcekitObject: SourceKitObject {
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

    /// Build a reusable cursorinfo request object for the given file and arguments
    ///
    /// Returns `nil` when no file path is provided.
    ///
    /// - Parameters:
    ///   - filePath: The source file path, or `nil`.
    ///   - arguments: Compiler arguments for the request.
    static func cursorInfoRequest(filePath: String?, arguments: [String]) -> SourceKitObject? {
        if let path = filePath {
            return Request.cursorInfo(file: path, offset: 0, arguments: arguments).sourcekitObject
        }
        return nil
    }

    /// Send a cursorinfo request at a specific byte offset
    ///
    /// Returns `nil` when the offset is zero (no valid position).
    ///
    /// - Parameters:
    ///   - cursorInfoRequest: A pre-built cursorinfo ``SourceKitObject``.
    ///   - offset: The byte offset to query.
    static func send(cursorInfoRequest: SourceKitObject, atOffset offset: ByteCount)
        -> [String: SourceKitValue]?
    {
        if offset == 0 {
            return nil
        }
        cursorInfoRequest.updateValue(Int64(offset.value), forKey: SwiftDocKey.offset)
        return try? Request.customRequest(request: cursorInfoRequest).send()
    }

    /// Send the request synchronously and return the response dictionary
    ///
    /// Serializes through a global gate to prevent concurrent sourcekitd crashes.
    /// On connection-interrupted errors, waits up to 10 seconds for SourceKit to restore.
    func send() throws(Request.Error) -> [String: SourceKitValue] {
        if _sourceKitDisabled.withLock({ $0 }) {
            throw .failed("SourceKit is disabled for testing (apple/swift#55112)")
        }
        _ensureSourceKitNotificationHandler
        let result: Result<[String: SourceKitValue], Request.Error> = sourceKitRequestGate
            .withLock {
                _ in
                let response = sourcekitObject.sendSync()
                defer { sourcekitd_response_dispose(response!) }
                if sourcekitd_response_is_error(response!) {
                    return .failure(Request.Error(response: response!))
                }
                guard let value =
                    SourceKitValue(sourcekitVariant: sourcekitd_response_get_value(response!)),
                    let dict = value.dictionaryValue
                else {
                    return .failure(.failed("Response was not a dictionary"))
                }
                return .success(dict)
            }
        if case let .failure(error) = result, case .connectionInterrupted = error {
            waitForSourceKitRestore()
        }
        return try result.get()
    }

    /// An error returned by the sourcekitd service, mapped from `SOURCEKITD_ERROR_*` constants
    enum Error: Swift.Error, LocalizedError, CustomStringConvertible {
        case connectionInterrupted(String?)
        case invalid(String?)
        case failed(String?)
        case cancelled(String?)
        case unknown(String?)

        var description: String {
            message ?? "no description"
        }

        var errorDescription: String? {
            message
        }

        private var message: String? {
            switch self {
                case let .connectionInterrupted(string): string
                case let .invalid(string): string
                case let .failed(string): string
                case let .cancelled(string): string
                case let .unknown(string): string
            }
        }

        fileprivate init(response: sourcekitd_response_t) {
            let description =
                String(validatingCString: sourcekitd_response_error_get_description(response)!)
            switch sourcekitd_response_error_get_kind(response) {
                case SOURCEKITD_ERROR_CONNECTION_INTERRUPTED:
                    self =
                        .connectionInterrupted(description)
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
