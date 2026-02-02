/// Errors that can occur during language-specific code generation.
///
/// `LanguageError` is thrown by Language implementations when they encounter
/// issues generating code, such as unsupported types or invalid configurations.
///
/// Language implementations should add their own error cases as needed.
enum LanguageError: Error {
    case routesNotSupported, recordsNotSupported
}
