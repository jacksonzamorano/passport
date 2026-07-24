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
    public let identifier: CTEIdentifier
    public let query: Query
    
    init(identifier: CTEIdentifier, query: Query) {
        self.identifier = identifier
        self.query = query
    }
}

public final class CTESource<Values: ProjectionKey>: Sendable {
    let identifier: CTEIdentifier
    
    init(identifier: CTEIdentifier) {
        self.identifier = identifier
    }
}

public final class CTEReference<Columns: ProjectionKey>: Sendable {
    let identifier: CTEIdentifier
    let alias: String
    
    init(identifier: CTEIdentifier, alias: String) {
        self.identifier = identifier
        self.alias = alias
    }
    
    public subscript(_ key: Columns) -> RelationColumnReference {
        return .init(
            relationName: alias,
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
