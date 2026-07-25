import Foundation

public indirect enum Condition: Sendable {
    case and([Condition]),
         or([Condition]),
         equals(QueryValue, QueryValue),
         null(QueryValue),
         notNull(QueryValue)
    
    static public func all(_ conditions: Condition...) -> Condition {
        return .and(conditions)
    }
    static public func one(_ conditions: Condition...) -> Condition {
        return .or(conditions)
    }
}

public indirect enum QueryValue: Sendable {
    case column(ColumnReference),
         constant(ConditionConstant),
         argument(ArgumentReference),
         relationColumn(RelationColumnReference)
    
    func dataType(dialect: Dialect) -> MaterializedDataType {
        switch self {
        case .column(let column): MaterializedDataType(dataType: column.dataType, optional: column.nullability.optional)
        case .constant(let constant): constant.dataType
        case .argument(let argument): .init(dataType: argument.dataType, optional: argument.optional)
        case .relationColumn(let rcr): rcr.parentValue.dataType(dialect: dialect)
        }
    }
}

public indirect enum ConditionConstant: Sendable {
    case string(String),
         integer(Int),
         null
    
    var dataType: MaterializedDataType {
        switch self {
        case .integer(_): .init(dataType: .integer, optional: false)
        case .string(_): .init(dataType: .string, optional: false)
        case .null: .init(dataType: .integer, optional: true)
        }
    }
}

public protocol IntoConditionValue {
    func toConditionValue() -> QueryValue
}
public func ==(lhs: any IntoConditionValue, rhs: any IntoConditionValue) -> Condition {
    return .equals(lhs.toConditionValue(), rhs.toConditionValue())
}
public func isNull(lhs: any IntoConditionValue) -> Condition {
    return .null(lhs.toConditionValue())
}
public func isNotNull(lhs: any IntoConditionValue) -> Condition {
    return .notNull(lhs.toConditionValue())
}
extension String: IntoConditionValue {
    public func toConditionValue() -> QueryValue {
        .constant(.string(self))
    }
}
extension Int: IntoConditionValue {
    public func toConditionValue() -> QueryValue {
        .constant(.integer(self))
    }
}
public struct Null: IntoConditionValue {
    public init() {}
    public func toConditionValue() -> QueryValue {
        return .constant(.null)
    }
}
