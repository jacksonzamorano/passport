import Foundation

public class UpdateQueryBuilder<ReturnType: ProjectionKey>: BaseQuery<ReturnType> {
    
    var setFields: [UpdateQuery.Field] = []
    var filters: [Condition] = []
    
    public func update<T: Table>(_ table: T.Type, as alias: String) -> LocalTableReference<T> {
        return bind(table, as: alias)
    }

    public func set(_ column: LocalColumnReference, value: any IntoConditionValue) {
        self.setFields.append(.init(column: column.column, value: value.toConditionValue()))
    }
    
    public func filter(_ build: () -> Condition) {
        filters.append(build())
    }
    
    public func returning(_ value: IntoConditionValue, as alias: ReturnType) {
        project(value, as: alias)
    }
    
    public func returnAll<T: Table>(from reference: TableReference<T>) where T.Key == ReturnType {
        for key in ReturnType.allCases {
            returning(reference[key], as: key)
        }
    }
    
    public func returnAll<T: Table>(from reference: LocalTableReference<T>) where T.Key == ReturnType {
        for key in ReturnType.allCases {
            returning(reference[key].column, as: key)
        }
    }
}

public protocol Update: IntoSchemaItem {
    associatedtype ReturnType: ProjectionKey
    
    func update(query: UpdateQueryBuilder<ReturnType>)
}

public extension Update {
    func toSchemaItem() -> SchemaItem {
        .query(.update(.init(configuration: self)))
    }
}

public class UpdateQuery: BaseQueryProperties, @unchecked Sendable {
    public struct Field {
        var column: ColumnReference
        var value: QueryValue
    }
    
    public let setFields: [Field]
    public let filters: [Condition]
    
    init<Configuration: Update>(configuration: Configuration) {
        let name = String(describing: type(of: configuration))

        let queryBuilder = UpdateQueryBuilder<Configuration.ReturnType>(name: name)
        configuration.update(query: queryBuilder)
        
        self.setFields = queryBuilder.setFields
        self.filters = queryBuilder.filters
        super.init(query: queryBuilder)
    }
    
    override func validate() throws(QueryValidationError) {
        try super.validate()
        if setFields.isEmpty {
            throw .noOpUpdate
        }
    }
}
