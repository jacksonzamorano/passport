public enum SourceOrigin: Sendable {
    case table(TableReference),
         cte(CTEIdentifier)
    
    public var realName: String {
        switch self {
        case .table(let tr): tr.tableName
        case .cte(let cte): cte.relationName
        }
    }
    public var alias: String {
        switch self {
        case .table(let tr): tr.alias
        case .cte(let cte): cte.alias
        }
    }
}
