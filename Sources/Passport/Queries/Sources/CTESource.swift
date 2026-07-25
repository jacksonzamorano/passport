import Foundation

public struct CTEIdentity: Hashable, Sendable {
    let id: UUID
    public let name: String
}

public struct CTESource: Sendable {
    public let identity: CTEIdentity
    public let query: Query
    
    init(name: String, query: Query) {
        self.identity = .init(id: UUID(), name: name)
        self.query = query
    }
}

public struct CTEReference<Columns: ProjectionKey>: Sendable {
    let identity: CTEIdentity
    let query: Query
    
    init(_ cte: CTESource) {
        self.identity = cte.identity
        self.query = cte.query
    }
    
    public subscript(_ key: Columns) -> QueryValue {
        .column(ColumnReference(
            sourceName: identity.name,
            columnName: key.rawValue,
            typeReference: .projection(query: query, columnName: key.rawValue)
        ))
    }
}
