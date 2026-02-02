import Foundation

/// The type of database query operation.
///
/// `QueryType` represents the different kinds of queries that can be defined,
/// each with their specific parameters and builders.
public enum QueryType: Sendable {
    /// SELECT query with parameters built using SelectQueryBuilder
    case select(@Sendable () -> SelectQueryParameters)

    /// INSERT query with the fields to insert
    case insert([NamedField])

    /// UPDATE query with parameters built using UpdateQueryBuilder
    case update(@Sendable() -> UpdateQueryParameters)

    /// DELETE query with parameters built using DeleteQueryBuilder
    case delete(@Sendable() -> DeleteQueryParameters)

    /// Raw SQL query (advanced use)
    case raw
}

/// Indicates how many results a query returns.
///
/// Used for type safety and optimization in generated code.
public enum ReturnCount: Sendable {
    /// Query returns no results
    case none

    /// Query returns exactly one result
    case one

    /// Query returns zero or more results
    case many
}

/// A function that builds raw SQL queries.
///
/// - Parameters:
///   - table: The table name
///   - selectFields: The comma-separated field list
/// - Returns: The raw SQL string
public typealias RawQueryBuilder = (_ table: String, _ selectFields: String) -> String
