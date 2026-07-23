import Foundation

public class SelectQueryBuilder<From: Table>: Query<From> {
    
    var fields: [SelectQuery.Field] = []
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
        joins.append(Join(kind: kind, alias: alias, foreignName: foreign.tableName, condition: condition))
        
        return source
    }
    
    public func select(_ column: ColumnReference, as alias: String? = nil) {
        fields.append(
            .init(alias: alias ?? column.columnName, column: column)
        )
    }
}

public final class SelectQuery: BaseQueryProperties, @unchecked Sendable {
    public struct Field: Sendable {
        public let alias: String
        public let column: ColumnReference
    }
    
    public let fields: [Field]
    public let filters: [Condition]
    public let joins: [Join]

    fileprivate init<From: Table>(_ queryBuilder: SelectQueryBuilder<From>) {
        self.fields = queryBuilder.fields
        self.filters = queryBuilder.filters
        self.joins = queryBuilder.joins
        super.init(query: queryBuilder)
    }
}

public typealias SelectBuilder<From: Table> = (TableSource<From>, SelectQueryBuilder<From>) -> Void
public func Select<From: Table>(from: From.Type, as name: String, _ exec: SelectBuilder<From>) -> SelectQuery {
    let from = TableSource(reference: .init(tableName: from.tableName, alias: from.tableName), table: from)
    let query = SelectQueryBuilder<From>(name: name)
    exec(from, query)
    return SelectQuery(query)
}
