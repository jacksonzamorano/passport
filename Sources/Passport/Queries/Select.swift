import Foundation

public class SelectQueryBuilder<From: Table>: Query<From> {
    
    var fields: [SelectQuery.Field] = []
    var filters: [Condition] = []
    
    public func filter(_ build: () -> Condition) {
        filters.append(build())
    }
    
    public func select(_ column: ColumnReference, as alias: String? = nil) {
        fields.append(
            .init(alias: alias ?? column.columnName, column: column)
        )
    }
}

public final class SelectQuery: BaseQueryProperties, @unchecked Sendable {
    public struct Field: Sendable {
        let alias: String
        let column: ColumnReference
    }
    
    public let fields: [Field]
    public let filters: [Condition]

    fileprivate init<From: Table>(_ queryBuilder: SelectQueryBuilder<From>) {
        self.fields = queryBuilder.fields
        self.filters = queryBuilder.filters
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
