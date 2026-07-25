import Foundation

public final class PostgreSQL: Sendable, Dialect {
    
    public init() {}
    
    private func joinKindToString(joinKind: Join.Kind) throws(DialectError) -> String {
        switch joinKind {
        case .inner: "INNER JOIN"
        case .left: "LEFT JOIN"
        case .right: "RIGHT JOIN"
        }
    }
    private func conditionValue(_ cv: QueryValue, argumentOffset: Int) -> String {
        switch cv {
        case .column(let cr): "\(cr.sourceName).\(cr.columnName)"
        case .constant(let cn):
            switch cn {
            case .integer(let i): "\(i)"
            case .string(let s): "'\(s)'"
            case .null: "NULL"
            }
        case .argument(let arg): "$\(arg.index+1+argumentOffset)"
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
        case .equals(let a, let b): return "\(conditionValue(a, argumentOffset: argumentOffset)) = \(conditionValue(b, argumentOffset: argumentOffset))"
        case .null(let a): return "\(conditionValue(a ,argumentOffset: argumentOffset)) IS NULL"
        case .notNull(let a): return "\(conditionValue(a, argumentOffset: argumentOffset)) IS NOT NULL"
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
        case .string: "TEXT"
        case .uuid: "UUID"
        case .integer32: "INT4"
        case .integer64: "INT8"
        case .date: "TIMESTAMP"
        case .dateWithTimezone: "TIMESTAMPTZ"
        }
    }
    private func buildColumn(_ column: Column, name: String) throws(DialectError) -> String {
        var parts: [String] = [name]
        parts.append(try convertDataType(column.dataType))
        if column.nullability == .notnullable {
            parts.append("NOT NULL")
        }
        if let foreignKey = column.foreignKey {
            parts.append("REFERENCES \(foreignKey.tableName)(\(foreignKey.columnName))")
        }
        return parts.joined(separator: " ")
    }
    
    public func buildQuery(query: Query, context: RenderContext) throws(DialectError) -> String {
        var queryComponents = [String]()
        
        if !query.base.ctes.isEmpty {
            queryComponents.append("WITH")
            var cteString = [String]()
            for cte in query.base.ctes {
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

        queryComponents.append(query.projections.map{
            "\(self.conditionValue($0.column, argumentOffset: context.argumentCount)) AS \($0.alias)"
        }.joined(separator: ", "))
        
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
            queryComponents.append("LIMIT \(conditionValue(limit, argumentOffset: context.argumentCount))")
        }
        if let offset = query.offset {
            queryComponents.append("OFFSET \(conditionValue(offset, argumentOffset: context.argumentCount))")
        }
        
        return queryComponents.joined(separator: " ")
    }
    
    public func buildInsertQuery(query: InsertQuery, context: RenderContext) throws(DialectError) -> String {
        var insertQueryComponents = ["INSERT INTO \(query.target!.realName) AS \(query.target!.alias)"]
        let insertColumnNames = query.insertFields.map {
            "\($0.column.columnName)"
        }.joined(separator: ", ")
        insertQueryComponents.append("(\(insertColumnNames)) VALUES")
        let insertColumnValues = query.insertFields.map {
            conditionValue($0.value, argumentOffset: context.argumentCount)
        }.joined(separator: ", ")
        insertQueryComponents.append("(\(insertColumnValues))")
        if query.projections.isEmpty {
            return insertQueryComponents.joined(separator: " ")
        }
        
        insertQueryComponents.append("RETURNING \(query.projections.map{ "\(conditionValue($0.column, argumentOffset: context.argumentCount)) AS \($0.alias)" }.joined(separator: ", "))")
        return insertQueryComponents.joined(separator: " ")
    }
    
    public func buildUpdateQuery(query: UpdateQuery, context: RenderContext) throws(DialectError) -> String {
        var queryComponents = ["UPDATE \(query.target!.realName) AS \(query.target!.alias)"]
        if !query.setFields.isEmpty {
            queryComponents.append("SET")
            var sets = [String]()
            for field in query.setFields {
                sets.append("\(field.column.columnName) = \(conditionValue(field.value, argumentOffset: context.argumentCount))")
            }
            queryComponents.append(sets.joined(separator: ", "))
        }
        
        if let filterString = try buildFilters(query.filters, argumentOffset: context.argumentCount) {
            queryComponents.append(filterString)
        }
        
        if query.projections.isEmpty {
            return queryComponents.joined(separator: " ")
        }
        
        let projectionsString = query.projections
            .map{ "\(conditionValue($0.column, argumentOffset: context.argumentCount)) AS \($0.alias)" }
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
        
        let projectionsString = query.projections
            .map{ "\(conditionValue($0.column, argumentOffset: context.argumentCount)) AS \($0.alias)" }
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
                \(columns.joined(separator: ",\n\t"))
            )
            """
        case .createColumn(let migration):
            return """
                ALTER TABLE \(migration.table.tableName) ADD COLUMN \(try buildColumn(migration.column, name: migration.name))
                """
        }
    }
}
