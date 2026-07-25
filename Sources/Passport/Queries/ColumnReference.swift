import Foundation

public enum ColumnTypeReference: Sendable {
    case declared(DeclaredType),
         projection(query: Query, columnName: String)
    
    public func resolve(dialect: any Dialect) -> DeclaredType {
        switch self {
        case .declared(let declared): return declared
        case .projection(query: let query, columnName: let qn): return query.base[qn].column.dataType(dialect: dialect)
        }
    }
}

public struct ColumnReference: Sendable, IntoConditionValue {
    public let sourceName: String
    public let columnName: String
    public let typeReference: ColumnTypeReference
    
    public func toConditionValue() -> QueryValue {
        .column(self)
    }
}
