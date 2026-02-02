import Foundation

/// The core data type system used throughout Passport.
///
/// `DataType` represents all possible data types that can be used in models, records, and queries.
/// It's an indirect enum to support recursive types like arrays and optionals.
///
/// ## Basic Types
/// - `.int32`: 32-bit integer
/// - `.int64`: 64-bit integer
/// - `.string`: Text/string
/// - `.double`: Double-precision floating point
/// - `.bool`: Boolean
/// - `.datetime`: Date and time
/// - `.uuid`: UUID/GUID
///
/// ## Container Types
/// - `.array(DataType)`: Array of another type
/// - `.optional(DataType)`: Optional/nullable type
///
/// ## Reference Types
/// - `.model(any Model.Type)`: Reference to another model
/// - `.value(any Enum.Type)`: Reference to an enum type
///
/// ## Example
/// ```swift
/// var id = Field(.int64, .primaryKey)
/// var tags = Field(.array(.string))
/// var email = Field(.optional(.string))
/// var status = Field(.value(Status.self))
/// ```
public indirect enum DataType: Sendable {
    /// 32-bit integer
    case int32

    /// 64-bit integer
    case int64

    /// String/text
    case string

    /// Double-precision floating point
    case double

    /// Boolean
    case bool

    /// Date and time
    case datetime

    /// UUID/GUID
    case uuid
    
    case bytes

    /// Array of another data type
    case array(DataType)

    /// Optional/nullable data type
    case optional(DataType)

    /// Reference to a Model type
    case model(any Model.Type)

    /// Reference to an Enum type
    case value(any Enum.Type)

    /// Checks if this type is optional/nullable.
    var isOptional: Bool {
        switch self {
        case .optional(_):
            return true
        default:
            return false
        }
    }

    /// Checks if this type is an array.
    var isArray: Bool {
        switch self {
        case .array(_):
            return true
        default:
            return false
        }
    }
}

/// Represents a schema entity (record, model, or enum).
///
/// Used internally to categorize types when building schemas.
public enum SchemaEntity: Sendable {
    case record(any Record.Type)
    case model(any Model.Type)
    case enm(any Enum.Type)
}

/// Protocol for types that can be included in a schema.
///
/// Models, Records, and Enums conform to this protocol (typically via macros)
/// to be usable in schema definitions.
public protocol SchemaCompatible {
    /// The schema entity type of this type
    static var schemaEntity: SchemaEntity { get }
}

/// Result builder for creating schemas with declarative syntax.
///
/// `SchemaBuilder` enables the DSL syntax for defining schemas:
///
/// ```swift
/// Schema {
///     User.self
///     Post.self
///     Comment.self
/// }
/// ```
@resultBuilder
public struct SchemaBuilder {
    /// The result of building a schema, containing categorized types.
    public struct Result {
        /// All model types in the schema
        var models: [any Model.Type] = []

        /// All record types in the schema
        var records: [any Record.Type] = []

        /// All enum types in the schema
        var enums: [any Enum.Type] = []
    }

    /// Builds a schema result from schema-compatible types.
    ///
    /// - Parameter expression: Variadic list of schema-compatible types
    /// - Returns: A Result containing categorized models, records, and enums
    public static func buildBlock(_ expression: SchemaCompatible.Type...) -> Result {
        var result = Result()
        for e in expression {
            switch e.schemaEntity {
            case .enm(let enm):
                result.enums.append(enm)
            case .model(let mdl):
                result.models.append(mdl)
            case .record(let rcd):
                result.records.append(rcd)
            }
        }

        return result
    }
}
