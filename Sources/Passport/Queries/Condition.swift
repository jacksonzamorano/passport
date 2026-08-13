import Foundation

public indirect enum Condition: Sendable {
    case and([Condition]),
         or([Condition]),
         equals(QueryValue, QueryValue),
         greaterThan(QueryValue, QueryValue),
         lessThan(QueryValue, QueryValue),
         gte(QueryValue, QueryValue),
         lte(QueryValue, QueryValue),
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
         function(QueryFunction)
    
    func dataType(dialect: Dialect) throws(DialectError) -> DeclaredType {
        switch self {
        case .column(let column): try column.typeReference.resolve(dialect: dialect)
        case .constant(let constant): constant.dataType
        case .argument(let argument): .init(dataType: argument.dataType, optional: argument.optional)
        case .function(let function): try dialect.typeFor(function: function)
        }
    }
    
    func isType(type t: DataType, in dialect: Dialect, required: Bool = false) throws(DialectError) -> Bool {
        let dt = try dataType(dialect: dialect)
        return dt.dataType == t && (!required || !dt.optional)
    }
    func isInteger(in dialect: Dialect, required: Bool = false) throws(DialectError) -> Bool {
        let dt = try dataType(dialect: dialect)
        return (dt.dataType == .integer32 || dt.dataType == .integer64) && (!required || !dt.optional)
    }
    func isFloat(in dialect: Dialect, required: Bool = false) throws(DialectError) -> Bool {
        let dt = try dataType(dialect: dialect)
        return (dt.dataType == .float32 || dt.dataType == .float64) && (!required || !dt.optional)
    }
    func isNumeric(in dialect: Dialect) throws(DialectError) -> Bool {
        let dt = try dataType(dialect: dialect)
        return [.integer32, .integer64, .float32, .float64].contains(dt.dataType)
    }
}

public func && (lhs: Condition, rhs: Condition)  -> Condition {
    return .and([lhs, rhs])
}

public indirect enum QueryFunction: Sendable, IntoConditionValue {
    case lower(QueryValue),
         upper(QueryValue),
         add(QueryValue, QueryValue),
         subtract(QueryValue, QueryValue),
         multiply(QueryValue, QueryValue),
         divide(QueryValue, QueryValue)

    var name: String {
        switch self {
        case .lower(_): "lower"
        case .upper(_): "upper"
        case .add(_, _): "add"
        case .subtract(_, _): "subtract"
        case .multiply(_, _): "multiply"
        case .divide(_, _): "divide"
        }
    }
    
    public func toConditionValue() -> QueryValue {
        .function(self)
    }
}
public func +(lhs: any IntoConditionValue, rhs: any IntoConditionValue) -> QueryFunction {
    .add(lhs.toConditionValue(), rhs.toConditionValue())
}

public indirect enum ConditionConstant: Sendable {
    case string(String),
         integer(Int),
         boolean(Bool)
    
    var dataType: DeclaredType {
        switch self {
        case .integer(_): .init(dataType: .integer64, optional: false)
        case .string(_): .init(dataType: .string, optional: false)
        case .boolean(_): .init(dataType: .boolean, optional: false)
        }
    }
}

public protocol IntoConditionValue {
    func toConditionValue() -> QueryValue
}
extension QueryValue: IntoConditionValue {
    public func toConditionValue() -> QueryValue { self }
}
extension IntoConditionValue {
    public func isNull() -> Condition { .null(self.toConditionValue()) }
    public func notNull() -> Condition { .notNull(self.toConditionValue()) }
}

public func ==(lhs: any IntoConditionValue, rhs: any IntoConditionValue) -> Condition {
    return .equals(lhs.toConditionValue(), rhs.toConditionValue())
}
public func >=(lhs: any IntoConditionValue, rhs: any IntoConditionValue) -> Condition {
    return .gte(lhs.toConditionValue(), rhs.toConditionValue())
}
public func <=(lhs: any IntoConditionValue, rhs: any IntoConditionValue) -> Condition {
    return .lte(lhs.toConditionValue(), rhs.toConditionValue())
}
public func >(lhs: any IntoConditionValue, rhs: any IntoConditionValue) -> Condition {
    return .greaterThan(lhs.toConditionValue(), rhs.toConditionValue())
}
public func <(lhs: any IntoConditionValue, rhs: any IntoConditionValue) -> Condition {
    return .lessThan(lhs.toConditionValue(), rhs.toConditionValue())
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
extension Bool: IntoConditionValue {
    public func toConditionValue() -> QueryValue {
        .constant(.boolean(self))
    }
}
