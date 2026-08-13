import Foundation

public struct ConstraintSet: Sendable {
    fileprivate var constraints: Set<Column.Constraints> = .init()
    
    mutating func add(_ constraint: Column.Constraints) {
        self.constraints.insert(constraint)
    }
    
    public var primaryKey: Bool { constraints.contains(.primaryKey) }
    public var unique: Bool { constraints.contains(.unique) }
    public var foreignKey: Column.ForeignKey? {
        for constraint in constraints {
            if case let .foreignKey(foreignKey) = constraint {
                return foreignKey
            }
        }
        return nil
    }
}

public struct Column: Sendable {
    public enum Constraints: Sendable, Hashable, Equatable {
        case primaryKey,
             unique,
             foreignKey(ForeignKey)
    }
    public let dataType: DataType
    
    public var defaultValue: DefaultValue? = nil
    public var nullability: Nullability = .nullable
    public var constraints: ConstraintSet = .init()
    
    public struct ForeignKey: Sendable, Equatable, Hashable {
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
        column.constraints.add(.foreignKey(.init(tableName: table.tableName, columnName: fk.rawValue)))
        return column
    }
    
    public func primaryKey() -> Column {
        var column = self
        column.constraints.add(.primaryKey)
        return column
    }
    
    public func unique() -> Column {
        var column = self
        column.constraints.add(.unique)
        return column
    }
}

