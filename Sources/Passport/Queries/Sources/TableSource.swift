import Foundation

public struct TableSource: Sendable {
    public let id: UUID = UUID()
    public let alias: String
    public let table: any Table.Type
}

public struct LocalColumnReference<T: Table>: Sendable {
    public let column: ColumnReference
}

public struct TableReference<T: Table> {
    let alias: String
    let table: T.Type
    
    init(_ source: TableSource) {
        self.alias = source.alias
        self.table = T.self
    }
    
    public subscript(_ key: T.Key) -> ColumnReference {
        let column = table.column(key)
        return ColumnReference(
            sourceName: alias,
            columnName: key.rawValue,
            typeReference: .declared(.init(dataType: column.dataType, optional: column.nullability.optional))
        )
    }
    public subscript(_ key: T.Key) -> LocalColumnReference<T> {
        return LocalColumnReference(
            column: self[key]
        )
    }
}
