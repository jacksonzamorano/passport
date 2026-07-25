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
    case blob,
         string,
         integer32,
         integer64,
         uuid,
         date,
         dateWithTimezone
}

public struct DeclaredType: Sendable {
    public var dataType: DataType
    public var optional: Bool
}
