import Foundation

/// Describes the characteristics of a field including its type, column name, and metadata.
///
/// `FieldDescription` contains all the information needed to generate code and SQL
/// for a model field, including optional computed definitions and database tags.
final public class FieldDescription: Sendable {
    /// The database column name (if different from the field name)
    let columnName: String?

    /// The base table name for joined fields
    let base: String?

    /// For computed fields, the SQL expression components
    let definition: [QueryInterpolation]?

    /// The data type of this field
    let dataType: DataType

    /// Metadata tags like primary key, foreign key, default values, etc.
    let tags: [FieldTag]

    /// Creates a field description.
    ///
    /// - Parameters:
    ///   - columnName: Optional custom column name
    ///   - base: Optional base table name for joined fields
    ///   - definition: Optional SQL expression for computed fields
    ///   - dataType: The data type
    ///   - tags: Field metadata tags
    public init(
        columnName: String? = nil,
        base: String? = nil,
        definition: [QueryInterpolation]? = nil,
        dataType: DataType,
        tags: [FieldTag]
    ) {
        self.columnName = columnName
        self.base = base
        self.definition = definition
        self.dataType = dataType
        self.tags = tags
    }
}

/// Internal enum for tracking whether a field description is stored or lazily computed.
enum FieldDescriptionLocation: Sendable {
    case stored(FieldDescription)
    case remote(@Sendable () -> FieldDescription)
}

/// Represents a field in a Model or Record.
///
/// `Field` is the core building block for defining properties in Passport models.
/// Fields can be:
/// - Simple stored fields with a data type and optional tags
/// - Computed fields with SQL expressions
/// - Foreign key references to other records
/// - Joined fields from related tables
///
/// ## Example
/// ```swift
/// @Record(type: .table("users"))
/// struct User {
///     var id = Field(.int64, .primaryKey, .generatedAlways)
///     var email = Field(.string)
///     var createdAt = Field(.datetime, .defaultValue("NOW()"))
/// }
/// ```
final public class Field: Sendable {
    /// The location where the field description is stored or computed
    let descriptionLocation: FieldDescriptionLocation

    /// The field's description, either stored or lazily computed
    var description: FieldDescription {
        switch descriptionLocation {
        case .stored(let fieldDescription):
            return fieldDescription
        case .remote(let descriptionHandler):
            return descriptionHandler()
        }
    }

    /// Creates a simple field with a data type and optional tags.
    ///
    /// - Parameters:
    ///   - dataType: The field's data type
    ///   - rules: Optional field tags (e.g., .primaryKey, .foreignKey)
    ///
    /// ## Example
    /// ```swift
    /// var id = Field(.int64, .primaryKey, .generatedAlways)
    /// var email = Field(.string)
    /// ```
    public init( _ dataType: DataType, _ rules: FieldTag...) {
        self.descriptionLocation =
            .stored(
                .init(dataType: dataType, tags: rules)
            )
    }
    

    /// Creates a computed field with a SQL expression.
    ///
    /// Computed fields are not stored in the database but are calculated using a SQL expression.
    ///
    /// - Parameters:
    ///   - dataType: The resulting data type of the expression
    ///   - expression: A closure that returns the SQL expression components
    ///
    /// ## Example
    /// ```swift
    /// var fullName = Field<User>(
    ///     dataType: .string,
    ///     expression: { User.concat([.field(\.firstName), .literal(" "), .field(\.lastName)]) }
    /// )
    /// ```
    public init<T: Record>(
        dataType: DataType,
        expression: @Sendable @escaping () -> QueryStringSingleLocationCondition<T>
    ) {
        self.descriptionLocation =
            .remote({
                let expr = expression()
                return .init(
                    definition: expr.components,
                    dataType: dataType,
                    tags: []
                )
            })
    }

    /// Creates a field that references another field from the same or different record.
    ///
    /// This is useful for creating aliases or references to fields in the base record.
    ///
    /// - Parameter b: Key path to the field being referenced
    public init<T: Record>(fromBase b: KeyPath<T, Field>) {
        let index = T.index(forKeyPath: b)
        self.descriptionLocation = .remote({
            let referencingField = T.fields[index]
            let referencingFieldData = referencingField.field.description
            return .init(
                columnName: referencingFieldData.columnName ?? referencingField.name,
                dataType: referencingFieldData.dataType,
                tags: referencingFieldData.tags
            )
        })
    }

    /// Creates a field from a joined table.
    ///
    /// This allows accessing fields from related records through JOIN operations.
    ///
    /// - Parameters:
    ///   - withJoin: The join definition specifying the relationship
    ///   - field: Key path to the field in the joined record
    ///
    /// ## Example
    /// ```swift
    /// var authorName = Field(withJoin: authorJoin, field: \.name)
    /// ```
    public init<T: Record>(withJoin: Join<T>, field: KeyPath<T, Field>) {
        let index = T.index(forKeyPath: field)
        self.descriptionLocation = .remote({
            let referencingField = T.fields[index]
            let referencingFieldData = referencingField.field.description
            return .init(
                columnName: referencingFieldData.columnName ?? referencingField.name,
                base: withJoin.joinName,
                dataType: referencingFieldData.dataType,
                tags: referencingFieldData.tags
            )
        })
    }
    
    
    /// Creates a field from a joined table.
    ///
    /// This allows accessing fields from related records through JOIN operations.
    ///
    /// - Parameters:
    ///   - withJoin: The join definition specifying the relationship
    ///   - field: Key path to the field in the joined record
    ///
    /// ## Example
    /// ```swift
    /// var authorName = Field(withJoin: authorJoin, field: \.name)
    /// ```
    public init<T: Record>(withJoin: Join<T>, field: KeyPath<T, Field>, fromView: String) {
        let index = T.index(forKeyPath: field)
        self.descriptionLocation = .remote({
            let referencingField = T.fields[index]
            let referencingFieldData = referencingField.field.description
            return .init(
                columnName: referencingFieldData.columnName ?? referencingField.name,
                base: fromView,
                dataType: referencingFieldData.dataType,
                tags: referencingFieldData.tags
            )
        })
    }

    /// Checks if this field has a specific tag.
    ///
    /// - Parameter tag: The tag to check for
    /// - Returns: `true` if the field has the specified tag, `false` otherwise
    public func tagged(with tag: FieldTag) -> Bool {
        guard case let .custom(id) = tag else {
            return false
        }
        for t in self.description.tags {
            if case let .custom(string) = t, id == string {
                return true
            }
        }
        return false
    }
}
