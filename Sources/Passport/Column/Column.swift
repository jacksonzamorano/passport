import Foundation

public struct Column: Sendable {
    let dataType: DataType
    
    var defaultValue: DefaultValue? = nil
    var nullability: Nullability = .nullable
    var foreignKey: ForeignKey? = nil
    
    struct ForeignKey {
        let tableName: String
        let columnName: String
    }
    
    public func nullable() -> Column {
        var column = self
        column.nullability = .nullable
        return column
    }
    public func required() -> Column {
        var column = self
        column.nullability = .notnullable
        return column
    }
    
    public func foreignKey<T: Table>(_ table: T.Type, column fk: T.Key) -> Column {
        var column = self
        column.foreignKey = .init(tableName: table.tableName, columnName: fk.rawValue)
        return column
    }
}

