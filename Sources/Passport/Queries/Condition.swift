import Foundation

public indirect enum Condition: Sendable {
    case and([Condition]),
         or([Condition]),
         equals(ConditionValue, ConditionValue),
         null(ConditionValue),
         notNull(ConditionValue)
    
    static public func all(_ conditions: Condition...) -> Condition {
        return .and(conditions)
    }
    static public func one(_ conditions: Condition...) -> Condition {
        return .or(conditions)
    }
}

public indirect enum ConditionValue: Sendable {
    case column(ColumnReference),
         constant(ConditionConstant),
         argument(ArgumentReference)
}

public indirect enum ConditionConstant: Sendable {
    case string(String),
         integer(Int),
         null
}

public protocol IntoConditionValue {
    func toConditionValue() -> ConditionValue
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
    public func toConditionValue() -> ConditionValue {
        .constant(.string(self))
    }
}
extension Int: IntoConditionValue {
    public func toConditionValue() -> ConditionValue {
        .constant(.integer(self))
    }
}
public struct Null: IntoConditionValue {
    public init() {}
    public func toConditionValue() -> ConditionValue {
        return .constant(.null)
    }
}
