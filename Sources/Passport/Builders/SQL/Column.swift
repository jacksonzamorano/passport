/// Represents a column in a SQL SELECT statement.
///
/// `Column` encapsulates the information needed to generate column selections in SQL,
/// including the display name (alias), field name, location (table), and optional
/// SQL expressions for computed columns.
///
/// Columns are typically created from Field definitions and used by SQL dialects
/// to build the column list for SELECT statements.
public struct Column {
    /// The display name (alias) for the column in the result set
    public var displayName: String

    /// The actual column name in the database
    public var fieldName: String

    /// The table or join alias where this field originates (nil for base table)
    public var fieldLocation: String?

    /// For computed fields, the SQL expression components
    public var fieldExpression: [QueryInterpolation]?

    /// Creates columns from an array of named fields.
    ///
    /// This factory method converts Field definitions into Column structures
    /// suitable for SQL generation.
    ///
    /// - Parameter fields: Array of named fields from a model or record
    /// - Returns: Array of columns with proper names, locations, and expressions
    static func create(fromFields fields: [NamedField]) -> [Column] {
        return fields
            .map {
                let desc = $0.field.description
                return Column(
                    displayName: $0.name,
                    fieldName: desc.columnName ?? $0.name,
                    fieldLocation: desc.base,
                    fieldExpression: desc.definition,
                )
            }
    }
}
