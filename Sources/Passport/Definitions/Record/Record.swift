import Foundation

/// Qualifies a type to be queryable and, depending on the record type, storable.
public protocol Record: Model {
    /// A record type indicating the desired implementation for this record.
    static var recordType: RecordType { get }
    /// A set of queries to build for this record, with a name attached to each.
    static var queries: [NamedQuery] { get }
    /// The set of joins necessary to access this record.
    static var joins: [AnyJoin] { get }
}

/// Makes a type into a record. A ``RecordType`` must be provided.
/// Making a struct a record type will automatically generate helper functions
/// to make typed queries.
///
/// Any attached, non-static properties with an explicit type of ``Field`` will be marked
/// for inclusion.
///
/// Any attached, static properties with an explicit type of ``Query`` will have SQL
/// and methods (if languages support it) generated.
///
/// Any attached, static properties with an explicit type of ``Join`` will use those joins
/// in SQL generated for this type.
@attached(extension, conformances: Record, SchemaCompatible)
@attached(member, names:
          named(name),
          named(schemaEntity),
          named(recordType),
          named(field),
          named(fields),
          named(index),
          named(queries),
          named(joins),
          named(BaseValue),
          named(fromBase),
          named(fromExpression),
          named(fromJoin),
          named(select),
          named(insert),
          named(update),
          named(delete),
          named(join)
)
public macro Record(type: RecordType) = #externalMacro(
    module: "PassportMacros",
    type: "RecordMacro"
)

/// Determines behavior for a record.
public enum RecordType: Sendable {
    /// A simple table, stored and persisted in a database. Joins are not allowed.
    case table(String)
    /// A view, stored and persisted in a database. Joins are allowed.
    case view(String, any Record.Type)
    /// A query, which is not stored or persisted. This defines a query whose base table is the provided ``Record``.
    case query(any Record.Type)
    
    /// A helper that returns the canonical name for the record.
    public var name: String {
        switch self {
        case .table(let name):
            return name
        case .query(let base):
            return base.recordType.name
        case .view(let name, _):
            return name
        }
    }
}

