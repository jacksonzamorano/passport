extension Column {
    public static func int32() -> Self {
        .init(dataType: .integer32)
    }
    public static func int64() -> Self {
        .init(dataType: .integer64)
    }
    public static func float32() -> Self {
        .init(dataType: .float32)
    }
    public static func float64() -> Self {
        .init(dataType: .float64)
    }
}
