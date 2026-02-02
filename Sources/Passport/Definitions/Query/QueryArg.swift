import Foundation

/// Represents a typed argument for a database query.
///
/// `QueryArg` defines a named parameter with a specific data type that will be
/// passed to a query at runtime. These are extracted from `@Argument` structs
/// to create type-safe query parameters.
///
/// ## Example
/// ```swift
/// @Argument
/// struct SelectByIdArgs {
///     var userId = Field(.int64)  // Becomes QueryArg("userId", .int64)
/// }
/// ```
public struct QueryArg: Sendable {
    /// The parameter name
    var name: String

    /// The parameter's data type
    var dataType: DataType

    /// Creates a query argument.
    ///
    /// - Parameters:
    ///   - name: The argument name
    ///   - dataType: The argument's data type
    public init(_ name: String, _ dataType: DataType) {
        self.name = name
        self.dataType = dataType
    }
}
