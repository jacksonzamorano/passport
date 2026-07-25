import Foundation

public protocol TableKey: Sendable, ProjectionKey, CaseIterable, RawRepresentable where RawValue == String {}

public protocol Table: Sendable, IntoSchemaItem {
    associatedtype Key: TableKey
    
    static var tableName: String { get }
    static func column(_ key: Key) -> Column
}
public extension Table {
    func toSchemaItem() -> SchemaItem {
        .table(self)
    }
}

public struct TableReference: Sendable {
    public let id: UUID = UUID()
    public let tableName: String
    public let alias: String
}

public struct ColumnReference: Sendable, IntoConditionValue {
    public let source: TableReference
    public let columnName: String
    public let dataType: DataType
    public let nullability: Nullability
    
    public func toConditionValue() -> QueryValue {
        .column(self)
    }
}

public final class TableSource<T: Table>: Sendable {
    let reference: TableReference
    let table: T.Type
    
    init(reference: TableReference, table: T.Type) {
        self.reference = reference
        self.table = table
    }
    
    public subscript(_ key: T.Key) -> ColumnReference {
        let col = table.column(key)
        return .init(
            source: self.reference,
            columnName: key.rawValue,
            dataType: col.dataType,
            nullability: col.nullability,
        )
    }
}
