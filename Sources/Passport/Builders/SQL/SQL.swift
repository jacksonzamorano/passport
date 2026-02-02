/// Temporary table name used for INSERT query results in CTE-based queries.
let INSERT_TEMP_TABLE_NAME: String = "insert_result"

/// Temporary table name used for UPDATE query results in CTE-based queries.
let UPDATE_TEMP_TABLE_NAME: String = "update_result"

/// Temporary table name used for DELETE query results in CTE-based queries.
let DELETE_TEMP_TABLE_NAME: String = "delete_result"

/// Errors that can occur during SQL generation.
public enum SQLError: Error {
    /// Indicates that a DataType cannot be converted to a SQL type in the current dialect.
    case typeNotSupported(DataType)
}

/// A request object containing all parameters needed to build a SELECT statement.
///
/// This struct encapsulates the various components of a SELECT query, including columns,
/// table location, query parameters, common table expressions (CTEs), and joins.
public struct SelectRequest {
    /// Comma-separated list of columns to select
    public var columns: String

    /// The table or subquery to select from
    public var location: String

    /// Query parameters like WHERE conditions, ORDER BY, LIMIT, etc.
    public var params: SelectQueryParameters

    /// Common Table Expressions (WITH clauses) mapping CTE name to SQL definition
    public var ctes: [String: String] = [:]

    /// Array of JOIN clauses to include in the query
    public var joins: [String] = []
}

/// Builds SQL statements and schema scripts for database operations.
///
/// `SQLBuilder` is the core SQL generation engine that works with a specific SQL dialect
/// to create database schemas, tables, and queries. It handles:
/// - Creating and dropping tables
/// - Generating enum types
/// - Building SELECT, INSERT, UPDATE, and DELETE queries
/// - Managing CTEs (Common Table Expressions) for complex queries
///
/// ## Example Usage
/// ```swift
/// let postgres = SQLBuilder(Postgres())
/// let createScript = try postgres.createScript(schema: mySchema)
/// ```
public class SQLBuilder {

    /// The SQL dialect used for generating database-specific SQL
    var dialect: any Dialect

    /// Creates a new SQL builder with the specified dialect.
    ///
    /// - Parameter dialect: The SQL dialect to use (e.g., Postgres)
    public init(_ dialect: any Dialect) {
        self.dialect = dialect
    }
    
    /// Generates a complete SQL script for creating the database schema.
    ///
    /// This method generates DROP and CREATE statements for all tables and enums in the schema.
    /// The output order is:
    /// 1. DROP TABLE statements for all records
    /// 2. DROP TYPE statements for all enums
    /// 3. CREATE TYPE statements for all enums
    /// 4. CREATE TABLE statements for all records
    ///
    /// - Parameter schema: The schema containing records and enums to generate SQL for
    /// - Returns: A complete SQL script ready to execute
    /// - Throws: SQLError if any type cannot be converted
    public func createScript(schema: Schema) throws -> String {
        var output = String()
        for record in schema.records {
            if let drop = drop(record: record.recordType) {
                output += drop
                output += dialect.terminator
                output += "\n"
            }
        }
        for enm in schema.enums {
            if let drop = dialect.buildEnumDropCommand(enm: enm) {
                output += drop
                output += dialect.terminator
                output += "\n"
            }
        }
        output += "\n\n"
        for enm in schema.enums {
            if let create = dialect.buildEnumCreateCommand(enm: enm) {
                output += create
                output += dialect.terminator
                output += "\n"
            }
        }
        for record in schema.records {
            if let create = try create(record: record) {
                output += create
                output += dialect.terminator
                output += "\n"
            }
        }
        return output
    }

    /// Generates SQL for all queries defined across all records in the schema.
    ///
    /// - Parameter schema: The schema containing records with queries
    /// - Returns: SQL statements for all queries, separated by blank lines
    /// - Throws: SQLError if query generation fails
    public func allQueries(inSchema schema: Schema) throws -> String {
        var output = String()
        for record in schema.records {
            for query in record.queries {
                output += self.build(query: query.query, forRecord: record)
                output += "\n\n"
            }
        }
        return output
    }
    
    /// Generates a DROP TABLE statement for a record.
    ///
    /// - Parameter record: The record type to drop
    /// - Returns: A DROP TABLE statement, or nil if not supported by the dialect
    public func drop(record: RecordType) -> String? {
        return dialect.buildDropCommand(type: record)
    }

    /// Generates a CREATE TABLE statement for a record.
    ///
    /// This method filters out computed fields (those with definitions) and generates
    /// column definitions for all stored fields.
    ///
    /// - Parameter record: The record type to create
    /// - Returns: A CREATE TABLE statement, or nil if not supported by the dialect
    /// - Throws: SQLError if any field type cannot be converted
    public func create(record: any Record.Type) throws -> String? {
        let fields = try record.fields
            .filter { $0.field.description.definition == nil }
            .map {
                let desc = $0.field.description
                return try dialect.buildColumnDefinition(name: $0.name,
                                                  dataType: desc.dataType,
                                                  traits: desc.tags)
            }
        return dialect.buildCreateCommand(type: record.recordType, fields: fields)

    }

    /// Builds a SQL query for a given Query and Record type.
    ///
    /// This method handles all query types (SELECT, INSERT, UPDATE, DELETE) and generates
    /// appropriate SQL using CTEs where needed. UPDATE and DELETE queries are wrapped in
    /// CTEs with a SELECT to return the affected rows.
    ///
    /// - Parameters:
    ///   - query: The query definition to build
    ///   - record: The record type this query operates on
    /// - Returns: The complete SQL statement for the query
    public func build(query: Query, forRecord record: any Record.Type) -> String {
        var sql: String = ""
        switch query.type {
        case .select(let parameters):
            let columns = Column.create(fromFields: record.fields)
            let selectColumns = dialect.buildColumns(columns: columns, location: record.recordType.name)
            let selectRequest = SelectRequest(
                columns: selectColumns,
                location: record.recordType.name,
                params: parameters(),
                joins: record.joins.map { dialect.buildJoin(join: $0) }
            )
            sql = dialect.buildSelect(request: selectRequest)
        case .insert(let fields):
            let insertVariableNames = dialect.interpolate(components: fields.enumerated().map { idx, _ in
                return QueryInterpolation.argument(idx)
            })
            
            let insertColumns = Column.create(fromFields: fields)
            let insert = dialect.buildInsert(columnNames: insertColumns.map{ $0.fieldName }.joined(separator: ", "), columnValues: insertVariableNames.joined(separator: ", "), tableName:  record.recordType.name)
            
            let selectColumns = Column.create(fromFields: record.fields)
            let selectColumnNames = dialect.buildColumns(columns: selectColumns, location: INSERT_TEMP_TABLE_NAME)
            let selectRequest = SelectRequest(
                columns: selectColumnNames,
                location: INSERT_TEMP_TABLE_NAME,
                params: SelectQueryParameters(),
                ctes: [INSERT_TEMP_TABLE_NAME: insert],
                joins: record.joins.map({ dialect.buildJoin(join: $0) })
            )
            sql = dialect.buildSelect(request: selectRequest)
        case .update(let parameters):
            let update = dialect.buildUpdate(
                update: parameters(),
                tableName: record.recordType.name
            )
            
            let selectColumns = dialect.buildColumns(
                columns: Column.create(fromFields: record.fields),
                location: UPDATE_TEMP_TABLE_NAME
            )
            
            let selectRequest = SelectRequest(
                columns: selectColumns,
                location: UPDATE_TEMP_TABLE_NAME,
                params: SelectQueryParameters(),
                ctes: [UPDATE_TEMP_TABLE_NAME: update],
                joins: record.joins.map({ dialect.buildJoin(join: $0) })
            )
            sql = dialect.buildSelect(request: selectRequest)
        case .delete(let parameters):
            let delete = dialect.buildDelete(
                delete: parameters(),
                tableName: record.recordType.name
            )
            
            let selectColumns = dialect.buildColumns(
                columns: Column.create(fromFields: record.fields),
                location: UPDATE_TEMP_TABLE_NAME
            )
            let selectRequest = SelectRequest(
                columns: selectColumns,
                location: UPDATE_TEMP_TABLE_NAME,
                params: SelectQueryParameters(),
                ctes: [DELETE_TEMP_TABLE_NAME: delete],
                joins: record.joins.map({ dialect.buildJoin(join: $0) })
            )
            sql = dialect.buildSelect(request: selectRequest)
        default:
            break
        }
        return sql
    }
}
