import Foundation

public class IndexBuilder<Base: Table> {
    
    var name: String
    var algorithm: IndexAlgorithm = .auto
    var filters: [Condition] = []
    var joins: [Join] = []
    var sorts: [IndexDefinition.Sort] = []
    var fields: [QueryValue] = []
    
    init(name: String) {
        self.name = name
    }
    
    public func table() -> LocalTableReference<Base> {
        return .init(.init(alias: Base.tableName, table: Base.self))
    }
    
    public func algorithm(_ algo: IndexAlgorithm) {
        self.algorithm = algo
    }
    
    public func filter(_ build: () -> Condition) {
        filters.append(build())
    }
    
    public func sort(_ column: LocalColumnReference, direction: IndexDefinition.Sort.SortDirection) {
        self.sorts.append(.init(column: column.column, direction: direction))
    }
    
    public func index(_ column: any IntoConditionValue) {
        self.fields.append(column.toConditionValue())
    }
}


public protocol Index  {
    associatedtype OnTable: Table
    
    func index(query: IndexBuilder<OnTable>)
}

public final class IndexDefinition: @unchecked Sendable {
    
    public struct Sort: Sendable {
        public enum SortDirection: Sendable {
            case ascending, descending
        }
        
        public var column: ColumnReference
        public var direction: SortDirection
    }

    public let tableName: String
    public let name: String
    public let algorithm: IndexAlgorithm
    public let fields: [QueryValue]
    public let filters: [Condition]
    public let joins: [Join]
    public let sorts: [Sort]

    public init<Configuration: Index>(configuration: Configuration) {
        let name = String(describing: type(of: configuration))
        
        let queryBuilder = IndexBuilder<Configuration.OnTable>(name: name)
        configuration.index(query: queryBuilder)
        
        self.tableName = Configuration.OnTable.tableName
        self.name = queryBuilder.name
        self.algorithm = queryBuilder.algorithm
        self.filters = queryBuilder.filters
        self.joins = queryBuilder.joins
        self.sorts = queryBuilder.sorts
        self.fields = queryBuilder.fields
    }
}
