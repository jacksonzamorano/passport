public class SQLite: Dialect {
    /// Creates a new PostgreSQL dialect instance.
    public init() {}
    
    /// The SQL statement terminator for PostgreSQL
    public var terminator: String = ";"
    public var startTransactionMarker: String = "BEGIN;"
    public var endTransactionMarker: String = "COMMIT;"
    public func convertType(_ type: DataType) throws -> String {
        switch type {
        case .value:
            return "TEXT"
        case .optional(let o):
            return try self.convertType(o)
        case .bool:
            return "BOOLEAN"
        case .double:
            return "DOUBLE"
        case .bytes:
            return "BLOB"
        case .datetime:
            return "DATETIME"
        case .int32:
            return "INTEGER"
        case .int64:
            return "INTEGER"
        case .string:
            return "TEXT"
        default:
            throw SQLError.typeNotSupported(type)
        }
    }
    public func queryParameterToken(atIndex idx: Int) -> String {
        return "?\(idx+1)"
    }
    public func buildEnumCreateCommand(enm: any Enum.Type) -> String? {
        return nil
    }
    public func buildEnumDropCommand(enm: any Enum.Type) -> String? {
        return nil
    }
    public func buildCreateTableCommand(tableName: String, fields: [String]) -> String? {
        return """
                CREATE TABLE \(tableName) (
                    \(fields.joined(separator: ",\n\t"))
                )
                """
    }
    
    public func buildCreateViewCommand(viewName: String, query: String) -> String? {
        return "CREATE VIEW \(viewName) AS \(query)"
    }
    public func buildDropCommand(type: RecordType) -> String? {
        switch type {
        case .table(let table):
            return "DROP TABLE IF EXISTS \(table)"
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
            case .foreignKey(let ref):
                let data = ref()
                postgresTraits.append("REFERENCES \(data.entity) (\(data.column))")
            case .unique:
                postgresTraits.append("UNIQUE")
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
                    .interpolate(components: _expression, fullyQualify: true)
                    .joined(separator: "")
            }
            return "\(expression) AS \($0.displayName)"
        }.joined(separator: ", ")
    }
    public func interpolate(components: [QueryInterpolation], fullyQualify: Bool) -> [String] {
        return components.map {
            switch $0 {
            case .argument(let val):
                return queryParameterToken(atIndex: val)
            case .field(let principal, let name):
                if fullyQualify {
                    return "\(principal).\(name)"
                }
                return name
            case .qualifiedField(let principal, let name):
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
                let componentString = self.interpolate(components: comps, fullyQualify: true).joined()
                return "WHERE \(componentString)"
            }),
            request.params.group.map({ "GROUP BY \($0)" }),
            request.params.sort.map({ sorts in
                "ORDER BY \(sorts.map{ sort in "\(sort.0) \(sort.1)" }.joined(separator: ", "))"
            }),
            request.params.limit.map({ "LIMIT \($0)" }),
            request.params.skip.map({ "OFFSET \($0)" }),
        ]
            .compactMap { $0 }
            .joined(separator: " ")
        
        var statements: [String] = []
        if !request.ctes.isEmpty {
            let cteStatements = request.ctes
                .map { "\($0.0) AS (\($0.1))" }
                .joined(separator: ", ")
            statements.append("WITH \(cteStatements)")
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
            components
                .append(
                    "SET \(interpolate(components: set, fullyQualify: false).joined(separator: ""))"
                )
        }
        if let wh = update.wh {
            components
                .append(
                    "WHERE \(interpolate(components: wh, fullyQualify: false).joined(separator: ""))"
                )
        }
        components.append("RETURNING *")
        return components.joined(separator: " ")
    }
    public func buildDelete(delete: DeleteQueryParameters, tableName: String) -> String {
        var components = ["DELETE FROM \(tableName)"]
        if let wh = delete.wh {
            components
                .append(
                    "WHERE \(interpolate(components: wh, fullyQualify: false).joined(separator: ""))"
                )
        }
        components.append("RETURNING *")
        return components.joined(separator: " ")
    }
    public func buildJoin(join: JoinRequest) -> String {
        var joinOperator: String!
        switch join.joinType {
        case .inner:
            joinOperator = "INNER JOIN"
        case .left:
            joinOperator = "LEFT JOIN"
        case .right:
            joinOperator = "RIGHT JOIN"
        case .cross:
            joinOperator = "CROSS JOIN"
        }
        return "\(joinOperator!) \(join.location) \(join.joinName) ON \(join.condition)"
    }
}

