import Foundation

public class UpdateQueryBuilder<T: Table>: Query<T> {
    var fields: [UpdateQuery.Field] = []
    var filters: [Condition] = []
    var from: UpdateQuery.From? = nil
    
    public func set(_ column: ColumnReference, value: IntoConditionValue) {
        self.fields.append(.init(column: column, value: value.toConditionValue()))
    }
    
    public func from<Foreign: Table>(foreign: Foreign.Type, as alias: String, kind: Join.Kind) -> TableSource<Foreign> {
        let source = TableSource(
            reference: .init(tableName: foreign.tableName, alias: alias),
            table: foreign
        )
        self.from = .init(alias: alias, foreignName: foreign.tableName)
        return source
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
    public struct From: Sendable {
        public let alias: String
        public let foreignName: String
    }

    
    public let fields: [Field]
    public let filters: [Condition]
    public let from: From?
    
    init<T: Table>(_ queryBuilder: UpdateQueryBuilder<T>) {
        self.fields = queryBuilder.fields
        self.filters = queryBuilder.filters
        self.from = queryBuilder.from
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
