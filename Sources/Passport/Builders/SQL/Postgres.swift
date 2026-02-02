/// PostgreSQL dialect implementation for SQL generation.
///
/// `Postgres` implements the `Dialect` protocol to generate PostgreSQL-specific SQL
/// statements, including proper type conversions, parameter placeholders, and PostgreSQL features
/// like RETURNING clauses and array types.
///
/// ## Features
/// - PostgreSQL data types (INT4, INT8, TEXT, BOOL, etc.)
/// - Array type support (e.g., TEXT[])
/// - Numbered parameter placeholders ($1, $2, etc.)
/// - CREATE TYPE for enums
/// - RETURNING clauses for INSERT, UPDATE, DELETE
/// - CTEs (Common Table Expressions) support
///
/// ## Example
/// ```swift
/// let postgres = SQLBuilder(Postgres())
/// let sql = try postgres.createScript(schema: mySchema)
/// ```
public class Postgres: Dialect {
    /// Creates a new PostgreSQL dialect instance.
    public init() {}

    /// The SQL statement terminator for PostgreSQL
    public var terminator: String = ";"
    public func convertType(_ type: DataType) throws -> String {
        switch type {
        case .optional(let o):
            return try self.convertType(o)
        case .array(let t):
            let inner = try self.convertType(t)
            return inner + "[]"
        case .bool:
            return "BOOL"
        case .double:
            return "DOUBLE"
        case .bytes:
            return "BINARY"
        case .datetime:
            return "TIMESTAMPTZ"
        case .int32:
            return "INT4"
        case .int64:
            return "INT8"
        case .string:
            return "TEXT"
        default:
            throw SQLError.typeNotSupported(type)
        }
    }
    public func queryParameterToken(atIndex idx: Int) -> String {
        return "$\(idx + 1)"
    }
    public func buildEnumCreateCommand(enm: any Enum.Type) -> String? {
        let casesString = enm.variants.values.map{"\"\($0)\""}.joined(separator: ", ")
        return "CREATE TYPE \(enm.name) AS (\(casesString))"
    }
    public func buildEnumDropCommand(enm: any Enum.Type) -> String? {
        return "DROP TYPE \(enm.name)"
    }
    public func buildCreateCommand(type: RecordType, fields: [String]) -> String? {
        switch type {
        case .table(let table):
            return """
                CREATE TABLE \(table) (
                    \(fields.joined(separator: ",\n\t"))
                )
                """
        case .view(let view, _):
            return """
                CREATE VIEW \(view) AS (
                    \(fields.joined(separator: ",\n\t"))
                )
                """
        default:
            return nil
        }
    }
    public func buildDropCommand(type: RecordType) -> String? {
        switch type {
        case .table(let table):
            return "DROP TABLE IF EXISTS \(table)"
        case .view(let name, _):
            return "DROP VIEW IF EXISTS \(name)"
        case .query(_):
            return nil
        }
    }
    public func buildColumnDefinition(name: String, dataType: DataType, traits: [FieldTag]) throws -> String {
        var postgresTraits: [String] = []
        if !dataType.isOptional {
            postgresTraits.append("NOT NULL")
        }
        for t in traits {
            switch t {
            case .primaryKey:
                postgresTraits.append("PRIMARY KEY")
            case .generatedAlways:
                postgresTraits.append("GENERATED ALWAYS AS IDENTITY")
            case .foreignKey(let t, let f):
                postgresTraits.append("REFERENCES \(t) (\(f))")
            case .defaultValue(let v):
                postgresTraits.append("DEFAULT \(v)")
            default:
                break
            }
        }
        
        return "\(name) \(try self.convertType(dataType)) \(postgresTraits.joined(separator: " "))".trimmingCharacters(in: .whitespaces)
    }
    public func buildColumns(columns: [Column], location: String) -> String {
        return columns.map {
            var expression = "\($0.fieldLocation ?? location).\($0.fieldName)"
            if let _expression = $0.fieldExpression {
                expression = self
                    .interpolate(components: _expression)
                    .joined(separator: "")
            }
            return "\(expression) AS \($0.displayName)"
        }.joined(separator: ", ")
    }
    public func interpolate(components: [QueryInterpolation]) -> [String] {
        return components.map {
            switch $0 {
            case .argument(let value):
                return "$\(value + 1)"
            case .field(let principal, let name):
                return "\(principal).\(name)"
            case .literal(let string):
                return "'\(string)'"
            case .raw(let string):
                return string
            }
        }
    }
    public func buildSelect(request: SelectRequest) -> String {
        let stringParams = [
            request.params.wh.map({ comps in
                let componentString = self.interpolate(components: comps).joined()
                return "WHERE \(componentString)"
            }),
            request.params.group.map({ "GROUP BY \($0)" }),
            request.params.sort.map({ "ORDER BY \($0.0) \($0.1)" }),
            request.params.limit.map({ "LIMIT \($0)" }),
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        
        var statements: [String] = []
        if !request.ctes.isEmpty {
            statements.append("WITH")
        }
        for cte in request.ctes {
            statements.append("\(cte.key) AS (\(cte.value))")
        }
        statements.append("SELECT \(request.columns) FROM \(request.location)")
        statements.append(contentsOf: request.joins)
        statements.append(stringParams)
        
        return statements.joined(separator: " ")
    }
    public func buildInsert(columnNames: String, columnValues: String, tableName: String) -> String {
        return "INSERT INTO \(tableName) (\(columnNames)) VALUES (\(columnValues)) RETURNING *"
    }
    public func buildUpdate(update: UpdateQueryParameters, tableName: String) -> String {
        var components = ["UPDATE \(tableName)"]
        if let set = update.set {
            components.append("SET \(interpolate(components: set).joined(separator: ""))")
        }
        if let wh = update.wh {
            components.append("WHERE \(interpolate(components: wh).joined(separator: ""))")
        }
        return components.joined(separator: " ")
    }
    public func buildDelete(delete: DeleteQueryParameters, tableName: String) -> String {
        var components = ["DELETE FROM \(tableName)"]
        if let wh = delete.wh {
            components.append("WHERE \(interpolate(components: wh).joined(separator: ""))")
        }
        components.append("RETURNING *")
        return components.joined(separator: " ")
    }
    public func buildJoin(join: AnyJoin) -> String {
        var joinOperator: String!
        switch join.joinType {
        case .inner:
            joinOperator = "INNER JOIN"
        }
        return "\(joinOperator!) \(join.location) \(join.joinName) ON \(join.condition)"
    }
}
