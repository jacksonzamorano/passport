import Foundation

public final class PostgreSQL: Sendable, Dialect {
    
    static let keywords: [String] = [
        "select",
        "insert",
        "update",
        "delete",
        "returning"
    ]
    private func checkKeyword(_ val: String, context: String) throws(DialectError) {
        if Self.keywords.contains(val.lowercased()) {
            throw .init(code: .keywordViolated, context: "\(context): \"\(val)\"")
        }
    }
    
    public init() {}
    
    private func joinKindToString(joinKind: Join.Kind) throws(DialectError) -> String {
        switch joinKind {
        case .inner: "INNER JOIN"
        case .left: "LEFT JOIN"
        case .right: "RIGHT JOIN"
        }
    }
    private func conditionValue(_ cv: QueryValue, argumentOffset: Int, fullyQualifyName: Bool = true) throws(DialectError) -> String {
        switch cv {
        case .column(let cr): fullyQualifyName ? "\"\(cr.sourceName)\".\"\(cr.columnName)\"" : "\"\(cr.columnName)\""
        case .constant(let cn):
            switch cn {
            case .integer(let i): "\(i)"
            case .string(let s): "'\(s.replacingOccurrences(of: "'", with: "\\'"))'"
            case .boolean(let b): "\(b ? "TRUE" : "FALSE")"
            }
        case .argument(let arg): "$\(arg.index+1+argumentOffset)"
        case .function(let fun): try functionDefinition(fun, argumentOffset: argumentOffset)
        }
    }
    
    private func arithmeticValue(l: QueryValue, r: QueryValue, argumentOffset: Int, op: (String, String, String) -> String) throws(DialectError) -> String {
        let lIsNumeric = try l.isNumeric(in: self)
        let rIsNumeric = try r.isNumeric(in: self)
        if !lIsNumeric || !rIsNumeric {
            throw .init(code: .functionArgumentsNotValid, context: "Using arithmetic is invalid with non-numeric columns.")
        }
        let (lFloating, rFloating) = (try l.isFloat(in: self), try r.isFloat(in: self))
        let promotedToReal = lFloating || rFloating
        let lCV = try conditionValue(l, argumentOffset: argumentOffset)
        let rCV = try conditionValue(r, argumentOffset: argumentOffset)
        return op(lCV, rCV, promotedToReal ? "::double precision" : "")
    }
    private func arithmeticType(l: QueryValue, r: QueryValue) throws(DialectError) -> DeclaredType {
        let lDataType = try l.dataType(dialect: self)
        let rDataType = try r.dataType(dialect: self)
        let (lFloating, rFloating) = (lDataType.dataType.isFloat, rDataType.dataType.isFloat)
        let promotedToReal = lFloating || rFloating
        let dt: DataType = promotedToReal ? .float64 : .integer64
        return .init(dataType: dt, optional: lDataType.optional || rDataType.optional)
    }
    
    public func typeFor(function fn: QueryFunction) throws(DialectError) -> DeclaredType {
        switch fn {
        case .lower(let value):
            let value = try value.dataType(dialect: self)
            if value.dataType == .string {
                return .init(dataType: .string, optional: value.optional)
            }
        case .upper(let value):
            let value = try value.dataType(dialect: self)
            if value.dataType == .string {
                return .init(dataType: .string, optional: value.optional)
            }
        case .add(let l, let r):
            return try arithmeticType(l: l, r: r)
        case .subtract(let l, let r):
            return try arithmeticType(l: l, r: r)
        case .multiply(let l, let r):
            return try arithmeticType(l: l, r: r)
        case .divide(let l, let r):
            return try arithmeticType(l: l, r: r)
        }
        throw .init(code: .dataTypeNotSupported, context: "")
    }
    private func functionDefinition(_ fn: QueryFunction, argumentOffset: Int) throws(DialectError) -> String {
        switch fn {
        case .lower(let value): "LOWER(\(try conditionValue(value, argumentOffset: argumentOffset)))"
        case .upper(let value): "UPPER(\(try conditionValue(value, argumentOffset: argumentOffset)))"
        case .add(let l, let r): try arithmeticValue(l: l, r: r, argumentOffset: argumentOffset) { l, r, t in
            "(\(l) + \(r))\(t)"
        }
        case .subtract(let l, let r):  try arithmeticValue(l: l, r: r, argumentOffset: argumentOffset) { l, r, t in
            "(\(l) - \(r))\(t)"
        }
        case .multiply(let l, let r):  try arithmeticValue(l: l, r: r, argumentOffset: argumentOffset) { l, r, t in
            "(\(l) * \(r))\(t)"
        }
        case .divide(let l, let r):  try arithmeticValue(l: l, r: r, argumentOffset: argumentOffset) { l, r, t in
            "(\(l) / \(r))\(t)"
        }
        }
    }
    
    private func sortDirection(_ dir: SelectQuery.Sort.SortDirection) -> String {
        switch dir {
        case .ascending: "ASC"
        case .descending: "DESC"
        }
    }
    private func conditionToString(_ condition: Condition, argumentOffset: Int) throws(DialectError) -> String {
        switch condition {
        case .and(let conditions):
            var subconditions: [String] = []
            for condition in conditions {
                subconditions.append(try conditionToString(condition, argumentOffset: argumentOffset))
            }
            return "(\(subconditions.joined(separator: " AND ")))"
        case .or(let conditions):
            var subconditions: [String] = []
            for condition in conditions {
                subconditions.append(try conditionToString(condition, argumentOffset: argumentOffset))
            }
            return "(\(subconditions.joined(separator: " OR ")))"
        case .equals(let a, let b): return "\(try conditionValue(a, argumentOffset: argumentOffset)) = \(try conditionValue(b, argumentOffset: argumentOffset))"
        case .gte(let a, let b): return "\(try conditionValue(a, argumentOffset: argumentOffset)) >= \(try conditionValue(b, argumentOffset: argumentOffset))"
        case .lte(let a, let b): return "\(try conditionValue(a, argumentOffset: argumentOffset)) <= \(try conditionValue(b, argumentOffset: argumentOffset))"
        case .greaterThan(let a, let b):
            return "\(try conditionValue(a, argumentOffset: argumentOffset)) > \(try conditionValue(b, argumentOffset: argumentOffset))"
        case .lessThan(let a, let b):
            return "\(try conditionValue(a, argumentOffset: argumentOffset)) < \(try conditionValue(b, argumentOffset: argumentOffset))"
        case .null(let a): return "\(try conditionValue(a ,argumentOffset: argumentOffset)) IS NULL"
        case .notNull(let a): return "\(try conditionValue(a, argumentOffset: argumentOffset)) IS NOT NULL"
        }
    }
    private func sourceToString(_ source: SourceOrigin) -> String {
        switch source {
        case .cte(let cte): cte.identity.name
        case .table(let table): table.table.tableName
        }
    }
    private func buildFilters(_ filters: [Condition], argumentOffset: Int) throws(DialectError) -> String? {
        var filterStrings: [String] = []
        for filter in filters {
            let condition = try conditionToString(filter, argumentOffset: argumentOffset)
            filterStrings.append(condition)
        }
        if !filterStrings.isEmpty {
            return "WHERE \(filterStrings.joined(separator: " AND "))"
        }
        return nil
    }
    private func convertDataType(_ dataType: DataType) throws(DialectError) -> String {
        switch dataType {
        case .blob: "BYTEA"
        case .boolean: "BOOLEAN"
        case .string: "TEXT"
        case .uuid: "UUID"
        case .integer32: "INT4"
        case .integer64: "INT8"
        case .float32: "REAL"
        case .float64: "DOUBLE PRECISION"
        case .date: "TIMESTAMP"
        case .dateWithTimezone: "TIMESTAMPTZ"
        }
    }
    private func buildColumn(_ column: Column, name: String) throws(DialectError) -> String {
        var parts: [String] = ["\"\(name)\""]
        parts.append(try convertDataType(column.dataType))
        if column.nullability == .notnullable {
            parts.append("NOT NULL")
        }
        if column.constraints.primaryKey {
            parts.append("PRIMARY KEY")
        }
        if let defaultValue = column.defaultValue {
            parts.append("DEFAULT")
            switch defaultValue {
            case .number(let num): parts.append("\(num)")
            case .boolean(let bool): parts.append(bool ? "TRUE" : "FALSE")
            }
        }
        if column.constraints.unique {
            parts.append("UNIQUE")
        }
        if let foreignKey = column.constraints.foreignKey {
            parts.append("REFERENCES \"\(foreignKey.tableName)\"(\"\(foreignKey.columnName)\")")
        }
        return parts.joined(separator: " ")
    }
    
    public func buildQuery(query: Query, context: RenderContext) throws(DialectError) -> String {
        try checkKeyword(query.base.identity.queryName, context: "Query name")
        try checkKeyword(query.base.identity.queryReturnTypeName, context: "Query return type")

        var queryComponents = [String]()
        
        if !query.base.ctes.isEmpty {
            queryComponents.append("WITH")
            var cteString = [String]()
            for (idx, cte) in query.base.ctes.enumerated() {
                try checkKeyword(cte.identity.name, context: "CTE #\(idx+1)")
                cteString.append("\(cte.identity.name) AS (\(try self.buildQuery(query: cte.query, context: context)))")
            }
            queryComponents.append(cteString.joined(separator: ", "))
        }
        
        
        let inner = switch query {
        case .select(let select): try buildSelectQuery(query: select, context: context)
        case .insert(let insert): try buildInsertQuery(query: insert, context: context)
        case .update(let update): try buildUpdateQuery(query: update, context: context)
        case .delete(let delete): try buildDeleteQuery(query: delete, context: context)
        }
        context.arguments.append(contentsOf: query.base.arguments)
        queryComponents.append(inner)

        return queryComponents.joined(separator: " ")
    }
    
    public func buildSelectQuery(query: SelectQuery, context: RenderContext) throws(DialectError) -> String {
        var queryComponents = ["SELECT"]

        var projectionString: [String] = []
        for projection in query.projections {
            projectionString.append("\(try conditionValue(projection.column, argumentOffset: context.argumentCount)) AS \"\(projection.alias)\"")
        }
        queryComponents.append(projectionString.joined(separator: ", "))
        
        queryComponents.append("FROM \(query.target!.realName) AS \(query.target!.alias)")
        
        for join in query.joins {
            let joinKind = try joinKindToString(joinKind: join.kind)
            let joinCondition = try conditionToString(join.condition, argumentOffset: context.argumentCount)
            let str = "\(joinKind) \(self.sourceToString(join.source)) AS \(join.alias) ON \(joinCondition)"
            queryComponents.append(str)
        }
        
        if let filterString = try buildFilters(query.filters, argumentOffset: context.argumentCount) {
            queryComponents.append(filterString)
        }
        
        if !query.sorts.isEmpty {
            queryComponents.append("ORDER BY")
            queryComponents.append(query.sorts.map{
                "\($0.column.sourceName).\($0.column.columnName) \(sortDirection($0.direction))"
            }.joined(separator: ", "))
        }
        
        if let limit = query.limit {
            queryComponents.append("LIMIT \(try conditionValue(limit, argumentOffset: context.argumentCount))")
        }
        if let offset = query.offset {
            queryComponents.append("OFFSET \(try conditionValue(offset, argumentOffset: context.argumentCount))")
        }
        
        return queryComponents.joined(separator: " ")
    }
    
    public func buildInsertQuery(query: InsertQuery, context: RenderContext) throws(DialectError) -> String {
        var insertQueryComponents = ["INSERT INTO \(query.target!.realName) AS \(query.target!.alias)"]
        let insertColumnNames = query.insertFields.map {
            "\($0.column.columnName)"
        }.joined(separator: ", ")
        insertQueryComponents.append("(\(insertColumnNames)) VALUES")
        
        var insertColumnValues: [String] = []
        for field in query.insertFields {
            let fValue: String
            if let fieldValue = field.value {
                fValue = try conditionValue(fieldValue, argumentOffset: context.argumentCount)
            } else {
                fValue = "NULL"
            }
            insertColumnValues.append(fValue)
        }
        insertQueryComponents.append("(\(insertColumnValues.joined(separator: ", ")))")
        if query.projections.isEmpty {
            return insertQueryComponents.joined(separator: " ")
        }
        
        var projections: [String] = []
        for projection in query.projections {
            projections.append("\(try conditionValue(projection.column, argumentOffset: context.argumentCount)) AS \(projection.alias)")
        }
        
        insertQueryComponents.append("RETURNING \(projections.joined(separator: ", "))")
        return insertQueryComponents.joined(separator: " ")
    }
    
    public func buildUpdateQuery(query: UpdateQuery, context: RenderContext) throws(DialectError) -> String {
        var queryComponents = ["UPDATE \(query.target!.realName) AS \(query.target!.alias)"]
        if !query.setFields.isEmpty {
            queryComponents.append("SET")
            var sets = [String]()
            for field in query.setFields {
                let fValue: String
                if let fieldValue = field.value {
                    fValue = try conditionValue(fieldValue, argumentOffset: context.argumentCount)
                } else {
                    fValue = "NULL"
                }
                sets.append("\(field.column.columnName) = \(fValue)")
            }
            queryComponents.append(sets.joined(separator: ", "))
        }
        
        if let filterString = try buildFilters(query.filters, argumentOffset: context.argumentCount) {
            queryComponents.append(filterString)
        }
        
        if query.projections.isEmpty {
            return queryComponents.joined(separator: " ")
        }
        
        var projectionsString: [String] = []
        for projection in query.projections {
            projectionsString.append("\(try conditionValue(projection.column, argumentOffset: context.argumentCount)) AS \(projection.alias)")
        }
        queryComponents.append("RETURNING \(projectionsString.joined(separator: ", "))")
        
        return queryComponents.joined(separator: " ")
    }
    
    public func buildDeleteQuery(query: DeleteQuery, context: RenderContext) throws(DialectError) -> String {
        var queryComponents = ["DELETE FROM \(query.target!.realName) AS \(query.target!.alias)"]

        if let filterString = try buildFilters(query.filters, argumentOffset: context.argumentCount) {
            queryComponents.append(filterString)
        }
        
        if query.projections.isEmpty {
            return queryComponents.joined(separator: " ")
        }
        
        var projectionsString: [String] = []
        for projection in query.projections {
            projectionsString.append("\(try conditionValue(projection.column, argumentOffset: context.argumentCount)) AS \(projection.alias)")
        }
        queryComponents.append("RETURNING \(projectionsString.joined(separator: ", "))")
        
        return queryComponents.joined(separator: " ")
    }
    
    public func buildMigrationStep(step: MigrationStep) throws(DialectError) -> String {
        switch step {
        case .createTable(let migration):
            var columns: [String] = []
            for column in migration.columns {
                columns.append(try buildColumn(column.column, name: column.name))
            }
            
            return """
            CREATE TABLE \(migration.table.tableName) (
              \(columns.joined(separator: ",\n  "))
            );
            """
        case .createColumn(let migration):
            return """
                ALTER TABLE \(migration.table.tableName) ADD COLUMN \(try buildColumn(migration.column, name: migration.name));
                """
        case .createIndex(let index):
            var indexString = ["CREATE INDEX"]
            indexString.append(index.name)
            indexString.append("ON \(index.tableName)")
            switch index.algorithm {
            case .auto:
                break
            case .btree:
                indexString.append("WITH btree")
            case .hash:
                indexString.append("WITH hash")
            }
            
            var fieldString: [String] = []
            for field in index.fields {
                let value = try conditionValue(field, argumentOffset: 0, fullyQualifyName: false)
                fieldString.append(value)
            }
            indexString.append("(\(fieldString.joined(separator: ", ")))")
            
            if !index.filters.isEmpty {
                indexString.append("WHERE")
                var conditions = [String]()
                for filter in index.filters {
                    let condition = try conditionToString(filter, argumentOffset: 0)
                    conditions.append(condition)
                }
                indexString.append(conditions.joined(separator: " AND "))
            }
            
            return indexString.joined(separator: " ")
        }
    }
}
