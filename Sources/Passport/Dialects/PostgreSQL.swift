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
        
        var filters: [String] = []
        for filter in query.filters {
            let condition = try conditionToString(filter)
            filters.append(condition)
        }
        if !filters.isEmpty {
            queryComponents.append("WHERE")
            queryComponents.append(filters.joined(separator: " AND "))
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
    
}
