public enum SourceOrigin: Sendable {
    case table(TableReference),
         cte(CTEIdentifier, alias: String)
    
    public var realName: String {
        switch self {
        case .table(let tr): tr.tableName
        case .cte(let cte, _): cte.name
        }
    }
    public var alias: String {
        switch self {
        case .table(let tr): tr.alias
        case .cte(_, let alias): alias
        }
    }
}
