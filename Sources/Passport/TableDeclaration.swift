import Foundation

public protocol TableKey: Sendable, ProjectionKey, CaseIterable, RawRepresentable where RawValue == String {}

public struct TableIndex<Key: TableKey>: Sendable {
    let name: String?
    let keys: [Key]
    let algorithm: IndexAlgorithm
    
    func build() -> BuiltTableIndex {
        return .init(name: name, keys: keys.map(\.rawValue), algorithm: algorithm)
    }
}
public struct BuiltTableIndex: Sendable {
    let name: String?
    let keys: [String]
    let algorithm: IndexAlgorithm
}
public enum IndexAlgorithm: Sendable {
    case auto, btree, hash
}

public protocol Table: Sendable, IntoSchemaItem {
    associatedtype Key: TableKey
    
    static var indicies: [TableIndex<Key>] { get }
    static var tableName: String { get }
    static func column(_ key: Key) -> Column
}
public extension Table {
    func toSchemaItem() -> SchemaItem {
        .table(self)
    }
    static var indicies: [TableIndex<Key>] { [] }
}
