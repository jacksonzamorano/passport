import Foundation

public class DeleteQueryBuilder<Returning: ProjectionKey>: BaseQuery<Returning> {
    
    var filters: [Condition] = []
    
    public func from<T: Table>(_ table: T.Type, as alias: String? = nil) -> LocalTableReference<T> {
        return bind(table, as: alias ?? table.tableName)
    }
    
    public func filter(_ build: () -> Condition) {
        filters.append(build())
    }

    
    public func returning(_ value: IntoConditionValue, as alias: Returning) {
        project(value, as: alias)
    }
    
    public func returnAll<T: Table>(from reference: TableReference<T>) where T.Key == Returning {
        for key in Returning.allCases {
            returning(reference[key], as: key)
        }
    }
    
    public func returnAll<T: Table>(from reference: LocalTableReference<T>) where T.Key == Returning {
        for key in Returning.allCases {
            returning(reference[key].column, as: key)
        }
    }
}


public protocol Delete: IntoSchemaItem {
    associatedtype ReturnType: ProjectionKey
    
    func delete(query: DeleteQueryBuilder<ReturnType>)
}

public extension Delete {
    func toSchemaItem() -> SchemaItem { .query(.delete(.init(configuration: self))) }
}

public final class DeleteQuery: BaseQueryProperties, @unchecked Sendable {
    
    public struct Sort: Sendable {
        public enum SortDirection: Sendable {
            case ascending, descending
        }
        
        public var column: ColumnReference
        public var direction: SortDirection
    }

    public let filters: [Condition]

    public init<Configuration: Delete>(configuration: Configuration) {
        let name = String(describing: type(of: configuration))
        
        let queryBuilder = DeleteQueryBuilder<Configuration.ReturnType>(name: name)
        configuration.delete(query: queryBuilder)
        
        self.filters = queryBuilder.filters
        super.init(query: queryBuilder)
    }
    
    override func validate() throws(QueryValidationError) {
        try super.validate()
        for f in filters {
            switch f {
            case .and(let ops) where ops.isEmpty, .or(let ops) where ops.isEmpty: throw .noOpCondition
            default: continue
            }
        }
    }
}
