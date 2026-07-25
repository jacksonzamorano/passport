public enum DefaultValue: Sendable {
    case random
}

public enum Nullability: Sendable {
    case nullable, notnullable
    
    var optional: Bool {
        self == .nullable
    }
}

public enum DataType: Sendable {
    case string, uuid, integer, dateWithTimezone
}

public struct DeclaredType: Sendable {
    public var dataType: DataType
    public var optional: Bool
}
