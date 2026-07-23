import Foundation

public class InsertQueryBuilder<T: Table>: Query<T> {
    var fields: [InsertQuery.Field] = []
    public func insert(_ column: ColumnReference, value: IntoConditionValue) {
        self.fields.append(.init(column: column, value: value.toConditionValue()))
    }
}

public class InsertQuery: BaseQueryProperties, @unchecked Sendable {
    public struct Field {
        var column: ColumnReference
        var value: ConditionValue
    }
    
    public let fields: [Field]

    
    public init<T: Table>(_ queryBuilder: InsertQueryBuilder<T>) {
        self.fields = queryBuilder.fields
        super.init(query: queryBuilder)
    }
}

public typealias InsertBuilder<Into: Table> = (TableSource<Into>, inout InsertQueryBuilder<Into>) -> Void
public func Insert<Into: Table>(into: Into.Type, as name: String, _ exec: InsertBuilder<Into>) -> InsertQuery {
    let from = TableSource(reference: .init(tableName: into.tableName, alias: into.tableName), table: into)
    var query = InsertQueryBuilder<Into>(name: name)
    exec(from, &query)
    return InsertQuery(query)
}
