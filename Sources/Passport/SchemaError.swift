/// The type of schema error that occurred.
enum SchemaErrorKind {
    /// Indicates that a referenced field does not exist
    case noSuchField
}

/// The location where a schema error occurred.
enum SchemaErrorLocation {
    /// Error in a field of an entity
    /// - Parameters:
    ///   - String: The entity name
    ///   - String: The field name
    case entityField(String, String)
}

/// An error that occurs during schema validation or processing.
///
/// `SchemaError` provides detailed information about what went wrong
/// and where it occurred in the schema definition.
@MainActor struct SchemaError: Error {
    /// The type of error
    var kind: SchemaErrorKind

    /// Where the error occurred
    var location: SchemaErrorLocation
}
