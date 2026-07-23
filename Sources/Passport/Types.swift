public enum DefaultValue: Sendable {
    case random
}

public enum Nullability: Sendable {
    case nullable, notnullable
}

public enum DataType: Sendable {
    case string, uuid
}
