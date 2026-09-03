public enum DefaultValue: Sendable {
    case number(Int), boolean(Bool), string(String)
}

public enum Nullability: Sendable {
    case nullable, notnullable
    
    var optional: Bool {
        self == .nullable
    }
}

public enum DataType: Sendable {
    case blob,
         boolean,
         string,
         integer32,
         integer64,
         float32,
         float64,
         uuid,
         date,
         dateWithTimezone
    
    var isNumeric: Bool {
        switch self {
        case .integer32, .integer64, .float32, .float64: true
        default: false
        }
    }
    var isFloat: Bool {
        switch self {
        case .float32, .float64: true
        default: false
        }
    }
    var isInteger: Bool {
        switch self {
        case .integer32, .integer64: true
        default: false
        }
    }
}

public struct DeclaredType: Sendable {
    public var dataType: DataType
    public var optional: Bool
}
