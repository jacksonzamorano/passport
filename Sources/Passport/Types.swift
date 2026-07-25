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
    case string, uuid, integer
}

public struct MaterializedDataType: Sendable {
    var dataType: DataType
    var optional: Bool
}
