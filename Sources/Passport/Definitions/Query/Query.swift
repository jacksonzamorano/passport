import Foundation

/// Specifies the sort direction for ORDER BY clauses.
public enum SortDirection: String, Codable, Sendable {
    /// Ascending order (smallest to largest)
    case asc

    /// Descending order (largest to smallest)
    case desc
}

/// A field with an associated name, used for query parameter mapping.
final public class NamedField: Sendable {
    /// The field name
    public let name: String

    /// The field definition
    public let field: Field

    /// Creates a named field.
    ///
    /// - Parameters:
    ///   - name: The field name
    ///   - field: The field definition
    public init(_ name: String, _ field: Field) {
        self.name = name
        self.field = field
    }
}

/// A query with an associated name, used for storing queries on Records.
final public class NamedQuery: Sendable {
    /// The query name
    public let name: String

    /// The query definition
    public let query: Query

    /// Creates a named query.
    ///
    /// - Parameters:
    ///   - name: The query name
    ///   - query: The query definition
    public init(_ name: String, _ query: Query) {
        self.name = name
        self.query = query
    }
}

/// Represents a type-safe database query (SELECT, INSERT, UPDATE, or DELETE).
///
/// `Query` is the core abstraction for database operations in Passport. It encapsulates
/// the query type, arguments, and return characteristics. Queries are defined using
/// static factory methods and builder patterns.
///
/// ## Example
/// ```swift
/// let selectQuery = Query.select(User.self, UserArgs.self) { builder in
///     builder.where(\.id, .equals, .arg(\.userId))
///     builder.limit(10)
/// }
/// ```
public struct Query: Sendable {
    /// The type of query (SELECT, INSERT, UPDATE, DELETE)
    let type: QueryType

    /// The arguments required by this query
    let arguments: [QueryArg]

    /// Indicates whether this query returns zero, one, or many results
    var returnCount: ReturnCount {
        switch type {
        case .select(let handler):
            return handler().returnCount
        case .insert(_):
            return .one
        case .update(let handler):
            return handler().returnCount
        default:
            return .many
        }
    }

    /// Creates a new query.
    ///
    /// - Parameters:
    ///   - type: The query type
    ///   - arguments: The query arguments
    init(type: QueryType, arguments: [QueryArg]) {
        self.type = type
        self.arguments = arguments
    }
    
    /// Creates a SELECT query with type-safe arguments and conditions.
    ///
    /// - Parameters:
    ///   - table: The record type to query
    ///   - args: The query arguments type (must conform to QueryArguments)
    ///   - build: A closure to configure the query builder with WHERE, ORDER BY, LIMIT, etc.
    /// - Returns: A configured SELECT query
    ///
    /// ## Example
    /// ```swift
    /// Query.select(User.self, UserArgs.self) { builder in
    ///     builder.where(\.email, .equals, .arg(\.email))
    ///     builder.orderBy(\.createdAt, .desc)
    ///     builder.limit(10)
    /// }
    /// ```
    public static func select<T: Record, A: QueryArguments>(_ table: T.Type, _ args: A.Type, _ build: @Sendable @escaping (SelectQueryBuilder<T, A>) -> Void) -> Query {
        let handler: @Sendable () -> SelectQueryParameters = {
            let builder = SelectQueryBuilder<T, A>()
            build(builder)
            return builder.parameters
        }
        let q = Query(type: .select(handler), arguments: A._asArguments())
        return q
    }

    /// Creates an INSERT query for the specified fields.
    ///
    /// - Parameters:
    ///   - table: The record type to insert into
    ///   - fields: Key paths to the fields that will be inserted
    /// - Returns: An INSERT query that returns the inserted record
    ///
    /// ## Example
    /// ```swift
    /// Query.insert(User.self, [\.email, \.name, \.createdAt])
    /// ```
    public static func insert<T: Record>(_ table: T.Type, _ fields: [KeyPath<T, Field>]) -> Query {
        let fieldNames = fields.map { field in
            return T.field(forKeyPath: field)!
        }
        let arguments = fields.map { kp in
            let field = T.field(forKeyPath: kp)!
            return QueryArg(field.name, field.field.description.dataType)
        }
        let q = Query(type: .insert(fieldNames), arguments: arguments)
        return q
    }

    /// Creates an UPDATE query with type-safe arguments and conditions.
    ///
    /// - Parameters:
    ///   - table: The record type to update
    ///   - args: The query arguments type (must conform to QueryArguments)
    ///   - build: A closure to configure the update builder with SET and WHERE clauses
    /// - Returns: An UPDATE query that returns the updated record(s)
    ///
    /// ## Example
    /// ```swift
    /// Query.update(User.self, UpdateUserArgs.self) { builder in
    ///     builder.set(\.name, to: .arg(\.newName))
    ///     builder.where(\.id, .equals, .arg(\.userId))
    /// }
    /// ```
    public static func update<T: Record, A: QueryArguments>(
        _ table: T.Type,
        _ args: A.Type,
        _ build: @Sendable @escaping (UpdateQueryBuilder<T, A>) -> Void
    ) -> Query {
        let handler: @Sendable () -> UpdateQueryParameters = {
            let builder = UpdateQueryBuilder<T, A>()
            build(builder)
            return builder.parameters
        }
        let q = Query(type: .update(handler), arguments: A._asArguments())
        return q
    }

    /// Creates a DELETE query with type-safe arguments and conditions.
    ///
    /// - Parameters:
    ///   - table: The record type to delete from
    ///   - args: The query arguments type (must conform to QueryArguments)
    ///   - build: A closure to configure the delete builder with WHERE conditions
    /// - Returns: A DELETE query that returns the deleted record(s)
    ///
    /// ## Example
    /// ```swift
    /// Query.delete(User.self, DeleteUserArgs.self) { builder in
    ///     builder.where(\.id, .equals, .arg(\.userId))
    /// }
    /// ```
    public static func delete<T: Record, A: QueryArguments>(
        _ table: T.Type,
        _ args: A.Type,
        _ build: @Sendable @escaping (DeleteQueryBuilder<T, A>) -> Void
    ) -> Query {
        let handler: @Sendable () -> DeleteQueryParameters = {
            let builder = DeleteQueryBuilder<T, A>()
            build(builder)
            return builder.parameters
        }
        let q = Query(
            type: .delete(handler),
            arguments: A._asArguments(),
        )
        return q
    }
}
