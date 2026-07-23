import Foundation

public struct Column: Sendable {
    let dataType: DataType
    
    var defaultValue: DefaultValue? = nil
    var nullability: Nullability = .nullable
    var foreignKey: any Table? = nil
    
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
}

