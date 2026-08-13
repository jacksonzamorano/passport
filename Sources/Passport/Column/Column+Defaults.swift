extension Column {
    public func withDefault(_ dv: DefaultValue) -> Column {
        var column = self
        column.defaultValue = dv
        return column
    }
}
