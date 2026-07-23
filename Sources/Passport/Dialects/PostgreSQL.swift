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
    
    private func conditionValue(_ cv: ConditionValue) -> String {
        switch cv {
        case .column(let cr): "\(cr.source.alias).\(cr.columnName)"
        case .constant(let cn):
            switch cn {
            case .integer(let i): "\(i)"
            case .string(let s): "\"\(s)\""
            case .null: "NULL"
            }
        case .argument(let arg): "$\(arg.index+1)"
        }
    }
    
    private func conditionToString(_ condition: Condition) throws(DialectError) -> String {
        switch condition {
        case .and(let conditions):
            var subconditions: [String] = []
            for condition in conditions {
                subconditions.append(try conditionToString(condition))
            }
            return subconditions.joined(separator: " AND ")
        case .or(let conditions):
            var subconditions: [String] = []
            for condition in conditions {
                subconditions.append(try conditionToString(condition))
            }
            return subconditions.joined(separator: " OR ")
        case .equals(let a, let b): return "\(conditionValue(a)) = \(conditionValue(b))"
        case .null(let a): return "\(conditionValue(a)) IS NULL"
        case .notNull(let a): return "\(conditionValue(a)) IS NOT NULL"
        }
    }
    
    private func buildFilters(_ filters: [Condition]) throws(DialectError) -> String? {
        var filterStrings: [String] = []
        for filter in filters {
            let condition = try conditionToString(filter)
            filterStrings.append(condition)
        }
        if !filterStrings.isEmpty {
            return "WHERE \(filterStrings.joined(separator: " AND "))"
        }
        return nil
    }
    
    public func buildSelectQuery(query: SelectQuery) throws(DialectError) -> String {
        var queryComponents = ["SELECT"]
        queryComponents.append(query.fields.map{
            "\($0.column.source.alias).\($0.column.columnName) AS \($0.alias)"
        }.joined(separator: ", "))
        queryComponents.append("FROM \(query.target.tableName)")
        for join in query.joins {
            let joinKind = try joinKindToString(joinKind: join.kind)
            let joinCondition = try conditionToString(join.condition)
            let str = "\(joinKind) \(join.foreignName) AS \(join.alias) ON \(joinCondition)"
            queryComponents.append(str)
        }
        
        if let filterString = try buildFilters(query.filters) {
            queryComponents.append(filterString)
        }
        
        return queryComponents.joined(separator: " ")
    }
    
    public func buildInsertQuery(query: InsertQuery) throws(DialectError) -> String {
        var queryComponents = ["INSERT INTO \(query.target.tableName)"]
        let insertColumnNames = query.fields.map {
            "\($0.column.columnName)"
        }.joined(separator: ", ")
        queryComponents.append("(\(insertColumnNames)) VALUES")
        let insertColumnValues = query.fields.map {
            conditionValue($0.value)
        }.joined(separator: ", ")
        queryComponents.append("(\(insertColumnValues))")
        return queryComponents.joined(separator: " ")
    }
    
    public func buildUpdateQuery(query: UpdateQuery) throws(DialectError) -> String {
        var queryComponents = ["UPDATE \(query.target.tableName)"]
        if !query.fields.isEmpty {
            queryComponents.append("SET")
            var sets = [String]()
            for field in query.fields {
                sets.append("\(field.column.columnName) = \(conditionValue(field.value))")
            }
            queryComponents.append(sets.joined(separator: ", "))
        }
        
        if let from = query.from {
            queryComponents.append("FROM \(from.foreignName) AS \(from.alias)")
        }
        
        if let filterString = try buildFilters(query.filters) {
            queryComponents.append(filterString)
        }
        
        return queryComponents.joined(separator: " ")
    }
}
