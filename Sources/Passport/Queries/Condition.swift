import Foundation

public indirect enum Condition: Sendable {
    case and([Condition]),
         or([Condition]),
         equals(ConditionValue, ConditionValue),
         null(ConditionValue),
         notNull(ConditionValue)
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
extension Optional: IntoConditionValue {
    public func toConditionValue() -> ConditionValue {
        .constant(.null)
    }
}
