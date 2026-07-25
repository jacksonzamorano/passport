import Foundation

public class SelectQueryBuilder<Returning: ProjectionKey>: BaseQuery<Returning> {
    
    var filters: [Condition] = []
    var joins: [Join] = []
    
    var limit: QueryValue?
    var offset: QueryValue?
    
    public func from<T: Table>(_ table: T.Type, as alias: String) -> RelationSource<T.Key> {
        return bind(table, as: alias)
    }
    public func from<Query: Insert>(_ insert: Query, as alias: String) -> RelationSource<Query.ReturnType> {
        return bind(insert, as: alias)
    }
    public func from<K: ProjectionKey>(_ cte: RelationReference<K>, as alias: String) -> RelationSource<K> {
        return bind(cte, as: alias)
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
    
    public func join<T: Table>(foreign: T.Type, as alias: String, kind: Join.Kind, _ build: (RelationSource<T.Key>) -> Condition) -> RelationSource<T.Key> {
        let table = TableReference(tableName: T.tableName, alias: alias)
        let relation = Relation(name: alias, source: .table(table))
        let reference = RelationReference<T.Key>(source: relation)
        return join(relation: reference, alias: alias, kind: kind, build)
    }
    
    public func join<K: ProjectionKey>(relation: RelationReference<K>, alias: String, kind: Join.Kind, _ build: (RelationSource<K>) -> Condition) -> RelationSource<K> {
        let source = RelationSource<K>(relation: relation.relation, alias: alias)
        let condition = build(source)
        joins.append(
            Join(
                kind: kind,
                alias: alias,
                relation: relation.relation,
                condition: condition
            )
        )
        
        return source
    }
    
    public func select(_ value: IntoConditionValue, as alias: Returning) {
        project(value, as: alias)
    }
    
    public func selectAll<T: Table>(from tableSource: TableSource<T>) where T.Key == Returning {
        for key in Returning.allCases {
            select(tableSource[key], as: key)
        }
    }
}


public protocol Select: IntoSchemaItem {
    static var name: String { get }
    
    associatedtype ReturnType: ProjectionKey
    
    func select(query: SelectQueryBuilder<ReturnType>)
}

public extension Select {
    func toSchemaItem() -> SchemaItem { .query(.select(.init(configuration: self))) }
}

public final class SelectQuery: BaseQueryProperties, @unchecked Sendable {

    public let filters: [Condition]
    public let joins: [Join]
    public var limit: QueryValue?
    public var offset: QueryValue?

    public init<Configuration: Select>(configuration: Configuration) {
        let queryBuilder = SelectQueryBuilder<Configuration.ReturnType>(name: Configuration.name)
        configuration.select(query: queryBuilder)
        
        self.filters = queryBuilder.filters
        self.joins = queryBuilder.joins
        self.limit = queryBuilder.limit
        self.offset = queryBuilder.offset
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
