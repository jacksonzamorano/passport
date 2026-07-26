import Foundation

public class SelectQueryBuilder<Returning: ProjectionKey>: BaseQuery<Returning> {
    
    var filters: [Condition] = []
    var joins: [Join] = []
    var sorts: [SelectQuery.Sort] = []
    
    var limit: QueryValue?
    var offset: QueryValue?
    
    public func from<T: Table>(_ table: T.Type, as alias: String? = nil) -> LocalTableReference<T> {
        return bind(table, as: alias)
    }
    public func from<Query: Insert>(_ query: Query, as alias: String? = nil) -> CTEReference<Query.ReturnType> {
        return bind(query, as: alias)
    }
    public func from<Query: Update>(_ query: Query, as alias: String? = nil) -> CTEReference<Query.ReturnType> {
        return bind(query, as: alias)
    }
    
    public func filter(_ build: () -> Condition) {
        filters.append(build())
    }
    
    public func limit(_ limit: IntoConditionValue) {
        self.limit = limit.toConditionValue()
    }
    
    public func offset(_ offset: IntoConditionValue) {
        self.offset = offset.toConditionValue()
    }
    
    public func sort(_ column: ColumnReference, direction: SelectQuery.Sort.SortDirection) {
        self.sorts.append(.init(column: column, direction: direction))
    }
    public func sort(_ column: LocalColumnReference, direction: SelectQuery.Sort.SortDirection) {
        self.sorts.append(.init(column: column.column, direction: direction))
    }
    
    public func join<T: Table>(foreign: T.Type, as alias: String, kind: Join.Kind, _ build: (TableReference<T>) -> Condition) -> TableReference<T> {
        let source = TableSource(alias: alias, table: foreign)
        
        let reference = TableReference<T>(source)
        let condition = build(reference)
        joins.append(
            Join(
                kind: kind,
                alias: alias,
                source: .table(source),
                condition: condition
            )
        )
        
        return reference
    }
    
    public func join<K: ProjectionKey>(
        cte: CTEPointer<K>,
        as alias: String,
        kind: Join.Kind,
        _ build: (CTEReference<K>) -> Condition
    ) -> CTEReference<K> {
        let reference = CTEReference<K>(cte.source, alias: alias)
        let condition = build(reference)
        joins.append(
            Join(
                kind: kind,
                alias: alias,
                source: .cte(cte.source),
                condition: condition
            )
        )
        
        return reference
    }
    
    public func select(_ value: IntoConditionValue, as alias: Returning) {
        project(value, as: alias)
    }
    
    public func selectAll<T: Table>(from tableSource: TableReference<T>) where T.Key == Returning {
        for key in Returning.allCases {
            select(tableSource[key], as: key)
        }
    }
    
    public func selectAll<T: Table>(from tableSource: LocalTableReference<T>) where T.Key == Returning {
        for key in Returning.allCases {
            select(tableSource[key], as: key)
        }
    }
}


public protocol Select: IntoSchemaItem {
    associatedtype ReturnType: ProjectionKey
    
    func select(query: SelectQueryBuilder<ReturnType>)
}

public extension Select {
    func toSchemaItem() -> SchemaItem { .query(.select(.init(configuration: self))) }
}

public final class SelectQuery: BaseQueryProperties, @unchecked Sendable {
    
    public struct Sort: Sendable {
        public enum SortDirection: Sendable {
            case ascending, descending
        }
        
        public var column: ColumnReference
        public var direction: SortDirection
    }

    public let filters: [Condition]
    public let joins: [Join]
    public let sorts: [Sort]
    public let limit: QueryValue?
    public let offset: QueryValue?

    public init<Configuration: Select>(configuration: Configuration) {
        let name = String(describing: type(of: configuration))
        
        let queryBuilder = SelectQueryBuilder<Configuration.ReturnType>(name: name)
        configuration.select(query: queryBuilder)
        
        self.filters = queryBuilder.filters
        self.joins = queryBuilder.joins
        self.limit = queryBuilder.limit
        self.offset = queryBuilder.offset
        self.sorts = queryBuilder.sorts
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
