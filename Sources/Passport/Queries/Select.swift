import Foundation

public class SelectQueryBuilder<From: Table, Returning: ProjectionKey>: BaseQuery<From, Returning> {
    
    
    var filters: [Condition] = []
    var joins: [Join] = []
    
    public func filter(_ build: () -> Condition) {
        filters.append(build())
    }
    
    public func join<Foreign: Table>(foreign: Foreign.Type, as alias: String, kind: Join.Kind, _ build: (TableSource<Foreign>) -> Condition) -> TableSource<Foreign> {
        let source = TableSource(
            reference: .init(tableName: foreign.tableName, alias: alias),
            table: foreign
        )
        let condition = build(source)
        joins.append(
            Join(
                kind: kind,
                alias: alias,
                relation: .table(source.reference),
                condition: condition
            )
        )
        
        return source
    }
    
    public func join<Projection: ProjectionKey>(cte: CTESource<Projection>, as alias: String, kind: Join.Kind, _ build: (CTEReference<Projection>) -> Condition) -> CTEReference<Projection> {
        let reference = CTEReference<Projection>(relationName: cte.alias, alias: alias)
        let condition = build(reference)
        joins.append(
            Join(
                kind: kind,
                alias: alias,
                relation: .cte(reference.identifier),
                condition: condition
            )
        )
        
        return reference
    }
    
    public func select(_ value: IntoConditionValue, as alias: Returning) {
        project(value, as: alias)
    }
}

extension SelectQueryBuilder where From.Key == Returning {
    public func selectAll() {
        for key in From.Key.allCases {
            project(source[key], as: key)
        }
    }
}

public protocol Select {
    static var name: String { get }
    
    associatedtype From: Table
    associatedtype ReturnType: ProjectionKey
    
    func select(local: TableSource<From>, query: SelectQueryBuilder<From, ReturnType>)
}

public final class SelectQuery: BaseQueryProperties, @unchecked Sendable {

    public let filters: [Condition]
    public let joins: [Join]
    
    public init<Configuration: Select>(configuration: Configuration) {
        let source = TableSource(reference: .init(tableName: Configuration.From.tableName, alias: Configuration.name), table: Configuration.From.self)
        let queryBuilder = SelectQueryBuilder<Configuration.From, Configuration.ReturnType>(name: Configuration.name, source: source)
        configuration.select(local: source, query: queryBuilder)
        
        self.filters = queryBuilder.filters
        self.joins = queryBuilder.joins
        super.init(query: queryBuilder, target: source.reference)
    }
}
