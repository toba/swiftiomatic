// Fixture: typed throws candidates

enum ParseError: Error {
    case invalidInput
    case unexpectedToken
}

// Should flag: throws only ParseError
func parse(_: String) throws {
    throw ParseError.invalidInput
}

// Should flag: throws only ParseError (via .case syntax)
func validate(_: String) throws {
    throw ParseError.unexpectedToken
}

// Should NOT flag: already typed
func strictParse(_: String) throws(ParseError) {
    throw .invalidInput
}

// Should NOT flag: throws multiple types
enum NetworkError: Error { case timeout }
func fetchAndParse() throws {
    throw ParseError.invalidInput
    throw NetworkError.timeout
}

// Should NOT flag: no throws clause
func safeParse(_: String) -> String? {
    nil
}

// Should flag: catch let error as SpecificType
func catchAsPattern() throws {
    do {
        try parse("")
    } catch let error as ParseError {
        throw error
    }
}

// Should flag: Result<T, E> return type on non-throwing function
func fetchResult() -> Result<String, ParseError> {
    .success("ok")
}

// Should NOT flag: Result<T, Error> (untyped error)
func fetchAnyResult() -> Result<String, Error> {
    .success("ok")
}
