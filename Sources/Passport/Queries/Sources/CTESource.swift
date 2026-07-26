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

public struct CTEPointer<Columns: ProjectionKey>: Sendable {
    let source: CTESource
    
    init(_ cte: CTESource) {
        self.source = cte
    }
}

public struct CTEReference<Columns: ProjectionKey>: Sendable {
    let identity: CTEIdentity
    let alias: String
    let query: Query
    let columnOrigin: ColumnOrigin
    
    init(_ cte: CTESource, alias: String, columnOrigin: ColumnOrigin) {
        self.identity = cte.identity
        self.alias = alias
        self.query = cte.query
        self.columnOrigin = columnOrigin
    }
    
    public subscript(_ key: Columns) -> QueryValue {
        .column(ColumnReference(
            sourceName: alias,
            columnName: key.rawValue,
            typeReference: .projection(query: query, columnName: key.rawValue),
            origin: columnOrigin
        ))
    }
}
