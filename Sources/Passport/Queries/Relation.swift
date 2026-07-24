import Foundation

public struct Relation: Sendable {
    public let relationName: String
    public let source: SourceOrigin
}

public enum Query: Sendable {
    case select(SelectQuery),
         insert(InsertQuery)
    
    var base: BaseQueryProperties {
        switch self {
        case .select(let select): select
        case .insert(let insert): insert
        }
    }
}

public final class CTE: Sendable {
    public let alias: String
    public let query: Query
    
    init(alias: String, query: Query) {
        self.alias = alias
        self.query = query
    }
}

public final class CTESource<Values: ProjectionKey>: Sendable {
    let relationName: String
    let alias: String
    
    init(relationName: String, alias: String) {
        self.relationName = relationName
        self.alias = alias
    }
}

public final class CTEReference<Columns: ProjectionKey>: Sendable {
    let identifier: CTEIdentifier
    
    init(relationName: String, alias: String) {
        self.identifier = .init(relationName: relationName, alias: alias)
    }
    
    public subscript(_ key: Columns) -> RelationColumnReference {
        return .init(
            relationName: identifier.alias,
            columnName: key.rawValue,
        )
    }
    
}

public final class CTEIdentifier: Sendable {
    let relationName: String
    let alias: String
    
    init(relationName: String, alias: String) {
        self.relationName = relationName
        self.alias = alias
    }
}


public struct RelationColumnReference: Sendable, IntoConditionValue {
    let relationName: String
    let columnName: String
    
    public func toConditionValue() -> QueryValue {
        return .relationColumn(self)
    }
}
