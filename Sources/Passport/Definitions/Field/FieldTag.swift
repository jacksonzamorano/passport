import Foundation

/// Metadata tags that can be applied to fields to control database constraints and behavior.
///
/// `FieldTag` provides type-safe ways to specify common database column attributes
/// like primary keys, foreign keys, default values, and more.
///
/// ## Example
/// ```swift
/// var id = Field(.int64, .primaryKey, .generatedAlways)
/// var email = Field(.string)
/// var createdAt = Field(.datetime, .defaultValue("NOW()"))
/// var authorId = Field(.int64, .foreignKey(User.self, \.id))
/// ```
public enum FieldTag: Sendable {
    /// Marks the field as a primary key column
    case primaryKey

    /// Indicates the field is automatically generated (e.g., auto-increment, GENERATED ALWAYS)
    case generatedAlways

    /// Specifies a default value expression for the column
    ///
    /// - Parameter String: The SQL expression for the default value (e.g., "NOW()", "'default'")
    case defaultValue(String)

    case foreignKey(ForeignKeyDefinitionFunction)
    public struct ForeignKeyDefinition {
        public let entity: String
        public let column: String
    }
    
    case unique

    /// A custom tag for dialect-specific or special column attributes
    ///
    /// - Parameter String: The custom attribute string
    case custom(String)

    /// Creates a type-safe foreign key reference to a field in another Record.
    ///
    /// - Parameter keyPath: Key path to the referenced field
    /// - Returns: A foreignKey tag with the table and column names
    ///
    /// ## Example
    /// ```swift
    /// var authorId = Field(.int64, .foreignKey(User.self, \.id))
    /// ```
    static public func foreignKey<T: Record>(_ keyPath: KeyPath<T, Field>) -> Self {
        let idx = T.index(forKeyPath: keyPath)
        return .foreignKey {
            return ForeignKeyDefinition(
                entity: T.recordType.name,
                column: T.fields[idx].name
            )
        }
    }
}

public typealias ForeignKeyDefinitionFunction = @Sendable () -> FieldTag.ForeignKeyDefinition
