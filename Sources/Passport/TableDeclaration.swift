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
