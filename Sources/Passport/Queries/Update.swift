import Foundation

public class UpdateQueryBuilder<T: Table>: Query<T> {
    var fields: [UpdateQuery.Field] = []
    var filters: [Condition] = []
    
    public func insert(_ column: ColumnReference, value: IntoConditionValue) {
        self.fields.append(.init(column: column, value: value.toConditionValue()))
    }
    
    public func filter(_ build: () -> Condition) {
        filters.append(build())
    }
}

public class UpdateQuery: BaseQueryProperties, @unchecked Sendable {
    public struct Field {
        var column: ColumnReference
        var value: ConditionValue
    }
    
    public let fields: [Field]

    
    public init<T: Table>(_ queryBuilder: UpdateQueryBuilder<T>) {
        self.fields = queryBuilder.fields
        super.init(query: queryBuilder)
    }
}

public typealias UpdateBuilder<Target: Table> = (TableSource<Target>, inout UpdateQueryBuilder<Target>) -> Void
public func Update<Target: Table>(_ target: Target.Type, as name: String, _ exec: UpdateBuilder<Target>) -> UpdateQuery {
    let from = TableSource(reference: .init(tableName: target.tableName, alias: target.tableName), table: target)
    var query = UpdateQueryBuilder<Target>(name: name)
    exec(from, &query)
    return UpdateQuery(query)
}
