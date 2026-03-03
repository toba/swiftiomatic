/// Runtime-loaded C function pointers for the sourcekitd in-process framework
///
/// All symbols are resolved lazily via ``DynamicLinkLibrary/load(symbol:)``
/// from the Xcode toolchain's `sourcekitdInProc.framework`.

import SourceKitC

/// The dynamically loaded sourcekitdInProc framework handle
private let library = toolchainLoader.load(
    path: "sourcekitdInProc.framework/Versions/A/sourcekitdInProc",
)

// sm:disable unused_declaration

let sourcekitd_initialize: @convention(c) () -> Void = library.load(
    symbol: "sourcekitd_initialize",
)
let sourcekitd_shutdown: @convention(c) () -> Void = library.load(
    symbol: "sourcekitd_shutdown",
)
let sourcekitd_set_interrupted_connection_handler:
    @convention(c) (@escaping sourcekitd_interrupted_connection_handler_t) -> Void = library.load(
        symbol: "sourcekitd_set_interrupted_connection_handler",
    )
let sourcekitd_uid_get_from_cstr: @convention(c) (UnsafePointer<CChar>) -> (sourcekitd_uid_t?) =
    library.load(
        symbol: "sourcekitd_uid_get_from_cstr",
    )
let sourcekitd_uid_get_from_buf: @convention(c) (UnsafePointer<CChar>, Int) -> (sourcekitd_uid_t?) =
    library.load(
        symbol: "sourcekitd_uid_get_from_buf",
    )
let sourcekitd_uid_get_length: @convention(c) (sourcekitd_uid_t) -> (Int) = library.load(
    symbol: "sourcekitd_uid_get_length",
)
let sourcekitd_uid_get_string_ptr: @convention(c) (sourcekitd_uid_t) -> (UnsafePointer<CChar>?) =
    library.load(
        symbol: "sourcekitd_uid_get_string_ptr",
    )
let sourcekitd_request_retain: @convention(c) (sourcekitd_object_t) -> (sourcekitd_object_t?) =
    library.load(
        symbol: "sourcekitd_request_retain",
    )
let sourcekitd_request_release: @convention(c) (sourcekitd_object_t) -> Void =
    library.load(symbol: "sourcekitd_request_release")
let sourcekitd_request_dictionary_create:
    @convention(c) (UnsafePointer<sourcekitd_uid_t?>?, UnsafePointer<sourcekitd_object_t?>?, Int)
    -> (
        sourcekitd_object_t?
    ) = library.load(symbol: "sourcekitd_request_dictionary_create")
let sourcekitd_request_dictionary_set_value:
    @convention(c) (sourcekitd_object_t, sourcekitd_uid_t, sourcekitd_object_t) -> Void =
    library.load(symbol: "sourcekitd_request_dictionary_set_value")
let sourcekitd_request_dictionary_set_string:
    @convention(c) (sourcekitd_object_t, sourcekitd_uid_t, UnsafePointer<CChar>) -> Void =
    library.load(symbol: "sourcekitd_request_dictionary_set_string")
let sourcekitd_request_dictionary_set_stringbuf:
    @convention(c) (sourcekitd_object_t, sourcekitd_uid_t, UnsafePointer<CChar>, Int) -> Void =
    library.load(symbol: "sourcekitd_request_dictionary_set_stringbuf")
let sourcekitd_request_dictionary_set_int64:
    @convention(c) (sourcekitd_object_t, sourcekitd_uid_t, Int64) -> Void = library.load(
        symbol: "sourcekitd_request_dictionary_set_int64",
    )
let sourcekitd_request_dictionary_set_uid:
    @convention(c) (sourcekitd_object_t, sourcekitd_uid_t, sourcekitd_uid_t) -> Void = library.load(
        symbol: "sourcekitd_request_dictionary_set_uid",
    )
let sourcekitd_request_array_create:
    @convention(c) (UnsafePointer<sourcekitd_object_t?>?, Int) -> (sourcekitd_object_t?) =
    library.load(symbol: "sourcekitd_request_array_create")
let sourcekitd_request_array_set_value:
    @convention(c) (sourcekitd_object_t, Int, sourcekitd_object_t) -> Void = library.load(
        symbol: "sourcekitd_request_array_set_value",
    )
let sourcekitd_request_array_set_string:
    @convention(c) (sourcekitd_object_t, Int, UnsafePointer<CChar>) -> Void = library.load(
        symbol: "sourcekitd_request_array_set_string",
    )
let sourcekitd_request_array_set_stringbuf:
    @convention(c) (sourcekitd_object_t, Int, UnsafePointer<CChar>, Int) -> Void = library.load(
        symbol: "sourcekitd_request_array_set_stringbuf",
    )
let sourcekitd_request_array_set_int64: @convention(c) (sourcekitd_object_t, Int, Int64) -> Void =
    library.load(
        symbol: "sourcekitd_request_array_set_int64",
    )
let sourcekitd_request_array_set_uid:
    @convention(c) (sourcekitd_object_t, Int, sourcekitd_uid_t) -> Void = library.load(
        symbol: "sourcekitd_request_array_set_uid",
    )
let sourcekitd_request_int64_create: @convention(c) (Int64) -> (sourcekitd_object_t?) =
    library.load(symbol: "sourcekitd_request_int64_create")
let sourcekitd_request_string_create:
    @convention(c) (UnsafePointer<CChar>) -> (sourcekitd_object_t?) = library.load(
        symbol: "sourcekitd_request_string_create",
    )
let sourcekitd_request_uid_create: @convention(c) (sourcekitd_uid_t) -> (sourcekitd_object_t?) =
    library.load(
        symbol: "sourcekitd_request_uid_create",
    )
let sourcekitd_request_create_from_yaml:
    @convention(c) (UnsafePointer<CChar>, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) -> (
        sourcekitd_object_t?
    ) = library.load(symbol: "sourcekitd_request_create_from_yaml")
let sourcekitd_request_description_dump: @convention(c) (sourcekitd_object_t) -> Void =
    library.load(symbol: "sourcekitd_request_description_dump")
let sourcekitd_request_description_copy:
    @convention(c) (sourcekitd_object_t) -> (UnsafeMutablePointer<CChar>?) = library.load(
        symbol: "sourcekitd_request_description_copy",
    )
let sourcekitd_response_dispose: @convention(c) (sourcekitd_response_t) -> Void =
    library.load(symbol: "sourcekitd_response_dispose")
let sourcekitd_response_is_error: @convention(c) (sourcekitd_response_t) -> (Bool) =
    library.load(symbol: "sourcekitd_response_is_error")
let sourcekitd_response_error_get_kind:
    @convention(c) (sourcekitd_response_t) -> (sourcekitd_error_t) = library.load(
        symbol: "sourcekitd_response_error_get_kind",
    )
let sourcekitd_response_error_get_description:
    @convention(c) (sourcekitd_response_t) -> (UnsafePointer<CChar>?) = library.load(
        symbol: "sourcekitd_response_error_get_description",
    )
let sourcekitd_response_get_value:
    @convention(c) (sourcekitd_response_t) -> (sourcekitd_variant_t) = library.load(
        symbol: "sourcekitd_response_get_value",
    )
let sourcekitd_variant_get_type:
    @convention(c) (sourcekitd_variant_t) -> (sourcekitd_variant_type_t) = library.load(
        symbol: "sourcekitd_variant_get_type",
    )
let sourcekitd_variant_dictionary_get_value:
    @convention(c) (sourcekitd_variant_t, sourcekitd_uid_t) -> (sourcekitd_variant_t) =
    library
        .load(
            symbol: "sourcekitd_variant_dictionary_get_value",
        )
let sourcekitd_variant_dictionary_get_string:
    @convention(c) (sourcekitd_variant_t, sourcekitd_uid_t) -> (UnsafePointer<CChar>?) =
    library
        .load(
            symbol: "sourcekitd_variant_dictionary_get_string",
        )
let sourcekitd_variant_dictionary_get_int64:
    @convention(c) (sourcekitd_variant_t, sourcekitd_uid_t) -> (Int64) = library.load(
        symbol: "sourcekitd_variant_dictionary_get_int64",
    )
let sourcekitd_variant_dictionary_get_bool:
    @convention(c) (sourcekitd_variant_t, sourcekitd_uid_t) -> (Bool) = library.load(
        symbol: "sourcekitd_variant_dictionary_get_bool",
    )
let sourcekitd_variant_dictionary_get_uid:
    @convention(c) (sourcekitd_variant_t, sourcekitd_uid_t) -> (sourcekitd_uid_t?) = library.load(
        symbol: "sourcekitd_variant_dictionary_get_uid",
    )
let sourcekitd_variant_dictionary_apply_f:
    @convention(c) (
        sourcekitd_variant_t, sourcekitd_variant_dictionary_applier_f_t, UnsafeMutableRawPointer?,
    ) -> (Bool) = library.load(symbol: "sourcekitd_variant_dictionary_apply_f")
let sourcekitd_variant_array_get_count: @convention(c) (sourcekitd_variant_t) -> (Int) =
    library.load(symbol: "sourcekitd_variant_array_get_count")
let sourcekitd_variant_array_get_value:
    @convention(c) (sourcekitd_variant_t, Int) -> (sourcekitd_variant_t) = library.load(
        symbol: "sourcekitd_variant_array_get_value",
    )
let sourcekitd_variant_array_get_string:
    @convention(c) (sourcekitd_variant_t, Int) -> (UnsafePointer<CChar>?) = library.load(
        symbol: "sourcekitd_variant_array_get_string",
    )
let sourcekitd_variant_array_get_int64: @convention(c) (sourcekitd_variant_t, Int) -> (Int64) =
    library.load(
        symbol: "sourcekitd_variant_array_get_int64",
    )
let sourcekitd_variant_array_get_bool: @convention(c) (sourcekitd_variant_t, Int) -> (Bool) =
    library.load(
        symbol: "sourcekitd_variant_array_get_bool",
    )
let sourcekitd_variant_array_get_uid:
    @convention(c) (sourcekitd_variant_t, Int) -> (sourcekitd_uid_t?) = library.load(
        symbol: "sourcekitd_variant_array_get_uid",
    )
let sourcekitd_variant_array_apply_f:
    @convention(c) (
        sourcekitd_variant_t, sourcekitd_variant_array_applier_f_t, UnsafeMutableRawPointer?,
    ) -> (Bool) = library.load(symbol: "sourcekitd_variant_array_apply_f")
let sourcekitd_variant_int64_get_value: @convention(c) (sourcekitd_variant_t) -> (Int64) =
    library.load(symbol: "sourcekitd_variant_int64_get_value")
let sourcekitd_variant_bool_get_value: @convention(c) (sourcekitd_variant_t) -> (Bool) =
    library.load(symbol: "sourcekitd_variant_bool_get_value")
let sourcekitd_variant_string_get_length: @convention(c) (sourcekitd_variant_t) -> (Int) =
    library.load(symbol: "sourcekitd_variant_string_get_length")
let sourcekitd_variant_string_get_ptr:
    @convention(c) (sourcekitd_variant_t) -> (UnsafePointer<CChar>?) = library.load(
        symbol: "sourcekitd_variant_string_get_ptr",
    )
let sourcekitd_variant_data_get_size: @convention(c) (sourcekitd_variant_t) -> (Int) =
    library.load(symbol: "sourcekitd_variant_data_get_size")
let sourcekitd_variant_data_get_ptr: @convention(c) (sourcekitd_variant_t) -> (UnsafeRawPointer?) =
    library.load(
        symbol: "sourcekitd_variant_data_get_ptr",
    )
let sourcekitd_variant_uid_get_value: @convention(c) (sourcekitd_variant_t) -> (sourcekitd_uid_t?) =
    library.load(
        symbol: "sourcekitd_variant_uid_get_value",
    )
let sourcekitd_response_description_dump: @convention(c) (sourcekitd_response_t) -> Void =
    library.load(symbol: "sourcekitd_response_description_dump")
let sourcekitd_response_description_dump_filedesc:
    @convention(c) (sourcekitd_response_t, Int32) -> Void = library.load(
        symbol: "sourcekitd_response_description_dump_filedesc",
    )
let sourcekitd_response_description_copy:
    @convention(c) (sourcekitd_response_t) -> (UnsafeMutablePointer<CChar>?) = library.load(
        symbol: "sourcekitd_response_description_copy",
    )
let sourcekitd_variant_description_dump: @convention(c) (sourcekitd_variant_t) -> Void =
    library.load(symbol: "sourcekitd_variant_description_dump")
let sourcekitd_variant_description_dump_filedesc:
    @convention(c) (sourcekitd_variant_t, Int32) -> Void = library.load(
        symbol: "sourcekitd_variant_description_dump_filedesc",
    )
let sourcekitd_variant_description_copy:
    @convention(c) (sourcekitd_variant_t) -> (UnsafeMutablePointer<CChar>?) = library.load(
        symbol: "sourcekitd_variant_description_copy",
    )
let sourcekitd_variant_json_description_copy:
    @convention(c) (sourcekitd_variant_t) -> (UnsafeMutablePointer<CChar>?) = library.load(
        symbol: "sourcekitd_variant_json_description_copy",
    )
let sourcekitd_send_request_sync: @convention(c) (sourcekitd_object_t) -> (sourcekitd_response_t?) =
    library.load(
        symbol: "sourcekitd_send_request_sync",
    )
let sourcekitd_send_request:
    @convention(c) (
        sourcekitd_object_t, UnsafeMutablePointer<sourcekitd_request_handle_t?>?,
        sourcekitd_response_receiver_t?,
    ) -> Void = library.load(symbol: "sourcekitd_send_request")
let sourcekitd_cancel_request: @convention(c) (sourcekitd_request_handle_t?) -> Void =
    library.load(symbol: "sourcekitd_cancel_request")
let sourcekitd_set_notification_handler: @convention(c) (sourcekitd_response_receiver_t?) -> Void =
    library.load(
        symbol: "sourcekitd_set_notification_handler",
    )
let sourcekitd_set_uid_handler: @convention(c) (sourcekitd_uid_handler_t?) -> Void =
    library.load(symbol: "sourcekitd_set_uid_handler")
let sourcekitd_set_uid_handlers:
    @convention(c) (sourcekitd_uid_from_str_handler_t?, sourcekitd_str_from_uid_handler_t?)
    -> Void =
    library.load(symbol: "sourcekitd_set_uid_handlers")
