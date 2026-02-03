/// Protocol for implementing database-specific SQL generation.
///
/// `Dialect` defines the interface for generating SQL statements in different database systems.
/// Each database (PostgreSQL, MySQL, SQLite, etc.) can have its own implementation with
/// specific syntax, data types, and features.
///
/// ## Built-in Implementations
/// - `Postgres`: PostgreSQL dialect
///
/// ## Example Custom Implementation
/// ```swift
/// class MySQL: Dialect {
///     var terminator: String = ";"
///     func convertType(_ type: DataType) throws -> String {
///         // Convert Passport types to MySQL types
///     }
///     // ... implement other required methods
/// }
/// ```
public protocol Dialect {
    /// The SQL statement terminator (usually ";")
    var terminator: String { get }
    
    var startTransactionMarker: String { get }
    var endTransactionMarker: String { get }

    /// Converts a Passport DataType to a database-specific SQL type.
    ///
    /// - Parameter type: The Passport data type to convert
    /// - Returns: The SQL type string (e.g., "INT8", "TEXT", "BOOL")
    /// - Throws: `SQLError.typeNotSupported` if the type is not supported
    func convertType(_ type: DataType) throws -> String

    /// Generates the parameter placeholder token for a query parameter.
    ///
    /// - Parameter idx: The zero-based parameter index
    /// - Returns: The parameter token (e.g., "$1" for Postgres, "?" for MySQL)
    func queryParameterToken(atIndex idx: Int) -> String

    /// Converts query interpolation components to SQL strings.
    ///
    /// - Parameter components: Array of interpolation components (arguments, fields, literals, raw SQL)
    /// - Returns: Array of SQL string fragments
    func interpolate(components: [QueryInterpolation], fullyQualify: Bool) -> [String]

    /// Builds a CREATE TYPE statement for an enum.
    ///
    /// - Parameter enm: The enum type to create
    /// - Returns: The CREATE TYPE SQL, or nil if not supported
    func buildEnumCreateCommand(enm: any Enum.Type) -> String?

    /// Builds a DROP TYPE statement for an enum.
    ///
    /// - Parameter enm: The enum type to drop
    /// - Returns: The DROP TYPE SQL, or nil if not supported
    func buildEnumDropCommand(enm: any Enum.Type) -> String?

    /// Builds a CREATE TABLE or VIEW statement.
    ///
    /// - Parameters:
    ///   - type: The record type (table or view)
    ///   - fields: Array of column definition strings
    /// - Returns: The CREATE statement, or nil if not supported
    func buildCreateCommand(type: RecordType, fields: [String]) -> String?

    /// Builds a DROP TABLE or VIEW statement.
    ///
    /// - Parameter type: The record type to drop
    /// - Returns: The DROP statement, or nil if not supported
    func buildDropCommand(type: RecordType) -> String?

    /// Builds a column definition for a CREATE TABLE statement.
    ///
    /// - Parameters:
    ///   - name: The column name
    ///   - dataType: The Passport data type
    ///   - traits: Field tags (primary key, foreign key, default, etc.)
    /// - Returns: The column definition string (e.g., "id INT8 PRIMARY KEY")
    /// - Throws: `SQLError` if the type cannot be converted
    func buildColumnDefinition(name: String, dataType: DataType, traits: [FieldTag]) throws -> String

    /// Builds the column list for a SELECT statement.
    ///
    /// - Parameters:
    ///   - columns: Array of columns to select
    ///   - location: The base table name
    /// - Returns: Comma-separated column list with aliases (e.g., "users.id AS id, users.name AS name")
    func buildColumns(columns: [Column], location: String) -> String

    /// Builds a complete SELECT statement.
    ///
    /// - Parameter request: The select request with columns, location, params, CTEs, and joins
    /// - Returns: The complete SELECT SQL
    func buildSelect(request: SelectRequest) -> String

    /// Builds an INSERT statement.
    ///
    /// - Parameters:
    ///   - columnNames: Comma-separated column names
    ///   - columnValues: Comma-separated value placeholders
    ///   - tableName: The table to insert into
    /// - Returns: The INSERT statement (typically with RETURNING clause)
    func buildInsert(columnNames: String, columnValues: String, tableName: String) -> String

    /// Builds an UPDATE statement.
    ///
    /// - Parameters:
    ///   - update: The update parameters with SET and WHERE clauses
    ///   - tableName: The table to update
    /// - Returns: The UPDATE statement
    func buildUpdate(update: UpdateQueryParameters, tableName: String) -> String

    /// Builds a DELETE statement.
    ///
    /// - Parameters:
    ///   - delete: The delete parameters with WHERE clause
    ///   - tableName: The table to delete from
    /// - Returns: The DELETE statement (typically with RETURNING clause)
    func buildDelete(delete: DeleteQueryParameters, tableName: String) -> String

    /// Builds a JOIN clause.
    ///
    /// - Parameter join: The join definition
    /// - Returns: The JOIN SQL (e.g., "INNER JOIN users u ON u.id = posts.user_id")
    func buildJoin(join: JoinRequest) -> String
}
