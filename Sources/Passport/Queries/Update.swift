import Foundation

public class UpdateQueryBuilder<ReturnType: ProjectionKey>: BaseQuery<ReturnType> {
    
    var setFields: [UpdateQuery.Field] = []
    var filters: [Condition] = []
    
    public func update<T: Table>(_ table: T.Type, as alias: String) -> TableSource<T> {
        return bind(table, as: alias)
    }

    public func set(_ column: ColumnReference, value: IntoConditionValue) {
        self.setFields.append(.init(column: column, value: value.toConditionValue()))
    }
    
    public func filter(_ build: () -> Condition) {
        filters.append(build())
    }
    
        public func returning(_ value: IntoConditionValue, as alias: ReturnType) {
        project(value, as: alias)
    }
    
    public func returnAll<T: Table>(from tableSource: TableSource<T>) where T.Key == ReturnType {
        for key in ReturnType.allCases {
            returning(tableSource[key], as: key)
        }
    }
}

public protocol Update: IntoSchemaItem {
    static var name: String { get }
    
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
        let queryBuilder = UpdateQueryBuilder<Configuration.ReturnType>(name: Configuration.name)
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
