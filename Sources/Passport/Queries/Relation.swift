import Foundation

public struct Relation: Sendable {
    public let relationName: String
    public let source: SourceOrigin
}

public enum Query: Sendable {
    case select(SelectQuery),
         insert(InsertQuery),
         update(UpdateQuery)
    
    var base: BaseQueryProperties {
        switch self {
        case .select(let select): select
        case .insert(let insert): insert
        case .update(let update): update
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
    let columnMap: [Values : QueryValue]

    init(identifier: CTEIdentifier, columnMap: [Values : QueryValue]) {
        self.identifier = identifier
        self.columnMap = columnMap
    }
}

public final class CTEReference<Columns: ProjectionKey>: Sendable {
    let identifier: CTEIdentifier
    let alias: String
    let columnMap: [Columns : QueryValue]
    
    init(
        source: CTESource<Columns>,
        alias: String,
    ) {
        self.identifier = source.identifier
        self.alias = alias
        self.columnMap = source.columnMap
    }
    
    public subscript(_ key: Columns) -> RelationColumnReference {
        return .init(
            relationName: alias,
            columnName: key.rawValue,
            parentValue: columnMap[key]!
        )
    }
    
}

public final class CTEIdentifier: Sendable, Equatable {
    let id: UUID = UUID()
    let name: String
    
    public static func ==(lhs: CTEIdentifier, rhs: CTEIdentifier) -> Bool {
        lhs.id == rhs.id
    }
    
    init(name: String) {
        self.name = name
    }
}


public struct RelationColumnReference: Sendable, IntoConditionValue {
    let relationName: String
    let columnName: String
    let parentValue: QueryValue
    
    public func toConditionValue() -> QueryValue {
        return .relationColumn(self)
    }
}
