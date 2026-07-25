public indirect enum SourceOrigin: Sendable {
    case table(TableSource),
         cte(CTESource)
    
    public var realName: String {
        switch self {
        case .table(let tr): tr.table.tableName
        case .cte(let ct): ct.identity.name
        }
    }
    public var alias: String {
        switch self {
        case .table(let tr): tr.alias
        case .cte(let ct): ct.identity.name
        }
    }
}
